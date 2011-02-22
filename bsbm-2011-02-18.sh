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

ROOT_PATH=`pwd`
BSBM_ROOT_PATH=/tmp/bsbm

BSBM_NUM_QUERY_MIXES=500
BSBM_NUM_QUERY_WARM_UP=50
BSBM_SCALE_FACTOR_VALUES=( 1001 2002 )
BSBM_CONCURRENT_CLIENTS_VALUES=( 1 2 ) 

BSBM_SEED=1212123
BSBM_QUERY_TIMEOUT=0

TDB_LOADER=tdbloader
FUSEKI_SPARQL_QUERY_URL="http://127.0.0.1:3030/bsbm/query"
FUSEKI_SPARQL_UPDATE_URL="http://127.0.0.1:3030/bsbm/update"

if [ ! -d "$BSBM_ROOT_PATH" ]; then
    mkdir $BSBM_ROOT_PATH
fi

if [ ! -d "$BSBM_ROOT_PATH/results" ]; then
    mkdir $BSBM_ROOT_PATH/results
fi


free_os_caches() {
    echo "== Freeing OS caches..."
    sync
    sudo bash -c "echo 3 > /proc/sys/vm/drop_caches"
    echo "== Done."
}


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
        CMD="-Xmx1024M -server benchmark.generator.Generator -fc -ud -pc $BSBM_SCALE_FACTOR -s nt"
        echo "== java -cp \"lib/*\" $CMD"
        java -cp "lib/*" $CMD > $BSBM_ROOT_PATH/results/bsbmtools-generator-$BSBM_SCALE_FACTOR.txt
        if [ ! -d "$BSBM_ROOT_PATH/datasets" ]; then
            mkdir $BSBM_ROOT_PATH/datasets
        fi
        mkdir $BSBM_ROOT_PATH/datasets/bsbm-dataset-$BSBM_SCALE_FACTOR
        mv $BSBM_ROOT_PATH/bsbmtools/dataset* $BSBM_ROOT_PATH/datasets/bsbm-dataset-$BSBM_SCALE_FACTOR/
        mv $BSBM_ROOT_PATH/bsbmtools/td_data $BSBM_ROOT_PATH/datasets/bsbm-dataset-$BSBM_SCALE_FACTOR/
        echo "== Finish: $(date +"%Y-%m-%d %H:%M:%S")"
    else
        echo "==== [skipped] Generating dataset: scale=$BSBM_SCALE_FACTOR ..."
    fi
}


run_bsbmtools_rampup() {
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

    if [ ! -f "$BSBM_ROOT_PATH/results/$BSBM_SCALE_FACTOR-$SYSTEM_UNDER_TEST-$USE_CASE-$BSBM_CONCURRENT_CLIENTS-rampup.txt" ]; then
        echo "==== Running BSBM: sut=$SYSTEM_UNDER_TEST, scale=$BSBM_SCALE_FACTOR, clients=$BSBM_CONCURRENT_CLIENTS, usecase=$USE_CASE ..."
        echo "== Start: $(date +"%Y-%m-%d %H:%M:%S")"
        cd $BSBM_ROOT_PATH/bsbmtools
        RESULT_FILENAME=$BSBM_SCALE_FACTOR-$SYSTEM_UNDER_TEST-$USE_CASE-$BSBM_CONCURRENT_CLIENTS-rampup
        CMD="-Xmx256M benchmark.testdriver.TestDriver -rampup -runs 8000 -seed 1212123 -idir $BSBM_ROOT_PATH/datasets/bsbm-dataset-$BSBM_SCALE_FACTOR/td_data -u $SPARQL_UPDATE_URL -udataset $BSBM_ROOT_PATH/datasets/bsbm-dataset-$BSBM_SCALE_FACTOR/dataset_update.nt -o $BSBM_ROOT_PATH/results/$RESULT_FILENAME.xml $SPARQL_QUERY_URL"
        echo "== java -cp \"lib/*\" $CMD"
        java -cp "lib/*" $CMD > $BSBM_ROOT_PATH/results/$RESULT_FILENAME.txt
        echo "== Finish: $(date +"%Y-%m-%d %H:%M:%S")"
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
        CMD="-Xmx256M benchmark.testdriver.TestDriver -runs $BSBM_NUM_QUERY_MIXES -w $BSBM_NUM_QUERY_WARM_UP -mt $BSBM_CONCURRENT_CLIENTS -t $BSBM_QUERY_TIMEOUT -ucf $USE_CASE_FILENAME -seed $BSBM_SEED -idir $BSBM_ROOT_PATH/datasets/bsbm-dataset-$BSBM_SCALE_FACTOR/td_data -u $SPARQL_UPDATE_URL -udataset $BSBM_ROOT_PATH/datasets/bsbm-dataset-$BSBM_SCALE_FACTOR/dataset_update.nt -o $BSBM_ROOT_PATH/results/$RESULT_FILENAME.xml $SPARQL_QUERY_URL"
        echo "== java -cp \"lib/*\" $CMD"
        java -cp "lib/*" $CMD > $BSBM_ROOT_PATH/results/$RESULT_FILENAME.txt
        echo "== Finish: $(date +"%Y-%m-%d %H:%M:%S")"
    fi
}


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


setup_fuseki() {
    if [ ! -d "$BSBM_ROOT_PATH/fuseki" ]; then
        echo "==== Checking-out and compiling Fuseki source code ..."
        echo "== Start: $(date +"%Y-%m-%d %H:%M:%S")"
        cd $BSBM_ROOT_PATH
        svn co http://jena.svn.sourceforge.net/svnroot/jena/Fuseki/trunk fuseki
        cd $BSBM_ROOT_PATH/fuseki
        mvn package
        echo "== Finish: $(date +"%Y-%m-%d %H:%M:%S")"
    else
        echo "==== [skipped] Checking-out and compiling Fuseki source code ..."
    fi
}


run_fuseki() {
    echo "== Starting Fuseki ..."
#    java -jar $BSBM_ROOT_PATH/fuseki/target/fuseki-0.2.0-SNAPSHOT-sys.jar --update --loc=$BSBM_ROOT_PATH/datasets/tdb-$BSBM_SCALE_FACTOR/TDB /bsbm &>> /dev/null &
    java -jar $BSBM_ROOT_PATH/fuseki/target/fuseki-0.2.0-SNAPSHOT-sys.jar --update --loc=$BSBM_ROOT_PATH/datasets/tdb-$BSBM_SCALE_FACTOR/TDB /bsbm &>> $BSBM_ROOT_PATH/results/$BSBM_SCALE_FACTOR-fuseki-$1-$BSBM_CONCURRENT_CLIENTS.log &
    sleep 4
    echo "== Done."
}


shutdown_fuseki() {
    echo "== Shutting down Fuseki ..."
    kill `ps -ef | grep fuseki | grep -v grep | awk '{print $2}'`
    sleep 1
    echo "== Done."
}


test_fuseki() {
    shutdown_fuseki

    if [ ! -f "$BSBM_ROOT_PATH/results/$BSBM_SCALE_FACTOR-fuseki-explore-$BSBM_CONCURRENT_CLIENTS.txt" ]; then
        run_fuseki "explore"
        free_os_caches
        run_bsbmtools_rampup "fuseki" $FUSEKI_SPARQL_QUERY_URL $FUSEKI_SPARQL_UPDATE_URL "explore"
        run_bsbmtools "fuseki" $FUSEKI_SPARQL_QUERY_URL $FUSEKI_SPARQL_UPDATE_URL "explore"
        shutdown_fuseki
    else
        echo "==== [skipped] Running BSBM: sut=Fuseki, scale=$BSBM_SCALE_FACTOR, clients=$BSBM_CONCURRENT_CLIENTS, usecase=explore ..."
    fi

    if [ ! -f "$BSBM_ROOT_PATH/results/$BSBM_SCALE_FACTOR-fuseki-update-$BSBM_CONCURRENT_CLIENTS.txt" ]; then
        run_fuseki "update"
        free_os_caches
        run_bsbmtools_rampup "fuseki" $FUSEKI_SPARQL_QUERY_URL $FUSEKI_SPARQL_UPDATE_URL "update"
        run_bsbmtools "fuseki" $FUSEKI_SPARQL_QUERY_URL $FUSEKI_SPARQL_UPDATE_URL "update"
        shutdown_fuseki
    else
        echo "==== [skipped] Running BSBM: sut=Fuseki, scale=$BSBM_SCALE_FACTOR, clients=$BSBM_CONCURRENT_CLIENTS, usecase=update ..."
    fi

    if [ ! -f "$BSBM_ROOT_PATH/results/$BSBM_SCALE_FACTOR-fuseki-bi-$BSBM_CONCURRENT_CLIENTS.txt" ]; then
        run_fuseki "bi"
        free_os_caches
        run_bsbmtools_rampup "fuseki" $FUSEKI_SPARQL_QUERY_URL $FUSEKI_SPARQL_UPDATE_URL "bi"
        run_bsbmtools "fuseki" $FUSEKI_SPARQL_QUERY_URL $FUSEKI_SPARQL_UPDATE_URL "bi"
        shutdown_fuseki
    else
        echo "==== [skipped] Running BSBM: sut=Fuseki, scale=$BSBM_SCALE_FACTOR, clients=$BSBM_CONCURRENT_CLIENTS, usecase=bi ..."
    fi
}


setup_bsbmtools
setup_tdb
setup_fuseki


for BSBM_SCALE_FACTOR in ${BSBM_SCALE_FACTOR_VALUES[@]} 
do
    generate_bsbmtools_dataset
    load_tdb
done


for BSBM_SCALE_FACTOR in ${BSBM_SCALE_FACTOR_VALUES[@]} 
do
    for BSBM_CONCURRENT_CLIENTS in ${BSBM_CONCURRENT_CLIENTS_VALUES[@]} 
    do
        test_fuseki
    done
done





















