#!/bin/bash
cp -v ./zxspectrum.runs/impl_1_a200t/zx3top.bit ZXSpectrum-MiST-zx3-a200t.bit
cp -v ./zxspectrum.runs/impl_1/zx3top.bit ZXSpectrum-MiST-zx3-a35t.bit
cp -v ./zxspectrum.runs/impl_1_a100t/zx3top.bit ZXSpectrum-MiST-zx3-a100t.bit
zip ZXSpectrum-MiST-zx3-v1.2.zip *.bit readme.txt spectrum.rom

