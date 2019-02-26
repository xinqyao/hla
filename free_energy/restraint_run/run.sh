#!/bin/sh

## IMPORTANT ##
## pmemd.cuda does not support restraint transformation yet ##
##
## we run regular MD but reduce force constants in RST.all gradually 
## Otherwise, WE HAVE TO USE PMEMD.MPI FOR ALL RUNS ##

#module load amber/18
#module load openmpi
#gpu=0
#ncore=10
#export CUDA_VISIBLE_DEVICES=${gpu}
source ../set_env.sh
source ./windows
#w_all=( $windows )
#nw=${#w_all[@]}
#mbar=$(echo $windows | sed 's/ /,/g')

cp ../complex_prepare/RST.all .
#cp ../restraint_prepare/complex_box.prmtop \
#   ../restraint_prepare/complex_box.inpcrd .
#top=$(cd ../restraint_prepare; pwd) #deprecated
top=$(cd ../complex_prepare; pwd)

#windows=$(seq 0.0 0.1 1.0)
#ligand=$(awk 'NR==2{print substr($1, 2, 3)}' ../ff/*.lib)
#ligres=( $(grep "^ATOM.*$ligand" ../complex_prepare/complex_nowat.pdb | cut -c23-26 | tr -d [:blank:] | uniq) )
#lig1=${ligres[0]}
#lig2=${ligres[1]}
natom=$(grep '^ATOM' ../complex_prepare/complex_nowat.pdb | tail -n 1 | cut -c7-11 | tr -d '[:blank:]')
for w in $windows; do
   mkdir $w
   cd $w

   ## 1. Energy minimization, Heating, and Equilibration
   ## NOTE: you might need to modify the path to match your local environment
   mkdir enmin_equil
   cd enmin_equil
   cp ../../../set_env.sh ../../enmin.sander ../../nvt.sander ../../npt.sander .
   sed -e "s/20.0/$(Rscript -e "cat(20.0*(1-$w))")/g" ../../RST.all > RST.all
   ln -s $top/complex_box.prmtop .
   ln -s $top/complex_box.inpcrd .
#  sed -e "s/%L%/$w/" -e "s/%LIG1%/$lig1/" -e "s/%LIG2%/$lig2/" ../../enmin.sander.tmpl > enmin.sander
#   sed -e "s/%L%/$w/" -e "s/%LIG1%/$lig1/" -e "s/%LIG2%/$lig2/" ../../nvt.sander.tmpl > nvt.sander
#   sed -e "s/%L%/$w/" -e "s/%LIG1%/$lig1/" -e "s/%LIG2%/$lig2/" ../../npt.sander.tmpl > npt.sander

   mpirun -v -np ${ncore} pmemd.MPI -O -i enmin.sander -p complex_box.prmtop -c complex_box.inpcrd -o enmin.out -r enmin.restrt -ref complex_box.inpcrd
   pmemd.cuda -O -i nvt.sander -p complex_box.prmtop -c enmin.restrt -o nvt.out -r nvt.restrt -ref enmin.restrt 
   pmemd.cuda -O -i npt.sander -p complex_box.prmtop -c nvt.restrt -o npt.out -r npt.restrt
   cd ..

   ## 2. Production
   mkdir production
   cd production
   cp ../../../set_env.sh ../../process_out.r .
   cp ../../RST.all ./RST_full.all
   sed -e "s/20.0/$(Rscript -e "cat(20.0*(1-$w))")/g" ../../RST.all > RST.all
   ln -s $top/complex_box.prmtop .
   ln -s ../enmin_equil/npt.restrt .
   sed -e "s/%NATOM%/$natom/" ../../prod.sander.tmpl > prod.sander
   cp ../../recap.sander .

   pmemd.cuda -O -i prod.sander -p complex_box.prmtop -c npt.restrt -o prod.out -r prod.restrt -x prod.mdcrd 
  
   ## Recap restraint energy at full fc
   cat > ptraj1.in <<EOF
parm complex_box.prmtop
parmstrip :WAT,Na+,Cl-
parmwrite out complex_nowat.prmtop
EOF

   cat > ptraj2.in <<EOF
parm complex_box.prmtop
trajin npt.restrt
strip :WAT,Na+,Cl-
trajout npt_nowat.restrt ncrestart
go
EOF

   cpptraj < ptraj1.in &> ptraj1.log
   cpptraj < ptraj2.in &> ptraj2.log
   mpirun -v -np ${ncore} sander.MPI -O -i recap.sander -p complex_nowat.prmtop -c npt_nowat.restrt -o recap.out -r recap.restrt -x recap.mdcrd -y prod.mdcrd &> recap.log
   rm -f recap.mdcrd

   ## make a prod.out file for alchemic_analysis.py
   Rscript process_out.r &> process_out.log
 
   cd ..
   cd ..
done
