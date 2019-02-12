module load amber/18

antechamber -i ../ligand.pdb -fi pdb -o Mol_GAFF.mol2 -fo mol2
PARMCHK=parmchk
# command -v $PARMCHK >/dev/null 2>&1 || { exit 1; }
if ! [ -x $(command -v $PARMCHK) ]
then
    PARMCHK=parmchk2
    if ! [ -x $(command -v $PARMCHK) ]
    then
        echo -e "\n\tparmchk or parmchk2 not found. Quitting ..."
        exit 1
    fi
fi

$PARMCHK -i Mol_GAFF.mol2 -f mol2 -o abc.frcmod -a Y

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

