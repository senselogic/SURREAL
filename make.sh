#!/bin/sh
set -x
dmd -m64 surreal.d
rm *.o
