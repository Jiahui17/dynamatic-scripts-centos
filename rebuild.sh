#!/usr/bin/env bash

#----------------------------------------------------------------------------
#- This script rebuild dynamatic without running cmake
#----------------------------------------------------------------------------

# this script should be called from dynamatic's source directory
SCRIPT_CWD=$PWD

CIRCT_DIR_PREFIX="$SCRIPT_CWD/circt"
POLYGEIST_DIR_PREFIX='/opt/polygeist'

LLVM_PREFIX='/opt/llvm'

export GUROBI_HOME="/opt/gurobi1000/linux64"
export PATH="${PATH}:${GUROBI_HOME}/bin"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${GUROBI_HOME}/lib"

CMAKE_FLAGS_SUPER="-DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
	-DLLVM_ENABLE_LLD=ON"

#---------------------
#- Wrapper functions -
#---------------------

rebuild_dynamatic () {
	cd $SCRIPT_CWD && mkdir -p build && cd build && ninja -j$(nproc)
}

set -e
rebuild_dynamatic
