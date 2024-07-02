#!/bin/bash -e

dir=~/config/non-packaged
bin=$dir/bin
git_haiku_format=$bin/git-haiku-format

cd llvm-project
cp -fv build/bin/clang-format $bin/haiku-format
sed s/clang-format/haiku-format/g clang/tools/clang-format/git-clang-format > $git_haiku_format
chmod -v +x $git_haiku_format

shopt -s extglob

cd build/lib
cp -fv lib@(clang|LLVM)!(*Gen*).so.* $dir/lib 2> /dev/null
