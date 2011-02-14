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


JOSEKI_SPARQL_QUERY_URL="http://127.0.0.1:2020/sparql"
JOSEKI_SPARQL_UPDATE_URL="http://127.0.0.1:2020/update/service"


setup_joseki() {
    if [ ! -d "$BSBM_ROOT_PATH/Joseki-3.4.3" ]; then
        echo "==== Downloading Joseki ..."
        echo "== Start: $(date +"%Y-%m-%d %H:%M:%S")"
        cd $BSBM_ROOT_PATH
        wget https://downloads.sourceforge.net/project/joseki/Joseki-SPARQL/Joseki-3.4.3/joseki-3.4.3.zip
        unzip joseki-3.4.3.zip
        rm joseki-3.4.3.zip
        chmod 744 $BSBM_ROOT_PATH/Joseki-3.4.3/bin/rdfserver
        echo "== Finish: $(date +"%Y-%m-%d %H:%M:%S")"
    else
        echo "==== [skipped] Downloading Joseki ..."
    fi
}


run_joseki() {
    echo "== Starting Joseki ..."
    export JOSEKIROOT=$BSBM_ROOT_PATH/Joseki-3.4.3
    export JOSEKIROOT=$BSBM_ROOT_PATH/Joseki-3.4.3
    SEARCH=\"TDB\"
    REPLACE=\"$BSBM_ROOT_PATH/datasets/tdb-$BSBM_SCALE_FACTOR/TDB\"
    sed "s/${SEARCH}/$(echo $REPLACE | sed -e 's/\\/\\\\/g' -e 's/\//\\\//g' -e 's/&/\\\&/g')/g" $JOSEKIROOT/joseki-config-tdb.ttl > $JOSEKIROOT/joseki-config-tdb-bsbm-$BSBM_SCALE_FACTOR.ttl
    cd $JOSEKIROOT
    ./bin/rdfserver joseki-config-tdb-bsbm-$BSBM_SCALE_FACTOR.ttl &>> $BSBM_ROOT_PATH/results/$BSBM_SCALE_FACTOR-joseki-$1-$BSBM_CONCURRENT_CLIENTS.log &
#    ./bin/rdfserver joseki-config-tdb-bsbm-$BSBM_SCALE_FACTOR.ttl &>> /dev/null &
    sleep 4
    echo "== Done."
}


shutdown_joseki() {
    echo "== Shutting down Joseki ..."
    kill `ps -ef | grep Joseki | grep -v grep | awk '{print $2}'`
    sleep 1
    echo "== Done."
}


test_joseki() {
    shutdown_joseki

    if [ ! -f "$BSBM_ROOT_PATH/results/$BSBM_SCALE_FACTOR-joseki-explore-$BSBM_CONCURRENT_CLIENTS.txt" ]; then
        run_joseki "explore"
        free_os_caches
        run_bsbmtools "joseki" $JOSEKI_SPARQL_QUERY_URL $JOSEKI_SPARQL_UPDATE_URL "explore"
        shutdown_joseki
    else
        echo "==== [skipped] Running BSBM: sut=Joseki, scale=$BSBM_SCALE_FACTOR, clients=$BSBM_CONCURRENT_CLIENTS, usecase=explore ..."
    fi

#    if [ ! -f "$BSBM_ROOT_PATH/results/$BSBM_SCALE_FACTOR-joseki-update-$BSBM_CONCURRENT_CLIENTS.txt" ]; then
#        run_joseki "update"
#        free_os_caches
#        run_bsbmtools "joseki" $JOSEKI_SPARQL_QUERY_URL $JOSEKI_SPARQL_UPDATE_URL "update"
#        shutdown_joseki
#    else
#        echo "==== [skipped] Running BSBM: sut=Joseki, scale=$BSBM_SCALE_FACTOR, clients=$BSBM_CONCURRENT_CLIENTS, usecase=update ..."
#    fi

    if [ ! -f "$BSBM_ROOT_PATH/results/$BSBM_SCALE_FACTOR-joseki-bi-$BSBM_CONCURRENT_CLIENTS.txt" ]; then
        run_joseki "bi"
        free_os_caches
        run_bsbmtools "joseki" $JOSEKI_SPARQL_QUERY_URL $JOSEKI_SPARQL_UPDATE_URL "bi"
        shutdown_joseki
    else
        echo "==== [skipped] Running BSBM: sut=Joseki, scale=$BSBM_SCALE_FACTOR, clients=$BSBM_CONCURRENT_CLIENTS, usecase=bi ..."
    fi






}

