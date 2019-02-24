#!/bin/sh 

#module load amber/18
source ../set_env.sh

ligand=$(basename ../ff/*.lib .lib)

## 0. Build the topology
## - Generate toplogy files for the ligand
cat >tleap.in << EOF
logFile leap.log
source leaprc.protein.ff14SB
source leaprc.water.tip3p
source leaprc.gaff2
loadamberparams ../ff/${ligand}.frcmod
loadoff ../ff/${ligand}.lib

sys = loadpdb ../init/ligand.pdb
savepdb sys ligand_nowat.pdb

solvateoct sys TIP3PBOX 15.0 iso
addions sys Na+ 0
addions sys Cl- 0

savepdb sys ligand_box.pdb
saveamberparm sys ligand_box.prmtop ligand_box.inpcrd
quit
EOF

tleap -f tleap.in &> leap_simple.log
