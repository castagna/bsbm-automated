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


setup_bsbmtools() {
    if [ ! -d "$BSBM_ROOT_PATH/bsbmtools" ]; then
        echo "==== Checking out and compiling BSBM Tools source code ..."
        echo "== Start: $(date +"%Y-%m-%d %H:%M:%S")"
        cd $BSBM_ROOT_PATH
        svn co https://bsbmtools.svn.sourceforge.net/svnroot/bsbmtools/trunk bsbmtools
        cd $BSBM_ROOT_PATH/bsbmtools
        ant jar
        echo "== Finish: $(date +"%Y-%m-%d %H:%M:%S")"
    else
        echo "==== [skipped] Checking out and compiling BSBM Tools source code ..."
    fi
}


generate_bsbmtools_dataset() {
    if [ ! -d "$BSBM_ROOT_PATH/datasets/bsbm-dataset-$BSBM_SCALE_FACTOR" ]; then
        echo "==== Generating dataset: scale=$BSBM_SCALE_FACTOR ..."
        echo "== Start: $(date +"%Y-%m-%d %H:%M:%S")"
        cd $BSBM_ROOT_PATH/bsbmtools
        java -cp "lib/*" -Xmx1024M -server benchmark.generator.Generator -fc -ud -pc $BSBM_SCALE_FACTOR -s nt
        if [ ! -d "$BSBM_ROOT_PATH/datasets" ]; then
            mkdir $BSBM_ROOT_PATH/datasets
        fi
        mkdir $BSBM_ROOT_PATH/datasets/bsbm-dataset-$BSBM_SCALE_FACTOR
        mv $BSBM_ROOT_PATH/bsbmtools/dataset* $BSBM_ROOT_PATH/datasets/bsbm-dataset-$BSBM_SCALE_FACTOR
        echo "== Finish: $(date +"%Y-%m-%d %H:%M:%S")"
    else
        echo "==== [skipped] Generating dataset: scale=$BSBM_SCALE_FACTOR ..."
    fi
}


run_bsbmtools() {
    SYSTEM_UNDER_TEST=`echo $1 | tr '[:upper:]' '[:lower:]'`
    SPARQL_QUERY_URL=$2
    SPARQL_UPDATE_URL=$3
    USE_CASE=$4

    if [[ $4 == "bi" ]] ; then
        USE_CASE=$4
        USE_CASE_FILENAME="usecases/businessIntelligence/sparql.txt"
    elif [[ $4 == "update" ]] ; then
        USE_CASE=$4
        USE_CASE_FILENAME="usecases/exploreAndUpdate/sparql.txt"
    elif [[ $4 == "explore" ]] ; then
        USE_CASE=$4
        USE_CASE_FILENAME="usecases/explore/sparql.txt"
    else
        USE_CASE=$4
        USE_CASE_FILENAME="usecases/explore/sparql.txt"
    fi

    if [ ! -f "$BSBM_ROOT_PATH/results/$BSBM_SCALE_FACTOR-$SYSTEM_UNDER_TEST-$USE_CASE-$BSBM_CONCURRENT_CLIENTS.txt" ]; then
        echo "==== Running BSBM: sut=$SYSTEM_UNDER_TEST, scale=$BSBM_SCALE_FACTOR, clients=$BSBM_CONCURRENT_CLIENTS, usecase=$USE_CASE ..."
        echo "== Start: $(date +"%Y-%m-%d %H:%M:%S")"
        cd $BSBM_ROOT_PATH/bsbmtools
        RESULT_FILENAME=$BSBM_SCALE_FACTOR-$SYSTEM_UNDER_TEST-$USE_CASE-$BSBM_CONCURRENT_CLIENTS
        CMD="-Xmx256M benchmark.testdriver.TestDriver -runs $BSBM_NUM_QUERY_MIXES -w $BSBM_NUM_QUERY_WARM_UP -mt $BSBM_CONCURRENT_CLIENTS -t $BSBM_QUERY_TIMEOUT -ucf $USE_CASE_FILENAME -seed $BSBM_SEED -u $SPARQL_UPDATE_URL -udataset $BSBM_ROOT_PATH/datasets/bsbm-dataset-$BSBM_SCALE_FACTOR/dataset_update.nt -o $BSBM_ROOT_PATH/results/$RESULT_FILENAME.xml $SPARQL_QUERY_URL"
        echo "== java -cp \"lib/*\" $CMD"
        java -cp "lib/*" $CMD > $BSBM_ROOT_PATH/results/$RESULT_FILENAME.txt
        echo "== Finish: $(date +"%Y-%m-%d %H:%M:%S")"
    fi
}
