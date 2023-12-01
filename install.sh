#!/bin/bash -e

config=~/config/settings/.haiku-format
test -f $config && echo "Warning: the obsolete config file $config can be deleted!"

bin=~/config/non-packaged/bin
git_haiku_format=$bin/git-haiku-format

cd llvm-project
cp -fv build/bin/clang-format $bin/haiku-format
sed s/clang-format/haiku-format/g clang/tools/clang-format/git-clang-format > $git_haiku_format
chmod -v +x $git_haiku_format
