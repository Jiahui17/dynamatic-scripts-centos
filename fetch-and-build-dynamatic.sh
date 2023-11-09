#!/usr/bin/env bash

#--------------------------------------------------------------------
#- this script sets up and build everything of legacy-dynamatic
#--------------------------------------------------------------------

# this script should be called from dynamatic's source directory
SCRIPT_CWD=$PWD

set -e

DYNAMATIC_ROOT=$SCRIPT_CWD/dynamatic

mkdir -p $DYNAMATIC_ROOT

git clone git@github.com:EPFL-LAP/dynamatic.git $DYNAMATIC_ROOT


cd $DYNAMATIC_ROOT
git checkout origin/iterative-buffers
bash $SCRIPT_CWD/mybuild.sh && echo "successfully built dynamatic"
