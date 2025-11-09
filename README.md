# Customized clang-format for Haiku

Haiku-format is a
[customized clang-format](https://github.com/owenca/llvm-project/tree/haiku-format-18)
for the [Haiku coding guidelines](https://www.haiku-os.org/development/coding-guidelines).

See the [specific instructions](linux.md) for information about using `haiku-format` on Linux.

## Building and installing haiku-format on Haiku R1/beta5 (64-bit)

1. Check out haiku-format:

     * `git clone https://github.com/owenca/haiku-format`

2. Build haiku-format:

     * `cd haiku-format`

     * `build.sh`

3. Install haiku-format:

     * `install.sh`

## Using haiku-format

> [!WARNING]
> Please remove existing `.haiku-format` config files if you installed v10.0.1 before.

Haiku-format is a superset of clang-format with the default style set to `Haiku`.
You can override any default
[style options](https://releases.llvm.org/18.1.8/tools/clang/docs/ClangFormatStyleOptions.html)
with `.haiku-format` config files. For example:

```
# for legacy code
ColumnLimit: 80

# for non-gcc2
IntegerLiteralSeparator:
  Binary: 4
  Decimal: 3
  DecimalMinDigits: 5
  Hex: 2
```

See the
[clang-format documentation](https://releases.llvm.org/18.1.8/tools/clang/docs/ClangFormat.html)
for more info.

## Using git-haiku-format

You can run `git haiku-format` before `git push`. For more info, run `git haiku-format -h`. Also,
see [here](https://discuss.haiku-os.org/t/how-to-use-haiku-format-17-0-1-with-git/14088) for a demo.
