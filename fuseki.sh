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


FUSEKI_SPARQL_QUERY_URL="http://127.0.0.1:3030/bsbm/query"
FUSEKI_SPARQL_UPDATE_URL="http://127.0.0.1:3030/bsbm/update"


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
    PID="`ps -ef | grep fuseki | grep -v grep | awk '{print $2}'`"
    if [[ -n $PID ]] ; then
        echo "== Shutting down Fuseki ..."
        kill $PID
        sleep 1
        echo "== Done."
    else
        echo "== [skipped] Shutting down Fuseki ..."
    fi
}


test_fuseki() {
    shutdown_fuseki

    if [ ! -f "$BSBM_ROOT_PATH/results/$BSBM_SCALE_FACTOR-fuseki-explore-$BSBM_CONCURRENT_CLIENTS.txt" ]; then
        run_fuseki "explore"
        free_os_caches
        run_bsbmtools "fuseki" $FUSEKI_SPARQL_QUERY_URL $FUSEKI_SPARQL_UPDATE_URL "explore"
        shutdown_fuseki
    else
        echo "==== [skipped] Running BSBM: sut=Fuseki, scale=$BSBM_SCALE_FACTOR, clients=$BSBM_CONCURRENT_CLIENTS, usecase=explore ..."
    fi

#    if [ ! -f "$BSBM_ROOT_PATH/results/$BSBM_SCALE_FACTOR-fuseki-update-$BSBM_CONCURRENT_CLIENTS.txt" ]; then
#        run_fuseki "update"
#        free_os_caches
#        run_bsbmtools "fuseki" $FUSEKI_SPARQL_QUERY_URL $FUSEKI_SPARQL_UPDATE_URL "update"
#        shutdown_fuseki
#    else
#        echo "==== [skipped] Running BSBM: sut=Fuseki, scale=$BSBM_SCALE_FACTOR, clients=$BSBM_CONCURRENT_CLIENTS, usecase=update ..."
#    fi

#    if [ ! -f "$BSBM_ROOT_PATH/results/$BSBM_SCALE_FACTOR-fuseki-bi-$BSBM_CONCURRENT_CLIENTS.txt" ]; then
#        run_fuseki "bi"
#        free_os_caches
#        run_bsbmtools "fuseki" $FUSEKI_SPARQL_QUERY_URL $FUSEKI_SPARQL_UPDATE_URL "bi"
#        shutdown_fuseki
#    else
#        echo "==== [skipped] Running BSBM: sut=Fuseki, scale=$BSBM_SCALE_FACTOR, clients=$BSBM_CONCURRENT_CLIENTS, usecase=bi ..."
#    fi
}


