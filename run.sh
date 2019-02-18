## Do a simple one-step soft-core decoupling simulation for testing purpose

# Input files (assume present in your working directory):
# - ligand_vina.pdb (from docking)
# - sys_nowat.pdb (from docking)
# - ref.pdb (the B57:01 structure used to map the peptide-presenting domain in other alleles)
# - zinc_4400.mol2 (Mol2 file of abacavir or ABC)
# - 0_process_pdb.r
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
## - Following commands will cut the receptor to keep the peptide-presenting domain only,
## - and prepare for the ligand PDB file.
Rscript 0_process_pdb.r

ln -s sys_nowat_cut.pdb receptor.pdb

cat <<EOF > setup_ligand.leap
<0>=loadmol2 zinc_4400.mol2
ligand=loadpdb ligand_vina1.pdb
set ligand.1 name "ABC"
savepdb ligand ligand.pdb
quit
EOF

tleap -s -f setup_ligand.leap &> setup_ligand.log

## - Generate toplogy files for the complex
cat >tleap.in << EOF
source leaprc.protein.ff14SB
source leaprc.water.tip3p
source leaprc.gaff2
loadamberparams ff/abc.frcmod
loadoff ff/abc.lib

m1 = loadpdb receptor.pdb
bond m1.100.SG m1.163.SG
m2 = loadpdb ligand.pdb
sys = combine { m1 m2 }
solvateoct sys TIP3PBOX 10.0 iso
addions sys Na+ 0
addions sys Cl- 0

savepdb sys complex_box.pdb
saveamberparm sys complex_box.prmtop complex_box.inpcrd
quit
EOF

tleap -f tleap.in &> leap.log

## 1. Energy minimization, Heating, and Equilibration
## NOTE: you might need to modify the path to match your local environment
mkdir enmin_equil
cd enmin_equil
cp ../complex_box.prmtop ../complex_box.inpcrd ../enmin.sander ../nvt.sander ../npt.sander ../RST.all ./ 
mpirun -v -np ${ncore} pmemd.MPI -O -i enmin.sander -p complex_box.prmtop -c complex_box.inpcrd -o enmin.out -r enmin.restrt -ref complex_box.inpcrd
pmemd.cuda -O -i nvt.sander -p complex_box.prmtop -c enmin.restrt -o nvt.out -r nvt.restrt -ref enmin.restrt 
pmemd.cuda -O -i npt.sander -p complex_box.prmtop -c nvt.restrt -o npt.out -r npt.restrt
cd ..

## 2. Production
mkdir production
cd production
cp ../complex_box.prmtop ../enmin_equil/npt.restrt ../prod.sander ../RST.all ../split_mdout.r ../analysis.sh ./
pmemd.cuda -O -i prod.sander -p complex_box.prmtop -c npt.restrt -o prod.out -r prod.restrt -x prod.mdcrd 

## 3. MBAR processing
#TODO: 1. Alchemical analysis python package (doi:10.1007/s10822-015-9840-9)
#      2. Estimate Autocorrelation times by pymbar (doi:10.1101/021659)
Rscript split_mdout.r
bash analysis.sh

