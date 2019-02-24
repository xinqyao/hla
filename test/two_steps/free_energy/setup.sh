#!/bin/sh
#
# Setup for the free energy simulations: creates and links to the input file as
# necessary.  Two alternative for the de- and recharging step can be used.
#


. ./windows

# partial removal/addition of charges: softcore atoms only
#decharge_crg=":2"
vdw_crg=":ABC"
recharge_crg=":1"

# complete removal/addition of charges
#decharge_crg=":2"
#vdw_crg=":1,2"
#recharge_crg=":1"

#decharge=" ifsc = 0, crgmask = '$decharge_crg',"
vdw_bonded=" timask1='', timask2=':ABC', ifsc=1, scmask1='', scmask2=':ABC', crgmask='$vdw_crg'"
recharge=" timask1=':1', timask2=':2', ifsc = 0, crgmask = '$recharge_crg',"

basedir=../setup
top=$(pwd)
setup_dir=$(cd "$basedir"; pwd)

for system in ligands complex; do
  if [ \! -d $system ]; then
    mkdir $system
  fi

  cd $system

  for step in vdw_bonded recharge; do
    
    if [ \! -d $step ]; then
      mkdir $step
    fi

    cd $step

    myw=( $(eval "echo \${windows_$step} | sed 's/ /, /g'") )
    nw=${#myw[@]}
    myw=$(eval "echo ${myw[@]}") 
    for w in $(eval "echo \${windows_$step}"); do
      if [ \! -d $w ]; then
        mkdir $w
      fi

      FE=$(eval "echo \${$step}")
      sed -e "s/%L%/$w/" -e "s/%FE%/$FE/" $top/heat.tmpl.$system > $w/heat.in
      sed -e "s/%L%/$w/" -e "s/%FE%/$FE/" -e "s/%NMBAR%/$nw/" -e "s/%MBAR%/$myw/" $top/prod.tmpl.$system > $w/ti.in
      if test $system = "complex"; then 
         cp $top/RST.all.$step $w/RST.all
      fi

      (
        cd $w
        ln -sf $setup_dir/${system}_$step.parm7 ti.parm7
        ln -sf $setup_dir/${system}_$step.rst7  ti.rst7
      )
    done

    cd ..
  done

  cd $top
done

