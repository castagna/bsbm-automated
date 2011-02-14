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


BIGOWLIM_SPARQL_QUERY_URL="http://127.0.0.1:8080/openrdf-workbench/repositories"
BIGOWLIM_SPARQL_UPDATE_URL="http://127.0.0.1:8080/openrdf-workbench/repositories" ## not used, since Sesame2 does not support SPARQL Update


SESAME2_HOME="$BSBM_ROOT_PATH/openrdf-sesame-2.3.2"
TOMCAT_HOME="$BSBM_ROOT_PATH/apache-tomcat-7.0.8"


setup_bigowlim() {
    if [ ! -f "$SESAME2_HOME/lib/owlim-big-3.4.jar" ] ; then
        echo "==== Setting up BigOWLIM ..."
        echo "== Start: $(date +"%Y-%m-%d %H:%M:%S")"
        if [ ! -d "$HOME/.aduna/openrdf-sesame-console/templates" ] ; then
            mkdir $HOME/.aduna/openrdf-sesame-console/templates
        fi

        if [ ! -f "$HOME/.aduna/openrdf-sesame-console/templates/bigowlim.ttl" ] ; then
            cp $BIGOWLIM_HOME/templates/bigowlim.ttl $HOME/.aduna/openrdf-sesame-console/templates/
        fi

        if [ ! -f "$SESAME2_HOME/lib/owlim-big-3.4.jar" ] ; then
            cp $BIGOWLIM_HOME/lib/owlim-big-3.4.jar $SESAME2_HOME/lib/
            cp $BIGOWLIM_HOME/lib/owlim-big-3.4.jar $TOMCAT_HOME/webapps/openrdf-sesame/WEB-INF/lib/
            cp $BIGOWLIM_HOME/ext/lucene-core-*.jar $TOMCAT_HOME/webapps/openrdf-sesame/WEB-INF/lib/
            cp $TOMCAT_HOME/webapps/openrdf-sesame/WEB-INF/lib/logback-* $TOMCAT_HOME/webapps/openrdf-workbench/WEB-INF/lib/
        fi 
        echo "== Finish: $(date +"%Y-%m-%d %H:%M:%S")"
    else 
        echo "==== [skipped] Setting up BigOWLIM ..."
    fi
}


run_bigowlim() {
    echo "== Starting Tomcat with Sesame2 + BigOWLIM ..."
    cd $BSBM_ROOT_PATH
    ./apache-tomcat-7.0.8/bin/startup.sh
    sleep 6
    echo "== Done."
}


load_bigowlim() {
    if [ ! -d "$HOME/.aduna/openrdf-sesame/repositories/bsbm-bigowlim-$BSBM_SCALE_FACTOR" ] ; then
        echo "==== Loading data with BigOWLIM: scale=$BSBM_SCALE_FACTOR ..."
        echo "== Start: $(date +"%Y-%m-%d %H:%M:%S")"
        cd $BSBM_ROOT_PATH
        cp $ROOT_PATH/bigowlim.script $BSBM_ROOT_PATH/openrdf-sesame-2.3.2/
        sed -i "s/@@BSBM_SCALE_FACTOR@@/$BSBM_SCALE_FACTOR/g" $BSBM_ROOT_PATH/openrdf-sesame-2.3.2/bigowlim.script
        SEARCH="@@BIGOWLIM_HOME@@"
        REPLACE=$BIGOWLIM_HOME
        sed -i "s/${SEARCH}/$(echo $REPLACE | sed -e 's/\\/\\\\/g' -e 's/\//\\\//g' -e 's/&/\\\&/g')/g" $BSBM_ROOT_PATH/openrdf-sesame-2.3.2/bigowlim.script
        time ./openrdf-sesame-2.3.2/bin/console.sh < $BSBM_ROOT_PATH/openrdf-sesame-2.3.2/bigowlim.script &>> $BSBM_ROOT_PATH/results/bigowlim-$BSBM_SCALE_FACTOR-load.txt
        rm $BSBM_ROOT_PATH/openrdf-sesame-2.3.2/bigowlim.script
        echo "== Finish: $(date +"%Y-%m-%d %H:%M:%S")"
    else
        echo "==== [skipped] Loading data with BigOWLIM: scale=$BSBM_SCALE_FACTOR ..."
    fi
}


shutdown_bigowlim() {
    echo "== Shutting down Sesame2 ..."
    kill `ps -ef | grep tomcat | grep -v grep | awk '{print $2}'`
    sleep 4 # Tomcat takes some time to shutdown
    echo "== Done."
}


test_bigowlim() {
    run_bigowlim
    free_os_caches
    run_bsbmtools "bigowlim" $BIGOWLIM_SPARQL_QUERY_URL/bsbm-bigowlim-$BSBM_SCALE_FACTOR/query $BIGOWLIM_SPARQL_UPDATE_URL/bsbm-bigowlim-$BSBM_SCALE_FACTOR/query "explore"
    shutdown_bigowlim
}
