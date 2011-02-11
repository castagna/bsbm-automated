#!/bin/bash

##
# Copyright © 2011 Talis Systems Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##


TDB_LOADER=tdbloader


load_tdb() {
    if [ ! -d "$BSBM_ROOT_PATH/datasets/tdb-$BSBM_SCALE_FACTOR" ]; then
        echo "==== Loading data in TDB: scale=$BSBM_SCALE_FACTOR ..."
        echo "== Start: $(date +"%Y-%m-%d %H:%M:%S")"
        free_os_caches
        export TDBROOT=$BSBM_ROOT_PATH/tdb
        export PATH=$PATH:$BSBM_ROOT_PATH/tdb/bin2
        mkdir $BSBM_ROOT_PATH/datasets/tdb-$BSBM_SCALE_FACTOR
        if [ ! -d "$BSBM_ROOT_PATH/results" ]; then
            mkdir $BSBM_ROOT_PATH/results
        fi
        $TDB_LOADER -v --loc=$BSBM_ROOT_PATH/datasets/tdb-$BSBM_SCALE_FACTOR/TDB $BSBM_ROOT_PATH/datasets/bsbm-dataset-$BSBM_SCALE_FACTOR/dataset.nt > $BSBM_ROOT_PATH/results/tdb-$BSBM_SCALE_FACTOR-tdbload.txt
        tdbstats --loc $BSBM_ROOT_PATH/datasets/tdb-$BSBM_SCALE_FACTOR/TDB > $BSBM_ROOT_PATH/datasets/tdb-$BSBM_SCALE_FACTOR/TDB/stats.opt
        echo "== Finish: $(date +"%Y-%m-%d %H:%M:%S")"
    else
        echo "==== [skipped] Loading data in TDB: scale=$BSBM_SCALE_FACTOR ..."
    fi
}


setup_tdb() {
    if [ ! -d "$BSBM_ROOT_PATH/tdb" ]; then
        echo "==== Checking-out and compiling TDB source code ..."
        echo "== Start: $(date +"%Y-%m-%d %H:%M:%S")"
        cd $BSBM_ROOT_PATH
        svn co https://jena.svn.sourceforge.net/svnroot/jena/TDB/trunk/ tdb
        cd $BSBM_ROOT_PATH/tdb
        mvn package
        echo "== Finish: $(date +"%Y-%m-%d %H:%M:%S")"
    else
        echo "==== [skipped] Checking-out and compiling TDB source code ..."
    fi
}
