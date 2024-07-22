#!/bin/bash
find ../Menu_MIST/ -name \*.vhd -exec echo "<File Path=\"\$PPRDIR/{}\">" \;
find ../Menu_MIST/ -name \*.v -exec echo "<File Path=\"\$PPRDIR/{}\">" \;
find ../Menu_MIST/ -name \*.sv -exec echo "<File Path=\"\$PPRDIR/{}\">" \;

