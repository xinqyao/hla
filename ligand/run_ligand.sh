## Do a simple one-step soft-core decoupling simulation for testing purpose

# Input files (assume present in your working directory):
# - ligand.pdb (generated from run.sh)
# - enmin.sander
# - nvt.sander
# - npt.sander
# - prod.sander
# - ff/* (Antechamber generated force field files for ligand)

module load amber/18
gpu=0
ncore=10
export CUDA_VISIBLE_DEVICES=${gpu}


## 0. Build the topology
## - Generate toplogy files for the ligand
cat >tleap.in << EOF
logFile leap.log
source leaprc.protein.ff14SB
source leaprc.water.tip3p
source leaprc.gaff2
loadamberparams ff/abc.frcmod
loadoff ff/abc.lib

sys = loadpdb ligand.pdb
solvateoct sys TIP3PBOX 15.0 iso
addions sys Na+ 0
addions sys Cl- 0

savepdb sys ligand_box.pdb
saveamberparm sys ligand_box.prmtop ligand_box.inpcrd
quit
EOF

tleap -f tleap.in &> leap_simple.log

## 1. Energy minimization, Heating, and Equilibration
## NOTE: you might need to modify the path to match your local environment
mkdir enmin_equil
cd enmin_equil
cp ../ligand_box.prmtop ../ligand_box.inpcrd ../enmin.sander ../nvt.sander ../npt.sander ./ 
mpirun -v -np ${ncore} pmemd.MPI -O -i enmin.sander -p ligand_box.prmtop -c ligand_box.inpcrd -o enmin.out -r enmin.restrt -ref ligand_box.inpcrd
pmemd.cuda -O -i nvt.sander -p ligand_box.prmtop -c enmin.restrt -o nvt.out -r nvt.restrt -ref enmin.restrt 
pmemd.cuda -O -i npt.sander -p ligand_box.prmtop -c nvt.restrt -o npt.out -r npt.restrt
cd ..

## 2. Production
mkdir production
cd production
cp ../ligand_box.prmtop ../enmin_equil/npt.restrt ../prod.sander ../split_mdout.r ../analysis.sh ./
pmemd.cuda -O -i prod.sander -p ligand_box.prmtop -c npt.restrt -o prod.out -r prod.restrt -x prod.mdcrd 

## 3. MBAR processing
#TODO: 1. Alchemical analysis python package (doi:10.1007/s10822-015-9840-9)
#      2. Estimate Autocorrelation times by pymbar (doi:10.1101/021659)
Rscript split_mdout.r
bash analysis.sh

