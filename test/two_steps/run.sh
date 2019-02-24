############################## ALCHEMICAL PATHS ######################################
## complex: 1. disappeared ligand -> coupled ligand (no charge) (vdw_bonded, dG1)
##          2. coupled ligand (no charge) -> fully interacted complex (recharge, dG2)
## 
## ligand:  1. disappeared ligand -> solvated ligand (no charge) (vdw_bonded, dG3)
##          2. solvated ligand (no charge) -> solvated ligand (recharge, dG4)
##
## dG_binding = dG1 + dG2 - dG3 - dG4 + dG_restraint
##
#####################################################################################

module load amber/18
gpu=0
export ncore=10
export CUDA_VISIBLE_DEVICES=${gpu}

top=$( pwd )

## 0a. Processing files from docking directly
## - Following commands will cut the receptor to keep the peptide-presenting domain only,
## - and prepare for the ligand PDB file.
#
# Required files (assume present in 'init'):
# - ligand_vina.pdb (from docking)
# - sys_nowat.pdb (from docking)
# - ref.pdb (the B57:01 structure used to map the peptide-presenting domain in other alleles)
# - zinc_4400.mol2 (Mol2 file of abacavir or ABC)
# - 0_process_pdb.r

cd init
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

cd $top

## 0a. Generate force field files for ligands
## 
## If .frcmod and .lib are absent, run following commands
#      cd ff
#      . ./run_gen_ff.sh
#      cd $top
##

## Following steps are adpated from Amber tutorial (A9)
cd setup

## 1. Generate topology files for the 'vdw_bonded' transformation
. ./1_leap.sh

## 2. Emin_equil with clambda=0.5 (double soft-core) to generate starting conformations for all steps
. ./2_run_md.sh


## 3. Extract coordinates from 2 for recharging steps
. ./3_strip.sh
 
## 4. Generate topology files for production runs
. ./4_leap.sh
 
cd $top

## 5. Setup for production
cd free_energy
. ./setup.sh

## 6. Production runs
. ./submit_complex.sh &> complex.log
. ./submit_ligands.sh &> ligands.log

## 7. Analysis - MBAR processing
#TODO: 1. Alchemical analysis python package (doi:10.1007/s10822-015-9840-9)
#      2. Estimate Autocorrelation times by pymbar (doi:10.1101/021659)
#Rscript split_mdout.r
bash analysis.sh

