#!/bin/bash

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
   echo "Usage: ./run_analysis.sh HLA drug"
   echo "Example:"
   echo "          ./run_analysis.sh B_5701 abc"
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
root=$(pwd)

echo 
echo "#######################"
echo "$hla, $drug"
echo "#######################"
echo 


cd results/$hla/$drug

top=$( pwd )

## 4. Analysis - MBAR processing
#TODO: 1. Alchemical analysis python package (doi:10.1007/s10822-015-9840-9)
#      2. Estimate Autocorrelation times by pymbar (doi:10.1101/021659)
#Rscript split_mdout.r
echo
echo "====== Analysis ======"
echo
echo
cd complex_run; sh analysis.sh; cd $top
#cd ligand_run; sh analysis.sh; cd $top
cd restraint_run; sh analysis.sh; cd $top

echo
echo "===== Completed ====="
echo "Raw data are under 'results/'"
echo "Final binding free energy is shown below:"

Rscript final.r

###

mkdir summary
cd summary
mkdir ligand_results ligand_run restraint_run complex_run

cp $top/ligand_results/*.pdf ligand_results/.
cp $top/ligand_run/*.pdf ligand_run/.
cp $top/restraint_run/*.pdf restraint_run/.
cp $top/complex_run/*.pdf complex_run/.

###

cd $root


###
