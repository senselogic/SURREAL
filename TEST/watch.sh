#!/bin/sh
set -x
../surreal --extension .upp .h .cpp --create --watch UPP/ H/ CPP/
