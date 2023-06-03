#!/bin/sh
set -x
dmd -debug -g -gf -gs -m64 surreal.d
rm *.o
