#!/bin/sh
#
# Create prmtop and inpcrd for both the ligands in solution and the complex
# in solution.  This is for the vdw+bonded transformation (name assuming that
# all charges of the ligands are turned on/off at the same time).  MD is
# expected to run on these next and the thusly created coordinates will be
# used to create the inputs for the decharging and recharging step (step #4)
# to ensure the same number of molecules are used and also to start from the
# same coordinates.
#

module load amber/18

tleap=$AMBERHOME/bin/tleap
basedir=leap


$tleap -f -  > leap_simple.log <<_EOF
# load the AMBER force fields
source leaprc.protein.ff14SB
source leaprc.water.tip3p
source leaprc.gaff2
#loadAmberParams frcmod.ionsjc_tip3p

# load force field parameters for ligand
loadamberparams $basedir/abc.frcmod
loadoff $basedir/abc.lib

# load the coordinates and create the complex
ligands = loadpdb $basedir/ligand.pdb
complex = loadpdb $basedir/receptor.pdb
bond complex.100.SG complex.163.SG
complex = combine {ligands complex}

# create ligands in solution for vdw+bonded transformation
solvatebox ligands TIP3PBOX 12.0 0.75
addions ligands Na+ 0
addions ligands Cl- 0
savepdb ligands ligands_vdw_bonded.pdb
saveamberparm ligands ligands_vdw_bonded.parm7 ligands_vdw_bonded.rst7

# create complex in solution for vdw+bonded transformation
solvatebox complex TIP3PBOX 12.0 0.75
addions complex Na+ 0
addions complex Cl- 0
savepdb complex complex_vdw_bonded.pdb
saveamberparm complex complex_vdw_bonded.parm7 complex_vdw_bonded.rst7

quit
_EOF

