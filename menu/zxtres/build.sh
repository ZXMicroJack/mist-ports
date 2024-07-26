#!/bin/bash
. /opt/vivado/Vivado/2022.2/settings64.sh

build()
{
echo build $1 $2
vivado -mode batch -source build.tcl $1.xpr
cp ./$1.runs/impl_1/zx3top.bit ./core.$2.bit
}

clean()
{
rm -rf $1.cache $1.hw $1.runs .Xil
}


if [ "$1" == "clean" ]; then
	clean menu
	clean menu-a100t
	clean menu-a200t
else

#build menu a35t

if [ "$1" == "all" ]; then
	#sed 's/xc7a35tfgg484-2/xc7a100tfgg484-2/g' < menu.xpr > menu-a100t.xpr
	#build menu-a100t a100t
	sed 's/xc7a35tfgg484-2/xc7a200tfbg484-2/g' < menu.xpr > menu-a200t.xpr
	build menu-a200t a200t
fi

fi
