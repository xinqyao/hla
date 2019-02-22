#!/bin/sh
#
# Create the prmtop and inpcrd files for the decharging and recharging steps.
# The coordinates are taken from the previous vdw+bonded step.
#

module load amber/18

tleap=$AMBERHOME/bin/tleap
basedir=leap


$tleap -f - > 4_leap.log <<_EOF
# load the AMBER force fields
source leaprc.protein.ff14SB
source leaprc.water.tip3p
source leaprc.gaff2
#loadAmberParams frcmod.ionsjc_tip3p

# load force field parameters for BNZ and PHN
loadamberparams $basedir/abc.frcmod
loadoff $basedir/abc.lib

# coordinates for solvated ligands as created previously by MD
lsolv = loadpdb ligands_solvent.pdb
labc = loadpdb ligands_abc.pdb

# coordinates for complex as created previously by MD
csolv = loadpdb complex_solvent.pdb
cabc = loadpdb complex_abc.pdb
crep = loadpdb complex_receptor.pdb
bond crep.100.SG crep.163.SG

# recharge transformation
recharge = combine {labc labc lsolv}
setbox recharge vdw
savepdb recharge ligands_recharge.pdb
saveamberparm recharge ligands_recharge.parm7 ligands_recharge.rst7

recharge = combine {cabc cabc crep csolv}
setbox recharge vdw
savepdb recharge complex_recharge.pdb
saveamberparm recharge complex_recharge.parm7 complex_recharge.rst7

quit
_EOF

