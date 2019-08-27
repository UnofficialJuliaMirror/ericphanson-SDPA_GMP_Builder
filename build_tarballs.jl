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

cd $WORKSPACE/srcdir/sdpa-gmp-7.1.3/

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

mkdir $prefix/bin
cp sdpa_gmp $prefix/bin/sdpa_gmp
cp COPYING $prefix/bin/COPYING
"""


# platforms are restricted by libcxxwrap-julia, which requires gcc7 or gcc8
# and hence will not work with the official binaries for windows (which uses gcc4)

platforms = Platform[
   MacOS(:x86_64),
   Linux(:x86_64),
   # Windows(:x86_64), # doesn't work :(
]

# The products that we will ensure are always built
products(prefix) = [
    ExecutableProduct(prefix, "sdpa_gmp", :sdpa_gmp),
    LibraryProduct(prefix, "libgmp", :libgmp)
]

# Dependencies that must be installed before this package can be built
dependencies = []

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
