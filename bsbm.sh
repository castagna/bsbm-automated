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
#BSBM_SCALE_FACTOR=14092
BSBM_SCALE_FACTOR=4000
BSBM_NUM_QUERY_MIXES=128
BSBM_NUM_QUERY_WARM_UP=32
BSBM_CONCURRENT_CLIENTS=4
BSBM_SEED=1212123
BSBM_QUERY_TIMEOUT=30000

TDB_LOADER=tdbloader2


free_os_caches() {
    echo "Freeing OS caches..."
    sync
    sudo bash -c "echo 3 > /proc/sys/vm/drop_caches"
    echo "done."
}


if [ ! -d "$BSBM_ROOT_PATH" ]; then
    mkdir $BSBM_ROOT_PATH
fi


if [ ! -d "$BSBM_ROOT_PATH/bsbmtools" ]; then
    echo "Downloading and compiling Berlin SPARQL Benchmark (BSBM)..."
    cd $BSBM_ROOT_PATH
    svn co https://bsbmtools.svn.sourceforge.net/svnroot/bsbmtools/trunk bsbmtools
    cd $BSBM_ROOT_PATH/bsbmtools
    ant jar
    echo "done."
fi


if [ ! -d "$BSBM_ROOT_PATH/datasets/bsbm-dataset-$BSBM_SCALE_FACTOR" ]; then
    echo "Generating dataset (scale factor is $BSBM_SCALE_FACTOR)..."
    cd $BSBM_ROOT_PATH/bsbmtools
    java -cp "lib/*" benchmark.generator.Generator -fc -ud -pc $BSBM_SCALE_FACTOR -s nt
    if [ ! -d "$BSBM_ROOT_PATH/datasets" ]; then
        mkdir $BSBM_ROOT_PATH/datasets
    fi
    mkdir $BSBM_ROOT_PATH/datasets/bsbm-dataset-$BSBM_SCALE_FACTOR
    mv $BSBM_ROOT_PATH/bsbmtools/dataset* $BSBM_ROOT_PATH/datasets/bsbm-dataset-$BSBM_SCALE_FACTOR
    echo "done."
fi


if [ ! -d "$BSBM_ROOT_PATH/tdb" ]; then
    echo "Downloading and compiling TDB..."
    cd $BSBM_ROOT_PATH
    svn co https://jena.svn.sourceforge.net/svnroot/jena/TDB/trunk/ tdb
    cd $BSBM_ROOT_PATH/tdb
    mvn package
    echo "done."
fi


if [ ! -d "$BSBM_ROOT_PATH/Joseki-3.4.3" ]; then
    echo "Downloading Joseki..."
    cd $BSBM_ROOT_PATH
    wget https://downloads.sourceforge.net/project/joseki/Joseki-SPARQL/Joseki-3.4.3/joseki-3.4.3.zip
    unzip joseki-3.4.3.zip
    rm joseki-3.4.3.zip
    chmod 744 $BSBM_ROOT_PATH/Joseki-3.4.3/bin/rdfserver
    echo "done."
fi


if [ ! -d "$BSBM_ROOT_PATH/fuseki" ]; then
    echo "Downloading and compiling Fuseki..."
    cd $BSBM_ROOT_PATH
    svn co http://jena.svn.sourceforge.net/svnroot/jena/Fuseki/trunk fuseki
    cd $BSBM_ROOT_PATH/fuseki
    mvn package
    echo "done."
fi


##
#   Sesame2 + Tomcat
##

if [ ! -d "$BSBM_ROOT_PATH/apache-tomcat-7.0.8" ]; then
    echo "Downloading Tomcat..."
    cd $BSBM_ROOT_PATH
    wget http://archive.apache.org/dist/tomcat/tomcat-7/v7.0.8/bin/apache-tomcat-7.0.8.tar.gz
    tar xvfz apache-tomcat-7.0.8.tar.gz
    rm apache-tomcat-7.0.8.tar.gz
    echo "done."
fi


if [ ! -d "$BSBM_ROOT_PATH/openrdf-sesame-2.3.2" ]; then
    echo "Downloading Sesame2..."
    cd $BSBM_ROOT_PATH
    wget https://downloads.sourceforge.net/project/sesame/Sesame%202/2.3.2/openrdf-sesame-2.3.2-sdk.tar.gz
    tar xvfz openrdf-sesame-2.3.2-sdk.tar.gz
    rm openrdf-sesame-2.3.2-sdk.tar.gz
    echo "done."

    cp $BSBM_ROOT_PATH/openrdf-sesame-2.3.2/war/*.war $BSBM_ROOT_PATH/apache-tomcat-7.0.8/webapps 
    cd $BSBM_ROOT_PATH/apache-tomcat-7.0.8/webapps
    jar xvf openrdf-sesame.war
    jar xvf openrdf-workbench.war
fi



if [ ! -d "$BSBM_ROOT_PATH/datasets/tdb-$BSBM_SCALE_FACTOR" ]; then
    echo "Loading dataset in TDB..."
    free_os_caches
    export TDBROOT=$BSBM_ROOT_PATH/tdb
    export PATH=$PATH:$BSBM_ROOT_PATH/tdb/bin2
    mkdir $BSBM_ROOT_PATH/datasets/tdb-$BSBM_SCALE_FACTOR
    if [ ! -d "$BSBM_ROOT_PATH/results" ]; then
        mkdir $BSBM_ROOT_PATH/results
    fi
    $TDB_LOADER -v --loc=$BSBM_ROOT_PATH/datasets/tdb-$BSBM_SCALE_FACTOR/TDB $BSBM_ROOT_PATH/datasets/bsbm-dataset-$BSBM_SCALE_FACTOR/dataset.nt > $BSBM_ROOT_PATH/results/bsbm-results-$BSBM_SCALE_FACTOR-tdbload.txt
    tdbstats --loc $BSBM_ROOT_PATH/datasets/tdb-$BSBM_SCALE_FACTOR/TDB > $BSBM_ROOT_PATH/datasets/tdb-$BSBM_SCALE_FACTOR/TDB/stats.opt
    echo "done."
fi


run_fuseki() {
    echo "Running Fuseki..."
    kill `ps -ef | grep fuseki | grep -v grep | awk '{print $2}'`
    java -jar $BSBM_ROOT_PATH/fuseki/target/fuseki-0.2.0-SNAPSHOT-sys.jar --update --loc=$BSBM_ROOT_PATH/datasets/tdb-$BSBM_SCALE_FACTOR/TDB /bsbm &>> /dev/null & # $BSBM_ROOT_PATH/results/fuseki.log &
    sleep 4
    echo "done."
}


if [ ! -f "$BSBM_ROOT_PATH/results/bsbm-results-$BSBM_SCALE_FACTOR-fuseki.txt" ]; then
    run_fuseki
    free_os_caches
    echo "Running BSBM benchmark (scale factor is $BSBM_SCALE_FACTOR) against Fuseki..."
    if [ ! -d "$BSBM_ROOT_PATH/results" ]; then
        mkdir $BSBM_ROOT_PATH/results
    fi
    cd $BSBM_ROOT_PATH/bsbmtools
    java -cp "lib/*" benchmark.testdriver.TestDriver -runs $BSBM_NUM_QUERY_MIXES -w $BSBM_NUM_QUERY_WARM_UP -mt $BSBM_CONCURRENT_CLIENTS -t $BSBM_QUERY_TIMEOUT -seed $BSBM_SEED http://127.0.0.1:3030/bsbm/query > $BSBM_ROOT_PATH/results/bsbm-results-$BSBM_SCALE_FACTOR-fuseki.txt
    kill `ps -ef | grep fuseki | grep -v grep | awk '{print $2}'`
    echo "done."
fi


if [ ! -f "$BSBM_ROOT_PATH/results/bsbm-results-$BSBM_SCALE_FACTOR-fuseki-update.txt" ]; then
    run_fuseki
    free_os_caches
    echo "Running BSBM benchmark (scale factor is $BSBM_SCALE_FACTOR) with update against Fuseki..."
    if [ ! -d "$BSBM_ROOT_PATH/results" ]; then
        mkdir $BSBM_ROOT_PATH/results
    fi
    cd $BSBM_ROOT_PATH/bsbmtools
    java -cp "lib/*" -Xmx256M benchmark.testdriver.TestDriver -runs $BSBM_NUM_QUERY_MIXES -w $BSBM_NUM_QUERY_WARM_UP -mt $BSBM_CONCURRENT_CLIENTS -t $BSBM_QUERY_TIMEOUT -ucf usecases/explore/sparql.txt -seed $BSBM_SEED -u http://127.0.0.1:3030/bsbm/update -udataset $BSBM_ROOT_PATH/datasets/bsbm-dataset-$BSBM_SCALE_FACTOR/dataset_update.nt http://127.0.0.1:3030/bsbm/query > $BSBM_ROOT_PATH/results/bsbm-results-$BSBM_SCALE_FACTOR-fuseki-update.txt
    kill `ps -ef | grep fuseki | grep -v grep | awk '{print $2}'`
    echo "done."
fi


if [ ! -f "$BSBM_ROOT_PATH/results/bsbm-results-$BSBM_SCALE_FACTOR-fuseki-bi.txt" ]; then
    run_fuseki
    free_os_caches
    echo "Running BSBM benchmark (scale factor is $BSBM_SCALE_FACTOR) with BI against Fuseki..."
    if [ ! -d "$BSBM_ROOT_PATH/results" ]; then
        mkdir $BSBM_ROOT_PATH/results
    fi
    cd $BSBM_ROOT_PATH/bsbmtools
    java -cp "lib/*" -Xmx256M benchmark.testdriver.TestDriver -runs $BSBM_NUM_QUERY_MIXES -w $BSBM_NUM_QUERY_WARM_UP -mt $BSBM_CONCURRENT_CLIENTS -t $BSBM_QUERY_TIMEOUT -ucf usecases/businessIntelligence/sparql.txt -seed $BSBM_SEED -u http://127.0.0.1:3030/bsbm/update -udataset $BSBM_ROOT_PATH/datasets/bsbm-dataset-$BSBM_SCALE_FACTOR/dataset_update.nt http://127.0.0.1:3030/bsbm/query > $BSBM_ROOT_PATH/results/bsbm-results-$BSBM_SCALE_FACTOR-fuseki-bi.txt
    kill `ps -ef | grep fuseki | grep -v grep | awk '{print $2}'`
    echo "done."
fi


run_joseki() {
    echo "Running Joseki..."
    export JOSEKIROOT=$BSBM_ROOT_PATH/Joseki-3.4.3
    kill `ps -ef | grep Joseki | grep -v grep | awk '{print $2}'`
    export JOSEKIROOT=$BSBM_ROOT_PATH/Joseki-3.4.3
    SEARCH=\"TDB\"
    REPLACE=\"$BSBM_ROOT_PATH/datasets/tdb-$BSBM_SCALE_FACTOR/TDB\"
    sed "s/${SEARCH}/$(echo $REPLACE | sed -e 's/\\/\\\\/g' -e 's/\//\\\//g' -e 's/&/\\\&/g')/g" $JOSEKIROOT/joseki-config-tdb.ttl > $JOSEKIROOT/joseki-config-tdb-bsbm-$BSBM_SCALE_FACTOR.ttl
    cd $JOSEKIROOT
    ./bin/rdfserver joseki-config-tdb-bsbm-$BSBM_SCALE_FACTOR.ttl &>> $BSBM_ROOT_PATH/results/joseki.log & # /dev/null &
    sleep 4
    echo "done."
}


if [ ! -f "$BSBM_ROOT_PATH/results/bsbm-results-$BSBM_SCALE_FACTOR-joseki.txt" ] ; then
    run_joseki
    free_os_caches
    echo "Running BSBM benchmark (scale factor is $BSBM_SCALE_FACTOR) against Joseki..."
    if [ ! -d "$BSBM_ROOT_PATH/results" ]; then
        mkdir $BSBM_ROOT_PATH/results
    fi
    cd $BSBM_ROOT_PATH/bsbmtools
    java -cp "lib/*" benchmark.testdriver.TestDriver -runs $BSBM_NUM_QUERY_MIXES -w $BSBM_NUM_QUERY_WARM_UP -mt $BSBM_CONCURRENT_CLIENTS -t $BSBM_QUERY_TIMEOUT -seed $BSBM_SEED http://127.0.0.1:2020/sparql > $BSBM_ROOT_PATH/results/bsbm-results-$BSBM_SCALE_FACTOR-joseki.txt
    kill `ps -ef | grep Joseki | grep -v grep | awk '{print $2}'`
    echo "done."
fi


if [ ! -f "$BSBM_ROOT_PATH/results/bsbm-results-$BSBM_SCALE_FACTOR-joseki-update.txt" ] ; then
    run_joseki
    free_os_caches
    echo "Running BSBM benchmark (scale factor is $BSBM_SCALE_FACTOR) with update against Joseki..."
    if [ ! -d "$BSBM_ROOT_PATH/results" ]; then
        mkdir $BSBM_ROOT_PATH/results
    fi
    cd $BSBM_ROOT_PATH/bsbmtools
    java -cp "lib/*" -Xmx256M benchmark.testdriver.TestDriver -runs $BSBM_NUM_QUERY_MIXES -w $BSBM_NUM_QUERY_WARM_UP -mt $BSBM_CONCURRENT_CLIENTS -t $BSBM_QUERY_TIMEOUT -ucf usecases/explore/sparql.txt -seed $BSBM_SEED -u http://127.0.0.1:2020/update/service -udataset $BSBM_ROOT_PATH/datasets/bsbm-dataset-$BSBM_SCALE_FACTOR/dataset_update.nt http://127.0.0.1:2020/sparql > $BSBM_ROOT_PATH/results/bsbm-results-$BSBM_SCALE_FACTOR-joseki-update.txt
    kill `ps -ef | grep Joseki | grep -v grep | awk '{print $2}'`
    echo "done."
fi


if [ ! -f "$BSBM_ROOT_PATH/results/bsbm-results-$BSBM_SCALE_FACTOR-joseki-bi.txt" ] ; then
    run_joseki
    free_os_caches
    echo "Running BSBM benchmark (scale factor is $BSBM_SCALE_FACTOR) with BI against Joseki..."
    if [ ! -d "$BSBM_ROOT_PATH/results" ]; then
        mkdir $BSBM_ROOT_PATH/results
    fi
    cd $BSBM_ROOT_PATH/bsbmtools
    java -cp "lib/*" -Xmx256M benchmark.testdriver.TestDriver -runs $BSBM_NUM_QUERY_MIXES -w $BSBM_NUM_QUERY_WARM_UP -mt $BSBM_CONCURRENT_CLIENTS -t $BSBM_QUERY_TIMEOUT -ucf usecases/businessIntelligence/sparql.txt -seed $BSBM_SEED -u http://127.0.0.1:2020/update/service -udataset $BSBM_ROOT_PATH/datasets/bsbm-dataset-$BSBM_SCALE_FACTOR/dataset_update.nt http://127.0.0.1:2020/sparql > $BSBM_ROOT_PATH/results/bsbm-results-$BSBM_SCALE_FACTOR-joseki-bi.txt
    kill `ps -ef | grep Joseki | grep -v grep | awk '{print $2}'`
    echo "done."
fi


run_sesame2() {
    echo "Running Sesame2 with Tomcat..."
    cd $BSBM_ROOT_PATH
    kill `ps -ef | grep tomcat | grep -v grep | awk '{print $2}'`
    sleep 4
    ./apache-tomcat-7.0.8/bin/startup.sh
    sleep 6
    echo "done."

}


if [ ! -d "$HOME/.aduna/openrdf-sesame/repositories/bsbm-$BSBM_SCALE_FACTOR" ] ; then
    run_sesame2
    echo "Loading data into Sesame2..."
    cd $BSBM_ROOT_PATH
    cp $ROOT_PATH/sesame2.script $BSBM_ROOT_PATH/openrdf-sesame-2.3.2/
    sed -i "s/@@BSBM_SCALE_FACTOR@@/$BSBM_SCALE_FACTOR/g" $BSBM_ROOT_PATH/openrdf-sesame-2.3.2/sesame2.script
    time ./openrdf-sesame-2.3.2/bin/console.sh < $BSBM_ROOT_PATH/openrdf-sesame-2.3.2/sesame2.script &>> $BSBM_ROOT_PATH/results/bsbm-results-$BSBM_SCALE_FACTOR-sesame2-load.txt
    echo "done."
fi


if [ ! -f "$BSBM_ROOT_PATH/results/bsbm-results-$BSBM_SCALE_FACTOR-sesame2.txt" ] ; then
##    run_sesame2
    free_os_caches
    echo "Running BSBM benchmark (scale factor is $BSBM_SCALE_FACTOR) against Sesame2 with Tomcat..."
    if [ ! -d "$BSBM_ROOT_PATH/results" ]; then
        mkdir $BSBM_ROOT_PATH/results
    fi
    cd $BSBM_ROOT_PATH/bsbmtools
    java -cp "lib/*" benchmark.testdriver.TestDriver -runs $BSBM_NUM_QUERY_MIXES -w $BSBM_NUM_QUERY_WARM_UP -mt $BSBM_CONCURRENT_CLIENTS -t $BSBM_QUERY_TIMEOUT -seed $BSBM_SEED http://127.0.0.1:8080/openrdf-workbench/repositories/bsbm-2000/query > $BSBM_ROOT_PATH/results/bsbm-results-$BSBM_SCALE_FACTOR-sesame2.txt
    kill `ps -ef | grep tomcat | grep -v grep | awk '{print $2}'`
    echo "done."
fi

