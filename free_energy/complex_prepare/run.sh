#!/bin/sh 

#module load amber/18
source ../set_env.sh

ligand=$(basename ../ff/*.lib .lib)
cyx=( $(grep "CYX" ../init/receptor.pdb | cut -c23-26 | tr -d [:blank:] | uniq) )
if test ${#cyx[@]} -lt 2; then 
   echo Error: No disulfide bond
   exit 1
fi
cyx1=${cyx[0]}
cyx2=${cyx[1]}

## - Generate toplogy files for the complex
cat >tleap.in << EOF
source leaprc.protein.ff14SB
source leaprc.water.tip3p
source leaprc.gaff2
loadamberparams ../ff/${ligand}.frcmod
loadoff ../ff/${ligand}.lib

m1 = loadpdb ../init/receptor.pdb
bond m1.${cyx1}.SG m1.${cyx2}.SG
m2 = loadpdb ../init/ligand.pdb

sys = combine { m1 m2 }
#saveamberparm sys complex_nowat.prmtop complex_nowat.inpcrd
savepdb sys complex_nowat.pdb

solvateoct sys TIP3PBOX 10.0 iso
addions sys Na+ 0
addions sys Cl- 0

savepdb sys complex_box.pdb
saveamberparm sys complex_box.prmtop complex_box.inpcrd

quit
EOF

tleap -f tleap.in &> leap_simple.log

if test $relax = "TRUE"; then
   sh relax.sh
   mv complex_nowat.pdb bak_complex_nowat.pdb
   cpptraj > ptraj.log <<EOF
parm complex_box.prmtop
trajin relax/production/prod.restrt
strip :WAT,Na+,Cl-
trajout relax/production/prod_nowat.pdb 
go
EOF
   ln -s relax/production/prod_nowat.pdb ./complex_nowat.pdb
fi

Rscript add_restraints.r
