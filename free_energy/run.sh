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
root=$(pwd)

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

cp -r ../../../init ../../../complex_run ../../../ligand_prepare ../../../ligand_run \
      ../../../restraint* .

mkdir ligand_results
cp ../../../ligand_results/$drug/* ligand_results/

cp ../../../docking/$hla/$drug/ligand_vina.pdb init/
cp ../../../docking/$hla/$drug/sys_nowat.pdb init/

mkdir complex_prepare
cp ../../../complex_prepare/*.sh complex_prepare/
cp ../../../complex_prepare/add_restraints_${drug}.r complex_prepare/add_restraints.r
cp -R ../../../complex_prepare/relax complex_prepare/

mkdir ff
cp ../../../ff/${drug}.* ff/
cp ../../../ff/${mol2}.mol2 ff/

cp ../../../analysis/final.r ./
cp ../../../analysis/analysis.sh complex_run/
cp ../../../analysis/analysis.sh ligand_run/
cp ../../../analysis/analysis.sh restraint_run/

cp ../../../rerun.sh .

sh rerun.sh

cd $root
