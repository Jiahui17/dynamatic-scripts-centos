#!/usr/bin/env bash

#-------------------------------------------------------
#- This script runs the default dynamatic flow
#-------------------------------------------------------

# Exits the script with a fatal error message if the last command that was
# called before this function failed, otherwise optionally prints an information
# message.
#   $1: fatal error message
#   $2: [optional] information message
exit_on_fail() {
	if [[ $? -ne 0 ]]; then
		if [[ ! -z $1 ]]; then
			echo "[FATAL] $1"
			exit 1
		fi
		echo "[FATAL] Failed!"
		exit 1
	else
		if [[ ! -z $2 ]]; then
			echo "[INFO] $2"
		fi
	fi
}

bench_path="."
output_path='reports'
name=$(basename $(ls ${bench_path}/src/*.cpp| head -1) | sed 's/.cpp//g')
hdl_path="$bench_path/hdl"

# Generated directories/files
d_comp="$bench_path/$output_path/comp"
f_affine="$d_comp/affine.mlir"
f_affine_mem="$d_comp/affine_mem.mlir"
f_scf="$d_comp/scf.mlir"
f_scf_transformed="$d_comp/scf_transformed.mlir"
f_std="$d_comp/std.mlir"
f_std_transformed="$d_comp/std_transformed.mlir"
f_std_dyn_transformed="$d_comp/std_dyn_transformed.mlir"
f_handshake="$d_comp/handshake.mlir"
f_handshake_transformed="$d_comp/handshake_transformed.mlir"
f_handshake_buffered="$d_comp/handshake_buffered.mlir"
f_handshake_export="$d_comp/handshake_export.mlir"
f_dot_visual="$d_comp/handshake_buffered.dot"
f_dot_legacy="$bench_path/$output_path/${name}_optimized.dot"
f_png="$d_comp/handshake_buffered.png"
f_frequency_csv="$d_comp/frequencies.csv"

verify_dir="${bench_path}/sim"

# format the benchmark using clang-format (otherwise the last step would
# not work)
clang-format -i "$bench_path/src/$name.cpp"
exit_on_fail "Failed clang-format" "clang-formatted"

cp "$bench_path/src/$name.cpp" "$bench_path/src/$name.c"

rm -rf "$d_comp" && mkdir -p "$d_comp"

# source code -> affine dialect
echo $POLYGEIST_PATH
include="$POLYGEIST_PATH/llvm-project/clang/lib/Headers/"
"$POLYGEIST_CLANG_BIN" "$bench_path/src/$name.c" -I "$include" \
	--function="$name" -S -O3 --memref-fullrank --raise-scf-to-affine \
	> "$f_affine" 2>/dev/null
exit_on_fail "Failed source -> affine conversion" "Lowered to affine"

# memory analysis
"$DYNAMATIC_OPT_BIN" "$f_affine" --allow-unregistered-dialect \
	--name-memory-ops --analyze-memory-accesses > "$f_affine_mem"
exit_on_fail "Failed memory analysis" "Passed memory analysis"

# affine dialect -> scf dialect
"$DYNAMATIC_OPT_BIN" "$f_affine_mem" --allow-unregistered-dialect \
	--lower-affine-to-scf > "$f_scf"
exit_on_fail "Failed affine -> scf conversion" "Lowered to scf"

# scf transformations
loop_rotate="--scf-rotate-for-loops"
"$DYNAMATIC_OPT_BIN" "$f_scf" --allow-unregistered-dialect \
	--scf-simple-if-to-select $loop_rotate \
	> "$f_scf_transformed"
exit_on_fail "Failed to transform scf IR" "Transformed scf"

# scf dialect -> std dialect
"$DYNAMATIC_OPT_BIN" "$f_scf_transformed" --allow-unregistered-dialect \
	--lower-scf-to-cf > "$f_std"
exit_on_fail "Failed scf -> std conversion" "Lowered to std"

# std transformations (1)
"$MLIR_OPT_BIN" "$f_std" --allow-unregistered-dialect --canonicalize --cse \
	--sccp --symbol-dce --control-flow-sink --loop-invariant-code-motion \
	--canonicalize \
	> "$f_std_transformed"
exit_on_fail "Failed to transform std IR (1)" "Transformed std (1)"

# std transformations (2)
"$DYNAMATIC_OPT_BIN" "$f_std_transformed" --allow-unregistered-dialect \
	--flatten-memref-row-major --flatten-memref-calls \
	--arith-reduce-strength --push-constants \
	> "$f_std_dyn_transformed"
exit_on_fail "Failed to transform std IR (2)" "Transformed std (2)"

# std dialect -> handshake dialect
echo "$bench_path/src/$name.c"
"$DYNAMATIC_OPT_BIN" "$f_std_dyn_transformed" --allow-unregistered-dialect \
	--lower-std-to-handshake-fpga18="id-basic-blocks" \
	--handshake-fix-arg-names="source=$bench_path/src/$name.c" \
	> "$f_handshake"
exit_on_fail "Failed std -> handshake conversion" "Lowered to handshake"

# Handshake transformations
"$DYNAMATIC_OPT_BIN" "$f_handshake" --allow-unregistered-dialect \
	--handshake-concretize-index-type="width=32" \
	--handshake-minimize-cst-width --handshake-optimize-bitwidths="legacy" \
	--handshake-materialize-forks-sinks --handshake-infer-basic-blocks \
	> "$f_handshake_transformed"
exit_on_fail "Failed to transform handshake IR" "Transformed handshake"

test_input="$bench_path/src/test_input.txt"
"$DYNAMATIC_PROFILER_BIN" "$f_std_dyn_transformed" --top-level-function="$name" \
	--input-args-file="$test_input" > $f_frequency_csv
exit_on_fail "Failed to run frequency profiler" "Ran frequency profiler"

#--------------------------------------
#- Buffer placement (regular)
#--------------------------------------
# # Run Buffer placement
# echo_info "Placing smart buffers"
# "$DYNAMATIC_OPT_BIN" "$f_handshake_transformed" \
# 	--allow-unregistered-dialect \
# 	--handshake-set-buffering-properties="version=fpga20" \
# 	--handshake-place-buffers="timing-models=$DYNAMATIC_PATH/data/components.json frequencies=$d_comp/frequencies.csv dump-logs" \
# 	> "$f_handshake_buffered"

#--------------------------------------
#- Buffer placement (iterative-buffer)
#--------------------------------------
# Run Buffer placement
echo_info "Placing smart buffers"
"$DYNAMATIC_OPT_BIN" "$f_handshake_transformed" \
	--allow-unregistered-dialect \
	--handshake-set-buffering-properties="version=fpga20" \
	--handshake-iterative-buffers="timing-models=$DYNAMATIC_PATH/data/components.json frequencies=$d_comp/frequencies.csv dump-logs" \
	> "$f_handshake_buffered"
exit_on_fail "Failed to buffer IR" "Buffered handshake"

# Export DOT for visual purpose
mode="visual"
edge_style="spline"
"$DYNAMATIC_EXPORT_DOT_BIN" "$f_handshake_buffered" "--mode=$mode" \
	"--edge-style=$edge_style" \
	"--timing-models=$DYNAMATIC_PATH/data/components.json" \
	> "$f_dot_visual"
dot -Tpng "$f_dot_visual" > "$f_png"
exit_on_fail "Failed to create DOT" "Created DOT"

# Canonicalization
"$DYNAMATIC_OPT_BIN" "$f_handshake_buffered" \
	--allow-unregistered-dialect --handshake-canonicalize \
	> "$f_handshake_export"
exit_on_fail "Failed to canonicalize handshake" "Canonicalized handshake"

# Export DOT to bridge with dot2vhdl
mode="legacy"
edge_style="spline"
"$DYNAMATIC_EXPORT_DOT_BIN" "$f_handshake_export" "--mode=$mode" \
	"--edge-style=$edge_style" \
	"--timing-models=$DYNAMATIC_PATH/data/components.json" \
	> "$f_dot_legacy"
exit_on_fail "Failed to create legacy DOT" "Created legacy DOT"

$DOT2VHDL_BIN "${bench_path}/$output_path/${name}_optimized" \
	|| fail "error - write_hdl failed!"

mkdir -p $hdl_path
mv "${bench_path}/reports/${name}_optimized.vhd" "$hdl_path/${name}_optimized.vhd"
cp "$DYNAMATIC_COMPONENTS_PATH/"*.vhd $hdl_path
cp "$DYNAMATIC_COMPONENTS_PATH/tcl"/*.tcl $hdl_path
cp "$DYNAMATIC_COMPONENTS_PATH/ip_vhdl"/*.vhd $hdl_path

# perform functional verification
mkdir -p "${bench_path}/sim/"{C_SRC,VHDL_SRC,REF_OUT,HLS_VERIFY,INPUT_VECTORS,VHDL_OUT}
cp "${bench_path}"/src/*.{cpp,h} "${verify_dir}"/C_SRC
cp "${bench_path}"/hdl/* "${verify_dir}"/VHDL_SRC
rm -r "$verify_dir/HLS_VERIFY/work"
cd "$verify_dir/HLS_VERIFY"

# run the verifier and save the log
$HLS_VERIFIER_BIN cover -aw32 "../C_SRC/$name.cpp" "../C_SRC/$name.cpp" "$name"
exit_on_fail "Failed functional verification!" "Functional verification completed!"

exit 0
