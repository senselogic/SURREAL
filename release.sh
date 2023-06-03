#!/bin/sh
set -x
dmd -O -m64 surreal.d
rm *.o
