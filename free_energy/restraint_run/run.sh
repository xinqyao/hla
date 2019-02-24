#!/bin/sh

## IMPORTANT ##
## pmemd.cuda does not support restraint transformation yet ##
## 
## WE HAVE TO USE PMEMD.MPI FOR ALL RUNS ##

#module load amber/18
#module load openmpi
#gpu=0
#ncore=10
#export CUDA_VISIBLE_DEVICES=${gpu}
source ../set_env.sh
source ./windows
w_all=( $windows )
nw=${#w_all[@]}
mbar=$(echo $windows | sed 's/ /,/g')

#cp ../restraint_prepare/complex_box.prmtop \
#   ../restraint_prepare/complex_box.inpcrd .
top=$(cd ../restraint_prepare; pwd)

#windows=$(seq 0.0 0.1 1.0)
ligand=$(awk 'NR==2{print substr($1, 2, 3)}' ../ff/*.lib)
ligres=( $(grep "^ATOM.*$ligand" ../restraint_prepare/complex_nowat.pdb | cut -c23-26 | tr -d [:blank:] | uniq) )
lig1=${ligres[0]}
lig2=${ligres[1]}
natom=$(grep '^ATOM' ../restraint_prepare/complex_nowat.pdb | tail -n 1 | cut -c7-11 | tr -d '[:blank:]')
for w in $windows; do
   mkdir $w
   cd $w

   ## 1. Energy minimization, Heating, and Equilibration
   ## NOTE: you might need to modify the path to match your local environment
   mkdir enmin_equil
   cd enmin_equil
   cp ../../../set_env.sh ../../RST.all .
   ln -s $top/complex_box.prmtop .
   ln -s $top/complex_box.inpcrd .
   sed -e "s/%L%/$w/" -e "s/%LIG1%/$lig1/" -e "s/%LIG2%/$lig2/" ../../enmin.sander.tmpl > enmin.sander
   sed -e "s/%L%/$w/" -e "s/%LIG1%/$lig1/" -e "s/%LIG2%/$lig2/" ../../nvt.sander.tmpl > nvt.sander
   sed -e "s/%L%/$w/" -e "s/%LIG1%/$lig1/" -e "s/%LIG2%/$lig2/" ../../npt.sander.tmpl > npt.sander

   mpirun -v -np ${ncore} pmemd.MPI -O -i enmin.sander -p complex_box.prmtop -c complex_box.inpcrd -o enmin.out -r enmin.restrt -ref complex_box.inpcrd
   mpirun -v -np ${ncore} pmemd.MPI -O -i nvt.sander -p complex_box.prmtop -c enmin.restrt -o nvt.out -r nvt.restrt -ref enmin.restrt 
   mpirun -v -np ${ncore} pmemd.MPI -O -i npt.sander -p complex_box.prmtop -c nvt.restrt -o npt.out -r npt.restrt
   cd ..

   ## 2. Production
   mkdir production
   cd production
   cp ../../../set_env.sh ../../RST.all .
   ln -s $top/complex_box.prmtop .
   ln -s ../enmin_equil/npt.restrt .
   sed -e "s/%L%/$w/" -e "s/%NATOM%/$natom/" -e "s/%LIG1%/$lig1/" -e "s/%LIG2%/$lig2/" \
       -e "s/%W%/$nw/" -e "s/%MBAR%/$mbar/" ../../prod.sander.tmpl > prod.sander

   mpirun -v -np ${ncore} pmemd.MPI -O -i prod.sander -p complex_box.prmtop -c npt.restrt -o prod.out -r prod.restrt -x prod.mdcrd 
   
   cd ..
   cd ..
done
