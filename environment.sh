#!/usr/bin/env bash

#------------------------------------------------------
#- Source this file before you run anything else!
#------------------------------------------------------

export LEGACY_DYNAMATIC_PATH=`realpath "dynamatic-utils/legacy-dynamatic"`
export LEGACY_DYNAMATIC_LLVM_PATH=`realpath "/usr/local/llvm-6.0"`
export DYNAMATIC_PATH=`realpath "dynamatic"`

# ===- Leave the environment variables below as is ------------------------=== #

# Where this file is located
export DYNAMATIC_UTILS_PATH=`realpath "${PWD}"`

# Shortcuts to CIRCT and Polygeist (within new Dynamatic)
export CIRCT_PATH="/opt/circt"
export POLYGEIST_PATH="/opt/polygeist"

# get Gurobi
source /opt/gurobi*/grbenv.sh

# Make sure that python sets always gives the same ordering
export PYTHONHASHSEED=0

# Needed by legacy Dynamatic internally
export DHLS_INSTALL_DIR="${LEGACY_DYNAMATIC_PATH}/dhls"

# Dynamatic
export POLYGEIST_CLANG_BIN="${POLYGEIST_PATH}/build/bin/cgeist"
export POLYGEIST_OPT_BIN="${POLYGEIST_PATH}/build/bin/polygeist-opt"
export MLIR_OPT_BIN="${CIRCT_PATH}/llvm/build/bin/mlir-opt"
export CIRCT_OPT_BIN="${CIRCT_PATH}/build/bin/circt-opt"
export DYNAMATIC_OPT_BIN="${DYNAMATIC_PATH}/build/bin/dynamatic-opt"
export DYNAMATIC_PROFILER_BIN="${DYNAMATIC_PATH}/build/bin/exp-frequency-profiler"
export DYNAMATIC_EXPORT_DOT_BIN="${DYNAMATIC_PATH}/build/bin/export-dot"

# Legacy Dynamatic
export LEGACY_DYNAMATIC_ROOT="${LEGACY_DYNAMATIC_PATH}/dhls/etc/dynamatic"
export DOT2VHDL_BIN="${LEGACY_DYNAMATIC_ROOT}/dot2vhdl/bin/dot2vhdl"
export BUFFERS_BIN="${LEGACY_DYNAMATIC_ROOT}/Buffers/bin/buffers"
export HLS_VERIFIER_BIN="${LEGACY_DYNAMATIC_ROOT}/Regression_test/hls_verifier/HlsVerifier/build/hlsverifier"
export LLVM_CLANG_BIN="${LEGACY_DYNAMATIC_LLVM_PATH}/bin/clang"
export LLVM_OPT_BIN="${LEGACY_DYNAMATIC_LLVM_PATH}/bin/opt"
export LLVM_ANALYZE_BIN="${LEGACY_DYNAMATIC_LLVM_PATH}/bin/opt"
export DYNAMATIC_COMPONENTS_PATH="${LEGACY_DYNAMATIC_ROOT}/components"

# Add legacy dynamatic bin directory to path and set a couple environment
# variables required by the frontend
export PATH="${LEGACY_DYNAMATIC_PATH}/dhls/etc/dynamatic/bin:${PATH}"
export CLANG_DIR="$(dirname ${LLVM_CLANG_BIN})"
export OPT_DIR="$(dirname ${LLVM_OPT_BIN})"
export ELASTIC_DIR="$LEGACY_DYNAMATIC_ROOT/elastic-circuits"

