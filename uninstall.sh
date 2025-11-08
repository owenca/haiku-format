#!/bin/bash -e

cd ~/config/non-packaged/bin
rm -fv haiku-format git-haiku-format

shopt -s extglob

if [ "$1" = "-s" ]; then
	cd ../lib
	rm -fv lib@(clang|LLVM)*.so.*
fi
