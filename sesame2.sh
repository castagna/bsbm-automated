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


SESAME2_SPARQL_QUERY_URL="http://127.0.0.1:8080/openrdf-workbench/repositories/bsbm-2000/query"
SESAME2_SPARQL_UPDATE_URL="http://127.0.0.1:8080/openrdf-workbench/repositories/bsbm-2000/query" ## not used, since Sesame2 does not support SPARQL Update


setup_sesame2() {
    if [ ! -d "$BSBM_ROOT_PATH/apache-tomcat-7.0.8" ]; then
        echo "==== Downloading Apache Tomcat ..."
        echo "== Start: $(date +"%Y-%m-%d %H:%M:%S")"
        cd $BSBM_ROOT_PATH
        wget http://archive.apache.org/dist/tomcat/tomcat-7/v7.0.8/bin/apache-tomcat-7.0.8.tar.gz
        tar xvfz apache-tomcat-7.0.8.tar.gz
        rm apache-tomcat-7.0.8.tar.gz
        echo "== Finish: $(date +"%Y-%m-%d %H:%M:%S")"
    else
        echo "==== [skipped] Downloading Apache Tomcat ..."
    fi

    if [ ! -d "$BSBM_ROOT_PATH/openrdf-sesame-2.3.2" ]; then
        echo "==== Downloading and installing Sesame2 ..."
        echo "== Start: $(date +"%Y-%m-%d %H:%M:%S")"
        cd $BSBM_ROOT_PATH
        wget https://downloads.sourceforge.net/project/sesame/Sesame%202/2.3.2/openrdf-sesame-2.3.2-sdk.tar.gz
        tar xvfz openrdf-sesame-2.3.2-sdk.tar.gz
        rm openrdf-sesame-2.3.2-sdk.tar.gz
        cp $BSBM_ROOT_PATH/openrdf-sesame-2.3.2/war/*.war $BSBM_ROOT_PATH/apache-tomcat-7.0.8/webapps 
        cd $BSBM_ROOT_PATH/apache-tomcat-7.0.8/webapps
        jar xvf openrdf-sesame.war
        jar xvf openrdf-workbench.war
        rm openrdf-sesame.war
        rm openrdf-workbench.war
        echo "== Finish: $(date +"%Y-%m-%d %H:%M:%S")"
    else
        echo "==== [skipped] Downloading and installing Sesame2 ..."
    fi
}


run_sesame2() {
    echo "==== Starting Tomcat with Sesame2 ..."
    cd $BSBM_ROOT_PATH
    ./apache-tomcat-7.0.8/bin/startup.sh
    sleep 6
    echo "==== Done."
}


load_sesame2() {
    if [ ! -d "$HOME/.aduna/openrdf-sesame/repositories/bsbm-$BSBM_SCALE_FACTOR" ] ; then
        echo "==== Loading data in Sesame2: scale=$BSBM_SCALE_FACTOR ..."
        echo "== Start: $(date +"%Y-%m-%d %H:%M:%S")"
        cd $BSBM_ROOT_PATH
        cp $ROOT_PATH/sesame2.script $BSBM_ROOT_PATH/openrdf-sesame-2.3.2/
        sed -i "s/@@BSBM_SCALE_FACTOR@@/$BSBM_SCALE_FACTOR/g" $BSBM_ROOT_PATH/openrdf-sesame-2.3.2/sesame2.script
        time ./openrdf-sesame-2.3.2/bin/console.sh < $BSBM_ROOT_PATH/openrdf-sesame-2.3.2/sesame2.script &>> $BSBM_ROOT_PATH/results/sesame2-$BSBM_SCALE_FACTOR-load.txt
        rm $BSBM_ROOT_PATH/openrdf-sesame-2.3.2/sesame2.script
        echo "== Finish: $(date +"%Y-%m-%d %H:%M:%S")"
    else
        echo "==== [skipped] Loading data in Sesame2: scale=$BSBM_SCALE_FACTOR ..."
    fi
}


shutdown_sesame2() {
    echo "==== Shutting down Sesame2 ..."
    kill `ps -ef | grep tomcat | grep -v grep | awk '{print $2}'`
    sleep 4 # Tomcat takes some time to shutdown
    echo "==== Done."
}


test_sesame2() {
    run_sesame2
    free_os_caches
    run_bsbmtools "sesame2" $SESAME2_SPARQL_QUERY_URL $SESAME2_SPARQL_UPDATE_URL "explore"
    shutdown_sesame2
}

