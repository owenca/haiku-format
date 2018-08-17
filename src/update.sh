#!/bin/sh -e

LLVM="../llvm"
CLANG="$LLVM/tools/clang"

cp -uv Path.inc $LLVM/lib/Support/Unix/
cp -uv Format.h $CLANG/include/clang/Format/
cp -uv ClangFormat.cpp $CLANG//tools/clang-format/

cp -uv ContinuationIndenter.cpp Format.cpp FormatToken.h TokenAnnotator.cpp \
		UnwrappedLineParser.cpp UnwrappedLineParser.h $CLANG/lib/Format/
