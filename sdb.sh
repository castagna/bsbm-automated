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


SDB_SPARQL_QUERY_URL="http://127.0.0.1:2020/sparql"
SDB_SPARQL_UPDATE_URL="http://127.0.0.1:2020/update/service"


setup_sdb() {
    if [ ! -d "$BSBM_ROOT_PATH/sdb" ]; then
        echo "==== Checking-out and compiling SDB source code ..."
        echo "== Start: $(date +"%Y-%m-%d %H:%M:%S")"
        cd $BSBM_ROOT_PATH
        svn co https://svn.apache.org/repos/asf/incubator/jena/Jena2/SDB/trunk sdb
        cd $BSBM_ROOT_PATH/sdb
        mvn package
        echo "== Finish: $(date +"%Y-%m-%d %H:%M:%S")"
    else
        echo "==== [skipped] Checking-out and compiling SDB source code ..."
    fi
}


load_sdb() {
        echo "==== Loading data in SDB: scale=$BSBM_SCALE_FACTOR ..."
        echo "== Start: $(date +"%Y-%m-%d %H:%M:%S")"
        free_os_caches
        export SDBROOT="$BSBM_ROOT_PATH/sdb"
        export SDB_JDBC="/usr/share/java/postgresql-jdbc3.jar"
        export SDB_USER="bsbmuser"
        export SDB_PASSWORD="bsbmpass"
        cd $BSBM_ROOT_PATH/sdb
        cp $ROOT_PATH/sdb.ttl $BSBM_ROOT_PATH/sdb/
        sudo su postgres -c "psql -c \"CREATE ROLE bsbmuser PASSWORD 'bsbmpass' SUPERUSER CREATEDB CREATEROLE INHERIT LOGIN;\""
        sudo su postgres -c "psql -c \"CREATE DATABASE \"SDB\" WITH OWNER = \"bsbmuser\" ENCODING = 'UTF8' TABLESPACE = pg_default;\""
        sudo su postgres -c "psql -c \"GRANT ALL PRIVILEGES ON DATABASE SDB to bsbmuser;\""
        # edit /etc/postgres/8.2/main/pg_hba.conf and change:
        # - localhost   all   all   ident sameuser
        # + localhost   all   all   md5
        if [ ! -d "$BSBM_ROOT_PATH/results" ]; then
            mkdir $BSBM_ROOT_PATH/results
        fi
        ./bin2/sdbconfig --sdb=sdb.ttl --format
        ./bin2/sdbload --sdb=sdb.ttl --time $BSBM_ROOT_PATH/datasets/bsbm-dataset-$BSBM_SCALE_FACTOR/dataset.nt > $BSBM_ROOT_PATH/results/sdb-$BSBM_SCALE_FACTOR-sdbload.txt
        ./bin2/sdbconfig --sdb=sdb.ttl --index >> $BSBM_ROOT_PATH/results/sdb-$BSBM_SCALE_FACTOR-sdbload.txt
        sudo su postgres -c "psql --dbname sdb -c \"ANALYZE;\""
        echo "== Finish: $(date +"%Y-%m-%d %H:%M:%S")"
}


run_sdb() {
    echo "== Starting Joseki with SDB ..."
    export JOSEKIROOT=$BSBM_ROOT_PATH/Joseki-3.4.3
    export SDBROOT="$BSBM_ROOT_PATH/sdb"
    export SDB_JDBC="/usr/share/java/postgresql-jdbc3.jar"
    export SDB_USER="bsbmuser"
    export SDB_PASSWORD="bsbmpass"
    cp $ROOT_PATH/joseki-config-sdb.ttl $JOSEKIROOT
    cd $JOSEKIROOT
    ./bin/rdfserver joseki-config-sdb.ttl &>> $BSBM_ROOT_PATH/results/$BSBM_SCALE_FACTOR-joseki-sdb-$1-$BSBM_CONCURRENT_CLIENTS.log &
    sleep 4
    echo "== Done."
}


shutdown_sdb() {
    echo "== Shutting down Joseki with SDB ..."
    kill `ps -ef | grep Joseki | grep -v grep | awk '{print $2}'`
    sleep 1
    echo "== Done."
}


test_sdb() {
    shutdown_sdb

    if [ ! -f "$BSBM_ROOT_PATH/results/$BSBM_SCALE_FACTOR-sdb-explore-$BSBM_CONCURRENT_CLIENTS.txt" ]; then
        load_sdb
        run_sdb "explore"
        free_os_caches
        run_bsbmtools "sdb" $SDB_SPARQL_QUERY_URL $SDB_SPARQL_UPDATE_URL "explore"
        shutdown_sdb
    else
        echo "==== [skipped] Running BSBM: sut=sdb, scale=$BSBM_SCALE_FACTOR, clients=$BSBM_CONCURRENT_CLIENTS, usecase=explore ..."
    fi

#    if [ ! -f "$BSBM_ROOT_PATH/results/$BSBM_SCALE_FACTOR-sdb-update-$BSBM_CONCURRENT_CLIENTS.txt" ]; then
#        load_sdb
#        run_sdb "update"
#        free_os_caches
#        run_bsbmtools "sdb" $SDB_SPARQL_QUERY_URL $SDB_SPARQL_UPDATE_URL "update"
#        shutdown_sdb
#    else
#        echo "==== [skipped] Running BSBM: sut=sdb, scale=$BSBM_SCALE_FACTOR, clients=$BSBM_CONCURRENT_CLIENTS, usecase=update ..."
#    fi

    if [ ! -f "$BSBM_ROOT_PATH/results/$BSBM_SCALE_FACTOR-sdb-bi-$BSBM_CONCURRENT_CLIENTS.txt" ]; then
        load_sdb
        run_sdb "bi"
        free_os_caches
        run_bsbmtools "sdb" $SDB_SPARQL_QUERY_URL $SDB_SPARQL_UPDATE_URL "bi"
        shutdown_sdb
    else
        echo "==== [skipped] Running BSBM: sut=sdb, scale=$BSBM_SCALE_FACTOR, clients=$BSBM_CONCURRENT_CLIENTS, usecase=bi ..."
    fi
}


