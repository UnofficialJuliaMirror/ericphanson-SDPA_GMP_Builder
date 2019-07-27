# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "SDPABuilder"
version = v"7.1.3"

# Collection of sources required to build SDPABuilder
sources = [
    "https://sourceforge.net/projects/sdpa/files/sdpa-gmp/sdpa-gmp-7.1.3.src.20150320.tar.gz" =>
    "65591cfba18afe710508023cd0c4a9d36ca8c56a7dd312d1cf4fc962c7b90df4",
    "https://gmplib.org/download/gmp/gmp-6.1.2.tar.bz2" =>
    "5275bb04f4863a13516b2f39392ac5e272f5e1bb8057b18aec1c9b79d73d8fb2",
    "./bundled"
]

# Bash recipe for building across all platforms
script = raw"""

# Build GMP

cd $WORKSPACE/srcdir/gmp-*
# Patch `configure` to include `$LDFLAGS` in its tests.  This is necessary on FreeBSD.
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/configure.patch
# Include Julia-carried patches
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/gmp_alloc_overflow_func.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/gmp-exception.patch
flags=(--enable-cxx --disable-shared --enable-static)
# On x86_64 architectures, build fat binary
if [[ ${proc_family} == intel ]]; then
    flags+=(--enable-fat)
fi
./configure --prefix=$prefix --host=$target ${flags[@]}
make -j6
make install


# Build SDPA-GMP

cd $WORKSPACE/srcdir/sdpa-gmp-7.1.3/
update_configure_scripts

if [ $target = "x86_64-apple-darwin14" ]; then
  # seems static linking requires apple's ar
  export AR=/opt/x86_64-apple-darwin14/bin/x86_64-apple-darwin14-ar
fi
# patch -p1 < $WORKSPACE/srcdir/patches/shared_gmp.diff
#patch -p1 < $WORKSPACE/srcdir/patches/lt_init_gmp.diff
#mv configure.in configure.ac
#autoreconf -i

CXXFLAGS="-I$prefix/include"; export CXXFLAGS
CPPFLAGS="-I$prefix/include"; export CPPFLAGS
CFLAGS="-I$prefix/include"; export CFLAGS
LDFLAGS="-L$prefix/lib"; export LDFLAGS

./configure --prefix=$prefix --host=$target lt_cv_deplibs_check_method=pass_all  --disable-shared --enable-static

make -j6

mkdir $prefix/bin
cp sdpa_gmp $prefix/bin/sdpa_gmp
cp COPYING $prefix/bin/COPYING
"""


# platforms are restricted by libcxxwrap-julia, which requires gcc7 or gcc8
# and hence will not work with the official binaries for windows (which uses gcc4)

platforms = Platform[
    # MacOS(:x86_64, compiler_abi=CompilerABI(:gcc7)),
    # MacOS(:x86_64, compiler_abi=CompilerABI(:gcc8)),
    Linux(:x86_64, compiler_abi=CompilerABI(:gcc7, :cxx11)),
    Linux(:x86_64, compiler_abi=CompilerABI(:gcc8, :cxx11)),
]

# The products that we will ensure are always built
products(prefix) = [
    ExecutableProduct(prefix, "sdpa_gmp", :sdpa_gmp),
    # LibraryProduct(prefix, "libsdpa", :libsdpa),
    # LibraryProduct(prefix, "libsdpawrap", :libsdpawrap)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/GMP-v6.1.2-1/build_GMP.v6.1.2.jl",
    # "https://github.com/JuliaOpt/COINBLASBuilder/releases/download/v1.4.6-1-static/build_COINBLASBuilder.v1.4.6.jl",
    # "https://github.com/JuliaOpt/COINLapackBuilder/releases/download/v1.5.6-1-static/build_COINLapackBuilder.v1.5.6.jl",
    # "https://github.com/JuliaOpt/COINMetisBuilder/releases/download/v1.3.5-1-static/build_COINMetisBuilder.v1.3.5.jl",
    # "https://github.com/JuliaOpt/COINMumpsBuilder/releases/download/v1.6.0-1-static-nm/build_COINMumpsBuilder.v1.6.0.jl",
    # "https://github.com/JuliaInterop/libcxxwrap-julia/releases/download/v0.5.1/build_libcxxwrap-julia-1.0.v0.5.1.jl",
    # "https://github.com/JuliaPackaging/JuliaBuilder/releases/download/v1.0.0-2/build_Julia.v1.0.0.jl"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
