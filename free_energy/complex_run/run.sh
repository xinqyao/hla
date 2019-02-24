#!/bin/sh

#module load amber/18
#gpu=0
#ncore=10
#export CUDA_VISIBLE_DEVICES=${gpu}
source ../set_env.sh
source ./windows
w_all=( $windows )
nw=${#w_all[@]}
mbar=$(echo $windows | sed 's/ /,/g')

#cp ../complex_prepare/complex_box.prmtop \
#   ../complex_prepare/complex_box.inpcrd .
top=$(cd ../complex_prepare; pwd)

#windows=$(seq 0.0 0.05 1.0)
ligand=$(awk 'NR==2{print substr($1, 2, 3)}' ../ff/*.lib)
natom=$(grep '^ATOM' ../complex_prepare/complex_nowat.pdb | tail -n 1 | cut -c7-11 | tr -d '[:blank:]')
for w in $windows; do
   mkdir $w
   cd $w

   ## 1. Energy minimization, Heating, and Equilibration
   ## NOTE: you might need to modify the path to match your local environment
   mkdir enmin_equil
   cd enmin_equil
#   cp ../../complex_box.prmtop ../../complex_box.inpcrd ../../RST.all .
   cp ../../../set_env.sh ../../RST.all .
   ln -s $top/complex_box.prmtop .
   ln -s $top/complex_box.inpcrd .
   sed -e "s/%L%/$w/" -e "s/%LIG%/$ligand/" ../../enmin.sander.tmpl > enmin.sander
   sed -e "s/%L%/$w/" -e "s/%LIG%/$ligand/" ../../nvt.sander.tmpl > nvt.sander
   sed -e "s/%L%/$w/" -e "s/%LIG%/$ligand/" ../../npt.sander.tmpl > npt.sander
   
   mpirun -v -np ${ncore} pmemd.MPI -O -i enmin.sander -p complex_box.prmtop -c complex_box.inpcrd -o enmin.out -r enmin.restrt -ref complex_box.inpcrd
   pmemd.cuda -O -i nvt.sander -p complex_box.prmtop -c enmin.restrt -o nvt.out -r nvt.restrt -ref enmin.restrt 
   pmemd.cuda -O -i npt.sander -p complex_box.prmtop -c nvt.restrt -o npt.out -r npt.restrt
   cd ..

   ## 2. Production
   mkdir production
   cd production
   cp ../../../set_env.sh ../../RST.all .
   ln -s $top/complex_box.prmtop .
   ln -s ../enmin_equil/npt.restrt .
   sed -e "s/%L%/$w/" -e "s/%NATOM%/$natom/" -e "s/%LIG%/$ligand/" \
       -e "s/%W%/$nw/" -e "s/%MBAR%/$mbar/" ../../prod.sander.tmpl > prod.sander

   pmemd.cuda -O -i prod.sander -p complex_box.prmtop -c npt.restrt -o prod.out -r prod.restrt -x prod.mdcrd 
   
   cd ..
   cd ..
done
