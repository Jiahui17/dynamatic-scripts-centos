#!/usr/bin/env bash

#--------------------------------------------------------------------
#- this script sets up and build everything of legacy-dynamatic
#--------------------------------------------------------------------

# this script should be called from dynamatic's source directory
SCRIPT_CWD=$PWD

set -e

LEGACY_DYNAMATIC_ROOT=$SCRIPT_CWD/dynamatic-utils/legacy-dynamatic/dhls/etc/dynamatic

mkdir -p $LEGACY_DYNAMATIC_ROOT

git clone git@github.com:Jiahui17/legacy-dynamatic.git $LEGACY_DYNAMATIC_ROOT

cd $LEGACY_DYNAMATIC_ROOT && bash build.sh && echo "successfully built legacy-dynamatic"

