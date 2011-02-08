#!/bin/bash

BSBM_ROOT_PATH=/tmp/bsbm
BSBM_SCALE_FACTOR=1000
BSBM_NUM_QUERY_MIXES=128
BSBM_NUM_QUERY_WARM_UP=32
BSBM_CONCURRENT_CLIENTS=1 # is there a bug in Fuseki?!
BSBM_QUERY_TIMEOUT=30000

TDB_LOADER=tdbloader

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


if [ ! -d "$BSBM_ROOT_PATH/datasets/tdb-$BSBM_SCALE_FACTOR" ]; then
	echo "Loading dataset in TDB..."
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
	java -jar $BSBM_ROOT_PATH/fuseki/target/fuseki-0.2.0-SNAPSHOT-sys.jar --update --loc=$BSBM_ROOT_PATH/datasets/tdb-$BSBM_SCALE_FACTOR/TDB /bsbm &> /dev/null &
	sleep 4
	echo "done."
}


if [ ! -f "$BSBM_ROOT_PATH/results/bsbm-results-$BSBM_SCALE_FACTOR-fuseki.txt" ]; then
	run_fuseki
	echo "Running BSBM benchmark (scale factor is $BSBM_SCALE_FACTOR) against Fuseki..."
    if [ ! -d "$BSBM_ROOT_PATH/results" ]; then
		mkdir $BSBM_ROOT_PATH/results
    fi
	cd $BSBM_ROOT_PATH/bsbmtools
	java -cp "lib/*" benchmark.testdriver.TestDriver -runs $BSBM_NUM_QUERY_MIXES -w $BSBM_NUM_QUERY_WARM_UP -mt $BSBM_CONCURRENT_CLIENTS -t $BSBM_QUERY_TIMEOUT http://127.0.0.1:3030/bsbm/query > $BSBM_ROOT_PATH/results/bsbm-results-$BSBM_SCALE_FACTOR-fuseki.txt
	kill `ps -ef | grep fuseki | grep -v grep | awk '{print $2}'`
	echo "done."
fi


if [ ! -f "$BSBM_ROOT_PATH/results/bsbm-results-$BSBM_SCALE_FACTOR-fuseki-update.txt" ]; then
	run_fuseki
	echo "Running BSBM benchmark (scale factor is $BSBM_SCALE_FACTOR) with update against Fuseki..."
    if [ ! -d "$BSBM_ROOT_PATH/results" ]; then
		mkdir $BSBM_ROOT_PATH/results
    fi
	cd $BSBM_ROOT_PATH/bsbmtools
	java -cp "lib/*" -Xmx256M benchmark.testdriver.TestDriver -runs $BSBM_NUM_QUERY_MIXES -w $BSBM_NUM_QUERY_WARM_UP -mt $BSBM_CONCURRENT_CLIENTS -t $BSBM_QUERY_TIMEOUT -ucf usecases/explore/sparql.txt -u http://127.0.0.1:3030/bsbm/update -udataset $BSBM_ROOT_PATH/datasets/bsbm-dataset-$BSBM_SCALE_FACTOR/dataset_update.nt http://127.0.0.1:3030/bsbm/query > $BSBM_ROOT_PATH/results/bsbm-results-$BSBM_SCALE_FACTOR-fuseki-update.txt
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
	./bin/rdfserver joseki-config-tdb-bsbm-$BSBM_SCALE_FACTOR.ttl &> /dev/null &
	sleep 4
	echo "done."
}


if [ ! -f "$BSBM_ROOT_PATH/results/bsbm-results-$BSBM_SCALE_FACTOR-joseki.txt" ] ; then
	run_joseki
	echo "Running BSBM benchmark (scale factor is $BSBM_SCALE_FACTOR) against Joseki..."
    if [ ! -d "$BSBM_ROOT_PATH/results" ]; then
		mkdir $BSBM_ROOT_PATH/results
    fi
	cd $BSBM_ROOT_PATH/bsbmtools
	java -cp "lib/*" benchmark.testdriver.TestDriver -runs $BSBM_NUM_QUERY_MIXES -w $BSBM_NUM_QUERY_WARM_UP -mt $BSBM_CONCURRENT_CLIENTS -t $BSBM_QUERY_TIMEOUT http://127.0.0.1:2020/sparql > $BSBM_ROOT_PATH/results/bsbm-results-$BSBM_SCALE_FACTOR-joseki.txt
	kill `ps -ef | grep Joseki | grep -v grep | awk '{print $2}'`
	echo "done."
fi


if [ ! -f "$BSBM_ROOT_PATH/results/bsbm-results-$BSBM_SCALE_FACTOR-joseki-update.txt" ] ; then
	run_joseki
	echo "Running BSBM benchmark (scale factor is $BSBM_SCALE_FACTOR) with update against Joseki..."
    if [ ! -d "$BSBM_ROOT_PATH/results" ]; then
		mkdir $BSBM_ROOT_PATH/results
    fi
	cd $BSBM_ROOT_PATH/bsbmtools
	java -cp "lib/*" -Xmx256M benchmark.testdriver.TestDriver -runs $BSBM_NUM_QUERY_MIXES -w $BSBM_NUM_QUERY_WARM_UP -mt $BSBM_CONCURRENT_CLIENTS -t $BSBM_QUERY_TIMEOUT -ucf usecases/explore/sparql.txt -u http://127.0.0.1:2020/update/service -udataset $BSBM_ROOT_PATH/datasets/bsbm-dataset-$BSBM_SCALE_FACTOR/dataset_update.nt http://127.0.0.1:2020/sparql > $BSBM_ROOT_PATH/results/bsbm-results-$BSBM_SCALE_FACTOR-joseki-update.txt
	kill `ps -ef | grep Joseki | grep -v grep | awk '{print $2}'`
	echo "done."
fi

