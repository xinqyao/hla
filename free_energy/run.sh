################## ALCHEMICAL PATHS ##################
## Turn off restraint in complex: dG.restr          ##
## Turn off VDW+ELEC in complex: dG1                ##
## Turn off VDW+ELEC in ligand: dG2                 ##
## Turn on  restraint in ligand (analytical): dG3   ##
##                                                  ##
## dG_binding = dG.restr - dG1 + dG2 + dG3          ##
##                                                  ##
######################################################

if test $# -ne 2 ; then
   echo
   echo "Usage: ./run.sh HLA drug"
   echo "Example:"
   echo "          ./run.sh B_5701 abc"
   echo
   exit 0
fi

hla=$1
shift
drug=$1
shift

if test $drug = abc; then
   mol2=zinc_4400
elif test $drug = alp; then
   mol2=zinc_13298313
elif test $drug = cbz; then
   mol2=zinc_4785
else
   echo Error: Unknown drug
   exit 1
fi

source set_env.sh

echo 
echo "#######################"
echo "$hla, $drug"
echo "#######################"
echo 

if test -d results/$hla/$drug; then
   echo "Error: results exists"
   exit 1
fi
mkdir -p results/$hla/$drug
cd results/$hla/$drug

cp ../../../set_env.sh .

cp -r ../../../init ../../../complex* ../../../ligand* ../../../restraint* .
cp ../../../docking/$hla/$drug/ligand_vina.pdb init/
cp ../../../docking/$hla/$drug/sys_nowat.pdb init/

mkdir ff
cp ../../../ff/${drug}.* ff/
cp ../../../ff/${mol2}.mol2 ff/

cp ../../../analysis/final.r ./
cp ../../../analysis/analysis.sh complex_run/
cp ../../../analysis/analysis.sh ligand_run/
cp ../../../analysis/analysis.sh restraint_run/

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
sh run.sh

cd $top

## 2. Generate topology files for three systems
echo
echo "====== 2. Generating topology files ======"
echo
cd complex_prepare
sh run.sh
cd $top

cd ligand_prepare
sh run.sh
cd $top

cd restraint_prepare
sh run.sh
cd $top

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
echo
cd ligand_run
sh run.sh
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
cd complex_run; sh analysis.sh; cd $top
cd ligand_run; sh analysis.sh; cd $top
cd restraint_run; sh analysis.sh; cd $top

echo
echo "===== Completed ====="
echo "Raw data are under 'results/'"
echo "Final binding free energy is shown below:"

Rscript final.r


