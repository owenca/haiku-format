#!/bin/bash -e

shopt -s extglob

cd ~/config/non-packaged
rm -fv lib/lib@(clang|LLVM)*.so.*

cd bin
rm -fv haiku-format git-haiku-format
