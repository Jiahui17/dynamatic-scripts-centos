#!/usr/bin/env bash

#----------------------------------------------------------------------------
#- This script fetch the circt from remote, and compile circt and dynamatic
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

build_circt () {
	local circt_dir=$SCRIPT_CWD/circt
	cd $circt_dir && mkdir -p build && cd build

	cmake3 -G Ninja .. \
		-DMLIR_DIR=$LLVM_PREFIX/build/lib/cmake/mlir \
		-DLLVM_DIR=$LLVM_PREFIX/build/lib/cmake/llvm \
		-DCMAKE_BUILD_TYPE=$BUILD_TYPE \
		-DLLVM_ENABLE_ASSERTIONS=ON \
		-DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
		-DVERILATOR_DISABLE=ON \
		-DVIVADO_DISABLE=ON \
		-DCLANG_TIDY_DISABLE=ON \
		-DSYSTEMC_DISABLE=ON \
		-DQUARTUS_DISABLE=ON \
		-DQUESTA_DISABLE=ON \
		-DYOSYS_DISABLE=ON \
		-DIVERILOG_DISABLE=ON \
		-DYOSYS_DISABLE=ON \
		-DCAPNP_DISABLE=ON \
		-DOR_TOOLS_DISABLE=ON \
		-DCAPNP_DISABLE=ON \
		$CMAKE_FLAGS_SUPER

	ninja -j $(nproc)
}

build_dynamatic () {
	cd $SCRIPT_CWD && mkdir -p build && cd build
	cmake3 -G Ninja .. \
		-DCIRCT_DIR=$CIRCT_DIR_PREFIX/build/lib/cmake/circt \
		-DMLIR_DIR=$LLVM_PREFIX/build/lib/cmake/mlir \
		-DLLVM_DIR=$LLVM_PREFIX/build/lib/cmake/llvm \
		-DCMAKE_BUILD_TYPE=Debug \
		-DLLVM_ENABLE_ASSERTIONS=ON \
		-DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
		$CMAKE_FLAGS_SUPER
	ninja -j$(nproc)
}

make_simlink () {
	# Create bin/ directory at the project's root
	cd "$SCRIPT_CWD" && mkdir -p bin

	# Create symbolic links to all binaries we use from subfolders
	ln -f --symbolic $POLYGEIST_DIR_PREFIX/build/bin/cgeist ./bin/cgeist
	ln -f --symbolic $POLYGEIST_DIR_PREFIX/build/bin/polygeist-opt ./bin/polygeist-opt
	ln -f --symbolic $POLYGEIST_DIR_PREFIX/llvm-project/build/bin/mlir-opt ./bin/mlir-opt
	ln -f --symbolic $CIRCT_DIR_PREFIX/build/bin/circt-opt ./bin/circt-opt
	ln -f --symbolic ../build/bin/dynamatic ./bin/dynamatic
	ln -f --symbolic ../build/bin/dynamatic-opt ./bin/dynamatic-opt
	ln -f --symbolic ../build/bin/export-dot ./bin/export-dot
	ln -f --symbolic ../build/bin/exp-frequency-profiler ./bin/exp-frequency-profiler
	ln -f --symbolic ../build/bin/handshake-simulator ./bin/handshake-simulator

	# Make the scripts used by the frontend executable
	chmod +x tools/dynamatic/scripts/synthesize.sh
	chmod +x tools/dynamatic/scripts/write-hdl.sh
	chmod +x tools/dynamatic/scripts/simulate.sh
	chmod +x tools/dynamatic/scripts/logic-synthesize.sh

	# Symlink polygeist
	rm -r $SCRIPT_CWD/polygeist
	ln -s $POLYGEIST_DIR_PREFIX $SCRIPT_CWD/polygeist
}

configure_circt () {
	git submodule init circt

	# fetch the circt (not recursive to avoid cloning the llvm/mlir)
	git submodule update circt
}

set -e
configure_circt
build_circt
build_dynamatic
make_simlink
