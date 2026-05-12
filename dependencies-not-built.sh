#!/bin/bash
#
# Arg: name of a file listing expected dependencies,
# default: all-dependencies.txt

grep -Fvx -f <(make list-built) ${1:-all-dependencies.txt}
