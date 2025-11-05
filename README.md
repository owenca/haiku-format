# Haiku format

`haiku-format` is a [customized clang-format](https://github.com/owenca/llvm-project/tree/haiku-format-18) for the [Haiku coding guidelines](https://www.haiku-os.org/development/coding-guidelines).

## Building and installing

The build and install process will work on a Haiku `x86_64` system or an `apt`-based linux system such as [Debian](https://www.debian.org/) or [Ubuntu](https://ubuntu.com/).

### Installed files

The `haiku-format` files will be installed at the following location;

|Operating system|Install location|
|---|---|
|Haiku|`${HOME}/config/non-packaged`|
|Linux|`/opt/haiku-format`|

The following files are installed;

|Files|Description|
|---|---|
|`lib/lib*.so.*`|Library resources for the binary|
|`bin/haiku-format`|a launcher script for `haiku-format`|
|`bin/_haiku-format`|the `haiku-format` native binary|
|`bin/git-haiku-format`|a git command to launch `haiku-format`|

### Build and install steps for Haiku

1. `git clone https://github.com/owenca/haiku-format`
2. `cd "haiku-format"`
3. `./setup.sh build`
4. `./setup.sh install`

The `PATH` env-var on Haiku will already include the installation `bin` directory. You can verify that it is working by running;

```
haiku-format -h
```

### Build and install steps for Linux

1. `git clone https://github.com/owenca/haiku-format`
2. `cd "haiku-format"`
3. `./setup.sh build`
4. `sudo ./setup.sh install`

The installation's `bin` directory must be included in the `PATH` env-var. The following additional line at the end of your `${HOME}/.profile` will ensure that this is configured;

```
export PATH="/opt/haiku-format/bin:${PATH}"
```

Restart your session and ensure that `haiku-format` can be executed by running;

```
haiku-format -h
```

### Clean steps for Haiku and Linux

If you would like to build again from scratch or would like to clean the build resources run;

1. `./setup.sh clean`

### Uninstall steps for Haiku

1. `./setup.sh uninstall`

### Uninstall steps for Linux

1. `sudo ./setup.sh uninstall`

## Usage

You can format a source file by running;

```
haiku-format src/apps/haikudepot/model/Model.cpp
```

From a clone of the Haiku source code you can get a diff between a commit and the current state with;

```
git haiku-format f7d2fc176e09b850909d6608ac60e9b9a6f1bcbc --diff
```

Find out more about other options with `git haiku-format -h`.

## Configuration

> [!WARNING]
> Please remove existing `.haiku-format` config files if you installed v10.0.1 before.

Haiku-format is a superset of clang-format with the default style set to `Haiku`. You can override any default [style options](https://releases.llvm.org/18.1.8/tools/clang/docs/ClangFormatStyleOptions.html) with `.haiku-format` config files. For example:

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

See the [clang-format documentation](https://releases.llvm.org/18.1.8/tools/clang/docs/ClangFormat.html) for more information on configuration options.