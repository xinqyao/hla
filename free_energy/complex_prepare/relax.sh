#!/bin/bash

top=$(pwd)
source ../set_env.sh

natom=$(grep '^ATOM' complex_nowat.pdb | tail -n 1 | cut -c7-11 | tr -d '[:blank:]')
cd relax
   ## 1. Energy minimization, Heating, and Equilibration
   ## NOTE: you might need to modify the path to match your local environment
   mkdir enmin_equil
   cd enmin_equil
#   cp ../../complex_box.prmtop ../../complex_box.inpcrd ../../RST.all .
   cp $top/../set_env.sh ../*.sander .
   ln -s $top/complex_box.prmtop .
   ln -s $top/complex_box.inpcrd .
   
   mpirun -v -np ${ncore} pmemd.MPI -O -i enmin.sander -p complex_box.prmtop -c complex_box.inpcrd -o enmin.out -r enmin.restrt -ref complex_box.inpcrd
   pmemd.cuda -O -i nvt.sander -p complex_box.prmtop -c enmin.restrt -o nvt.out -r nvt.restrt -ref enmin.restrt 
   pmemd.cuda -O -i npt.sander -p complex_box.prmtop -c nvt.restrt -o npt.out -r npt.restrt
   cd ..

   ## 2. Production
   mkdir production
   cd production
   cp $top/../set_env.sh .
   ln -s $top/complex_box.prmtop .
   ln -s ../enmin_equil/npt.restrt .
   sed -e "s/%NATOM%/$natom/" ../prod.sander.tmpl > prod.sander

   pmemd.cuda -O -i prod.sander -p complex_box.prmtop -c npt.restrt -o prod.out -r prod.restrt -x prod.mdcrd

cd $top
