source set_env.sh
top=$( pwd )

## 1. Processing files from docking directly
## - Following commands will cut the receptor to keep the peptide-presenting domain only,
## - and prepare for the ligand PDB file.
#
# Required files (assume present in 'init'):
# - ref.pdb (the B57:01 structure used to map the peptide-presenting domain in other alleles)
# - 0_process_pdb.r
# - ligand_vina.pdb
# - sys_nowat.pdb
#
echo
echo "====== 1. Processing files from docking ======"
echo
cd init
#sh run.sh

cd $top

## 2. Generate topology files for three systems
echo
echo "====== 2. Generating topology files ======"
echo
cd complex_prepare
#sh run.sh
cd $top

cd ligand_prepare
#sh run.sh
cd $top

## deprecated
#cd restraint_prepare
#sh run.sh
#cd $top

## 3. Run calculations
echo
echo "====== 3. Run calculations ======"
echo
echo
echo "=========== 3.1 Complex (VDW+ELEC) ====="
echo
cd complex_run
sh run.sh
cd $top

echo
echo "=========== 3.2 Ligand (VDW+ELEC) ====="
echo "... skipped ..."
cd ligand_run
#sh run.sh
#cp ../ligand_results/* ./
cd $top

echo
echo "=========== 3.3 Complex (Restraint) ====="
echo
cd restraint_run
sh run.sh
cd $top

## 4. Analysis - MBAR processing
#TODO: 1. Alchemical analysis python package (doi:10.1007/s10822-015-9840-9)
#      2. Estimate Autocorrelation times by pymbar (doi:10.1101/021659)
#Rscript split_mdout.r
echo
echo "====== 4. Analysis ======"
echo
echo
cd complex_run; sh analysis.sh &> analysis.log; cd $top
#cd ligand_run; sh analysis.sh; cd $top
cd restraint_run; sh analysis.sh &> analysis.log; cd $top

echo
echo "===== Completed ====="
echo "Raw data are under 'results/'"
echo "Final binding free energy is shown below:"

Rscript final.r
Rscript final.r > final.out

#cd $root
