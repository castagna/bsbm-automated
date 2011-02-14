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


BIGOWLIM_HOME="/opt/bigowlim"
SESAME2_HOME="$BSBM_ROOT_PATH/openrdf-sesame-2.3.2"
TOMCAT_HOME="$BSBM_ROOT_PATH/apache-tomcat-7.0.8"

setup_bigowlim() {

    if [ ! -d "$HOME/.aduna/openrdf-sesame-console/templates" ] ; then
        mkdir $HOME/.aduna/openrdf-sesame-console/templates
    fi

    if [ ! -f "$HOME/.aduna/openrdf-sesame-console/templates/bigowlim.ttl" ] ; then
        cp $BIGOWLIM_HOME/templates/bigowlim.ttl $HOME/.aduna/openrdf-sesame-console/templates/
    fi

    if [ ! -f "$SESAME2_HOME/lib/owlim-big-3.4.jar" ] ; then
        cp $BIGOWLIM_HOME/lib/owlim-big-3.4.jar $SESAME2_HOME/lib/
        cp $BIGOWLIM_HOME/lib/owlim-big-3.4.jar $TOMCAT_HOME/webapps/openrdf-sesame/WEB-INF/lib/
        cp $BIGOWLIM_HOME/lib/lucene-core-*.jar $TOMCAT_HOME/webapps/openrdf-sesame/WEB-INF/lib/
        cp $TOMCAT_HOME/webapps/openrdf-sesame/WEB-INF/lib/logback-* $TOMCAT_HOME/webapps/openrdf-workbench/WEB-INF/lib/
    fi 

}
