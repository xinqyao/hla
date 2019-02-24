#!/bin/sh

#module load amber/18
source ../set_env.sh

## 0. Build the topology
## - Following commands will cut the receptor to keep the peptide-presenting domain only,
## - and prepare for the ligand PDB file.
Rscript 0_process_pdb.r &> 0.log

ln -s sys_nowat_cut.pdb receptor.pdb

mol2=$(ls ../ff/*.mol2)
ligand=$(awk 'NR==2{print substr($1, 2, 3)}' ../ff/*.lib)

cat <<EOF > setup_ligand.leap
<0>=loadmol2 $mol2
ligand=loadpdb ligand_vina1.pdb
set ligand.1 name "$ligand"
savepdb ligand ligand.pdb
quit
EOF

tleap -s -f setup_ligand.leap &> setup_ligand.log
