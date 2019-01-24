## Do a simple one-step soft-core decompling simulation for testing purpose

# Input files:
# - ligand_vina.pdb (from docking)
# - sys_nowat.pdb (from docking)
# - ref.pdb
# - zinc_4400.mol2
# - 0_process_pdb.r
# - min.sander
# - heat.sander
# - md.sander
# - ff/* (Antechamber generated force field files for ligand)

module load amber/18

## 0. Build the topology
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

## 1. Energy minimization

