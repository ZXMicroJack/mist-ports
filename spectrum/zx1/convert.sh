#!/bin/bash
top=zxspectrum
#top=MENU
#dir=Menu_MIST
dir=spectrum-128k

files=`ls ../${dir}/*.v \
  ../${dir}/*.sv \
  ../${dir}/mist-modules/*.v \
  ../${dir}/mist-modules/*.sv \
  ../${dir}/sys/*.v \
  ../${dir}/sys/*.sv \
  ../${dir}/T80/*.v \
  ../${dir}/T80/*.sv`

echo ${files}

#sv2v -w . --top=${top} ${files}
#cp ../${dir}/mist-modules/*.vhd ../${dir}/sys/*.vhd ../${dir}/T80/*.vhd .
