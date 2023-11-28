#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

DYNAMATIC_DIR="$SCRIPT_DIR/dynamatic"
SRC_DIR="$PWD"
OUTPUT_DIR="${PWD}/reports"
KERNEL_NAME=$(basename $(ls $SRC_DIR/*.c | head -1) | sed 's/.c//g')
USE_SIMPLE_BUFFERS=0

$SCRIPT_DIR/compile.sh $DYNAMATIC_DIR $SRC_DIR $OUTPUT_DIR $KERNEL_NAME $USE_SIMPLE_BUFFERS
