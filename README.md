# SDPABuilder

[![Build Status](https://travis-ci.com/ericphanson/SDPA_GMP_Builder.svg?branch=master)](https://travis-ci.com/ericphanson/SDPA_GMP_Builder)

This repository builds binary artifacts for [SDPA-GMP](http://sdpa.sourceforge.net/).
Binary artifacts are automatically uploaded to
[this repository's GitHub releases page](https://github.com/ericphanson/SDPA_GMP_Builder/releases)
whenever a tag is created on this repository. The source code can be found here: <https://github.com/ericphanson/sdpa-gmp>.

This repository was created using [BinaryBuilder.jl](https://github.com/JuliaPackaging/BinaryBuilder.jl)

There is one platform we were not able to get BinaryBuilder to work with: building SDPA-GMP binaries to run on Windows Subsystem for Linux (WSL). However, we could build SDPA-GMP by running WSL locally and building the binary there. The result of this can be found here: <https://github.com/ericphanson/SDPA_GMP_Builder/tree/master/deps/sdpa_gmp_wsl>.

SDPA-GMP is available under a GPLv2 license, which can be found here: <https://github.com/ericphanson/SDPA_GMP_Builder/tree/master/deps/COPYING>.
