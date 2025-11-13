#!/bin/bash -e

cd llvm-project/build
ninja FormatTests

if [ "$1" = "-s" ]; then
	export LIBRARY_PATH=$LIBRARY_PATH:$(pwd)/lib
fi

log=ft.err
tools/clang/unittests/Format/FormatTests 2> $log
cat $log

ninja clang-format-check-format
