#!/bin/sh
#
# Use cpptraj to extract the individual ligands and the rest of the system
# (complex: protein+water, ligands:water only).  This is done to get the
# coordinates and keep the same number of molecules for the setup of the
# subsequent de- and recharging steps.
#

module load amber/18

cpptraj=$AMBERHOME/bin/cpptraj

for s in ligands complex; do
  if [ -f ${s}_prepare/press.rst7 ]; then
    cp ${s}_vdw_bonded.rst7 ${s}_vdw_bonded.rst7.leap
    cp ${s}_prepare/press.rst7 ${s}_vdw_bonded.rst7
  fi

  $cpptraj -p ${s}_vdw_bonded.parm7 > 3_strip.log <<_EOF
trajin ${s}_prepare/press.rst7

# extract solvent
strip "!:WAT,Na+,Cl-"
outtraj ${s}_solvent.pdb onlyframes 1

# extract ligand
unstrip
strip "!:ABC"
outtraj ${s}_abc.pdb onlyframes 1

# extract receptor
unstrip
strip ":ABC,WAT,Na+,Cl-"
outtraj ${s}_receptor.pdb onlyframes 1
_EOF
done

## reorder resid in complex_receptor.pdb
Rscript -e "library(bio3d)"\
        -e "pdb <- read.pdb('complex_receptor.pdb')"\
        -e "pdb <- clean.pdb(pdb, force.renumber=TRUE, fix.chain=TRUE)"\
        -e "write.pdb(pdb, chain='', file='complex_receptor.pdb')"

rm -f ligands_receptor.pdb
