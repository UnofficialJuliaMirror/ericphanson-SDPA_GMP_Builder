# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "SDPA_GMP-QD-DD_Builder"
version = v"7.1.2"

# Collection of sources required to build SDPABuilder
sources = [
    "https://github.com/ericphanson/sdpa-gmp/archive/v7.1.3-patch-2.tar.gz" =>
    "198cf7449ae751911f40b501f4b9a4e87c5cefd0110442067e16d6c212d996ea",
    "https://gmplib.org/download/gmp/gmp-6.1.2.tar.bz2" =>
    "5275bb04f4863a13516b2f39392ac5e272f5e1bb8057b18aec1c9b79d73d8fb2",
    "https://github.com/ericphanson/sdpa-qd/archive/v7.1.2.tar.gz" =>
    "e8d8d52168fc8b9c07e724221e02bfd6e436bd8f89939cfec13a00e9e4a4f916",
    "https://github.com/ericphanson/sdpa-dd/archive/v7.1.2.tar.gz" =>
    "8e246a40c7b43b63016522f71611cba7dad1768dd78c6f65be5d8385110ef8ef",
]

# Bash recipe for building across all platforms
script = raw"""
# Build GMP
cd $WORKSPACE/srcdir/gmp-*

update_configure_scripts

if [ $target = "x86_64-apple-darwin14" ]; then
  # seems static linking requires apple's ar
  export AR=/opt/x86_64-apple-darwin14/bin/x86_64-apple-darwin14-ar
fi

flags=(--enable-cxx --disable-shared --enable-static --with-pic)

# On x86_64 architectures, build fat binary
if [[ ${proc_family} == intel ]]; then
    flags+=(--enable-fat)
fi

./configure --prefix=$prefix --build=x86_64-linux-gnu --host=$target  ${flags[@]}
make
make install

# Build SDPA-GMP

cd $WORKSPACE/srcdir/sdpa-gmp-*/

update_configure_scripts

if [ $target = "x86_64-apple-darwin14" ]; then
  # seems static linking requires apple's ar
  export AR=/opt/x86_64-apple-darwin14/bin/x86_64-apple-darwin14-ar
fi

mv configure.in configure.ac
autoreconf -i

CXXFLAGS="-std=c++03"; export CXXFLAGS

./configure --prefix=$prefix --with-gmp-includedir=$prefix/include --with-gmp-libdir=$prefix/lib --host=$target lt_cv_deplibs_check_method=pass_all 

make

cp sdpa_gmp $prefix/bin/sdpa_gmp
cp COPYING $prefix/bin/COPYING

# Build SDPA-QD

cd $WORKSPACE/srcdir/sdpa-qd-*/

update_configure_scripts

if [ $target = "x86_64-apple-darwin14" ]; then
  # seems static linking requires apple's ar
  export AR=/opt/x86_64-apple-darwin14/bin/x86_64-apple-darwin14-ar
fi

mv configure.in configure.ac
autoreconf -i

CXXFLAGS="-std=c++03"; export CXXFLAGS

./configure --prefix=$prefix --with-qd-includedir=$prefix/include --with-qd-libdir=$prefix/lib --host=$target lt_cv_deplibs_check_method=pass_all 

make

cp sdpa_qd $prefix/bin/sdpa_qd

# Build SDPA-QD

cd $WORKSPACE/srcdir/sdpa-dd-*/

update_configure_scripts

if [ $target = "x86_64-apple-darwin14" ]; then
  # seems static linking requires apple's ar
  export AR=/opt/x86_64-apple-darwin14/bin/x86_64-apple-darwin14-ar
fi

mv configure.in configure.ac
autoreconf -i

CXXFLAGS="-std=c++03"; export CXXFLAGS

./configure --prefix=$prefix --with-qd-includedir=$prefix/include --with-qd-libdir=$prefix/lib --host=$target lt_cv_deplibs_check_method=pass_all 

make

cp sdpa_dd $prefix/bin/sdpa_dd
"""

platforms = Platform[
   MacOS(:x86_64),
   Linux(:x86_64),
   # Windows(:x86_64), # doesn't work :(
]

# The products that we will ensure are always built
products(prefix) = [
    ExecutableProduct(prefix, "sdpa_gmp", :sdpa_gmp),
    ExecutableProduct(prefix, "sdpa_qd", :sdpa_qd),
    ExecutableProduct(prefix, "sdpa_dd", :sdpa_dd),
]

# Dependencies that must be installed before this package can be built
dependencies = [ "https://github.com/ericphanson/QD_Builder/releases/download/v2.3.22/build_QD.v2.3.22.jl",


# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
