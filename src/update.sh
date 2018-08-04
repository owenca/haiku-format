#!/bin/sh -e

LLVM="../llvm"
CLANG="$LLVM/tools/clang"

cp -uv Path.inc $LLVM/lib/Support/Unix/
cp -uv Format.h $CLANG/include/clang/Format/

for file in *.cpp; do
	cp -uv $file $CLANG/lib/Format/
done
