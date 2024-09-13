#!/bin/bash
size=`stat zxspectrum.bit | grep Size | awk '{ print $2 }'`
echo "${size}" > /dev/ttyACM0
cat zxspectrum.bit > /dev/ttyACM0
dd if=/dev/zero of=/dev/ttyACM0 bs=512 count=1


