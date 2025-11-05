#!/bin/bash -e

# This is a script to perform build and install processes for the `haiku-format` tool. Run the
# script with no arguments to get usage. See the accompanying `README.md` file for instructions
# on general use.

set -e
set -o pipefail

script_bin=$0
build_dir="llvm-project/build"
llvm_version=18.1.8
llvm_project=llvm-project
llvm_base_url="https://github.com/llvm/${llvm_project}/releases/download/llvmorg-${llvm_version}"

function hf_usage()
{
  local os_type=$1

  cat <<EOF
build.sh

This script is designed to build the `haiku-format` tool and install it. It will
work on the Haiku operating system as well as GNU Linux.

EOF

  echo "${script_bin} build"
  echo "${script_bin} clean"

  case "${os_type}" in
    haiku)
      echo "${script_bin} install"
      echo "${script_bin} uninstall"
      ;;
    linux*)
      echo "sudo ${script_bin} install"
      echo "sudo ${script_bin} uninstall"
      ;;
    *)
  		echo "error; unsupported operating system" 1>&2
  		;;
  esac

  exit 1
}

function hf_confirm_yes_no()
{
	while true; do
		read -p "$* [y/n]: " yn
		case $yn in
			[Yy])
			  return 0
			  ;;
			[Nn])
			  echo "aborted" 1>&2
			  return 1
			  ;;
		esac
	done
}

function hf_derive_os_type()
{
  case "${OSTYPE}" in
  	haiku)
  		echo "haiku"
  		;;
  	linux-gnu)
  		if command -v apt &> /dev/null; then
  			echo "linux-gnu-apt"
  		else
  			echo "error; unsupported linux-gnu operating system" 1>&2
  			exit 1
  		fi
  		;;
  	*)
  		echo "error; unsupported operating system [${OSTYPE}]" 1>&2
  		exit 1
  		;;
  esac
}

function hf_derive_install_root()
{
  local os_type=$1

  case "${os_type}" in
    haiku)
      echo "${HOME}/config/non-packaged"
      ;;
    linux*)
      echo "/opt/haiku-format"
      ;;
    *)
  		echo "error; unsupported operating system" 1>&2
  		exit 1
  		;;
  esac
}

# This function will install the package identified by the package name using the
# Haiku package system.

function hf_install_package_haiku()
{
	depend="${2:-$1}"
	type -f $1 &> /dev/null || pkgman install -y "${depend}"
}

# installs the packages required for a Haiku system.

function hf_install_dependencies_haiku()
{
	local depends="cmake ninja"

	for d in $depends; do
		hf_install_package_haiku "${d}"
	done

	for d in $depends; do
		type -f "${d}" &> /dev/null || { echo "Please rerun this script after restarting Haiku."; exit 1; }
	done
}

# Detects absent Debian packages that are required for build and install. If there are
# any absent then it will error to the user with the command they are required to run
# to install the missing packages.

function hf_install_dependencies_linux_gnu_apt()
{
	local depends="lld clang cmake ninja-build"
	local missing_depends=()

	for d in $depends; do
	  if ! dpkg -s "${d}" &> /dev/null; then
	    missing_depends+=("${d}")
	  fi
	done

  if [ "${#missing_depends[@]}" -gt 0 ]; then
    echo "ensure that the necessary dependencies are installed before running this script;"
    echo "sudo apt install ${missing_depends[*]}"
    exit 1
  fi
}

# A number of source files have to be downloaded for the build process to work. This
# function will pull those down and then un-pack them into the directory where the
# build will be undertaken.

function hf_download_sources()
{
  local assets="clang cmake llvm third-party"
  local tar_suffix="${llvm_version}.src.tar.xz"
  local tarball

  for a in $assets; do
    tarball="${a}-${tar_suffix}"
    if [ -e "${tarball}" ]; then
      echo "file [${tarball}] exists - can skip download"
    else
      echo "will download [${tarball}]"
      wget -N "${llvm_base_url}/${tarball}"
    fi
  done

  mkdir -v "${llvm_project}"

  for a in $assets; do
    tarball="${a}-${tar_suffix}"
    mkdir -v "${llvm_project}/${a}"
    echo -n "will extract ${a}"
    tar -xf "${tarball}" -C "${llvm_project}/${a}" --strip-components=1 --checkpoint=.1000
    echo
  done
}

# This function will download and unpack the sources and then perform the build. It will
# not proceed if there is already a build product present in the build location.

function hf_build()
{
  if [ -e "${llvm_project}" ]; then
    echo "Please rerun this script after removing ${llvm_project}. You can achieve this by running;"
    echo "${script_bin} clean"
    exit 1
  fi

  case "$(hf_derive_os_type)" in
  	haiku)
  		hf_install_dependencies_haiku
  		;;
  	linux-gnu-apt)
  		hf_install_dependencies_linux_gnu_apt
  		;;
  	*)
  		echo "unsupported operating system" 1>&2
  		exit 1
  		;;
  esac

  hf_download_sources

  local cmake_options="-DBUILD_SHARED_LIBS=ON -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DLLVM_USE_LINKER=lld"

  pushd "${llvm_project}"

  patch -N -p1 -r - < "../v${llvm_version}.diff"
  cmake -Wno-dev -S llvm -B "build" -G Ninja "${cmake_options}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_ENABLE_PROJECTS=clang \
    -DLLVM_TARGETS_TO_BUILD=X86
  ninja -C "build" clang-format
  strip -sv "build/bin/clang-format"

  popd

  echo "did perform build"
}

# Removes the downloaded sources and build product from this directory (not the install).

function hf_clean()
{
  if [ -d "llvm-project" ]; then
    echo "deleting [llvm-project]..."
    rm -rf "llvm-project"
    echo "did delete [llvm-project]"
  fi

  for l in ./*.src.tar.xz; do
    rm "${l}"
    echo "deleted [${l}]"
  done

  echo "did perform clean"
}

# Copies the build product and a launch script into place. It will also create a
# little launch script which sets the library path.

function hf_install()
{
  if [ ! -f "${build_dir}/bin/clang-format" ]; then
    echo "Build product to install not found. You can run a build with;"
    echo "${script_bin} build"
    exit 1
  fi

  local os_type
  local install_root
  local library_env_var_name

  os_type="$(hf_derive_os_type)"
  install_root="$(hf_derive_install_root "${os_type}")"

  if [ -f "${install_root}/bin/haiku-format" ]; then
    echo "the program is already installed at [${install_root}]"
    exit 1
  fi

  if [[ "${os_type}" =~ ^linux.+$ ]] && [[ $EUID -ne 0 ]]; then
    echo "run install as the root user by using 'sudo'"
    exit 1
  fi

  case "${os_type}" in
  	haiku)
  	  library_env_var_name="LIBRARY_PATH"
  		;;
  	linux-gnu-apt)
  		library_env_var_name="LD_LIBRARY_PATH"
  		;;
  	*)
  		echo "unsupported operating system" 1>&2
  		exit 1
  		;;
  esac

  mkdir -p "${install_root}/bin"
  mkdir -p "${install_root}/lib"

  cp -fv ${build_dir}/bin/clang-format "${install_root}/bin/_haiku-format"
  sed s/clang-format/haiku-format/g llvm-project/clang/tools/clang-format/git-clang-format \
    > "${install_root}/bin/git-haiku-format"

  cat <<EOF > "${install_root}/bin/haiku-format"
#!/bin/bash
${library_env_var_name}="${install_root}/lib:\${LIBRARY_PATH}"
"${install_root}/bin/_haiku-format" \$@
EOF

  chmod -v ogu+x "${install_root}/bin/haiku-format"
  chmod -v ogu+x "${install_root}/bin/_haiku-format"
  chmod -v ogu+x "${install_root}/bin/git-haiku-format"

  for f in ${build_dir}/lib/lib*.so.*; do
    if [[ "$f" =~ ^.+/lib(clang|LLVM).+ ]] && ! [[ "$f" =~ ^.+/lib.+Gen.+$ ]]; then
      cp -v "${f}" "${install_root}/lib"
    fi
  done
}

hf_uninstall()
{
  local os_type
  local install_root

  os_type="$(hf_derive_os_type)"
  install_root="$(hf_derive_install_root "${os_type}")"

  if [[ "${os_type}" =~ ^linux.+$ ]] && [[ $EUID -ne 0 ]]; then
    echo "run uninstall as the root user by using 'sudo'"
    exit 1
  fi

  if [ ! -d "${install_root}" ]; then
    echo "The program is not installed at [${install_root}]"
    exit 1
  fi

  if ! hf_confirm_yes_no "remove the haiku-format program from [${install_root}]"; then
    exit 1
  fi

  # A different approach for removal for Haiku compared to linux. On linux we have a
  # specific directory for the `haiku-format` but in Haiku the resources are
  # installed into a shared directory.

  case "${os_type}" in
  	haiku)
  		rm -fv "${install_root}/bin/haiku-format"
  		rm -fv "${install_root}/bin/_haiku-format"
  		rm -fv "${install_root}/bin/git-haiku-format"

      for f in ${install_root}/lib/lib*.so.*; do
        if [[ "$f" =~ ^.+/lib(clang|LLVM).+ ]]; then
          rm -fv "${f}"
        fi
      done
  		;;
  	linux-gnu-apt)
  		rm -rf "${install_root}"
  		;;
  	*)
  		echo "unsupported operating system" 1>&2
  		exit 1
  		;;
  esac

  echo "did remove the 'haiku-format' program"
}

hf_main()
{
  if [ $# != 1 ]; then
    hf_usage "$(hf_derive_os_type)"
  fi

  local command=$1
  shift

  case "${command}" in
    build)
      hf_build
      ;;
    install)
      hf_install
      ;;
    uninstall)
      hf_uninstall
      ;;
    clean)
      hf_clean
      ;;
    *)
      echo "unknown command [$1]" 1>&2
      return 1
  esac
}

hf_main "$@"