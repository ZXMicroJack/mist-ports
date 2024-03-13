#!/bin/bash
#file=./ql.runs/impl_1/zx3top.bit
file=./zxspectrum.runs/impl_1/zx3top.bit
if [ "$1" != "" ]; then file=$1; fi
cat << EOF | /opt/urjtag_artix/bin/jtag
cable usbblaster
detect
pld load ${file}
EOF

