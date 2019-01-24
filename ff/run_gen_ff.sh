module load amber/18

antechamber -i ../ligand.pdb -fi pdb -o Mol_GAFF.mol2 -fo mol2
parmchk -i Mol_GAFF.mol2 -f mol2 -o abc.frcmod -a Y

cat >ff.leap << EOF
logFile leap.log
source leaprc.protein.ff14SB
source leaprc.gaff2
loadamberparams abc.frcmod
ABC = loadmol2 Mol_GAFF.mol2
saveoff ABC abc.lib
quit
EOF

tleap -s -f ff.leap &> ff.log

