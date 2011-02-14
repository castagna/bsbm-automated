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
#BSBM_SCALE_FACTOR=4000
#BSBM_CONCURRENT_CLIENTS=4
BSBM_NUM_QUERY_MIXES=128
BSBM_NUM_QUERY_WARM_UP=32
BSBM_SEED=1212123
BSBM_QUERY_TIMEOUT=60000

source common.sh
source bsbmtools.sh
source tdb.sh
source fuseki.sh
source joseki.sh
source sesame2.sh
# source bigowlim.sh

setup_bsbmtools
setup_tdb
setup_fuseki
setup_joseki
setup_sesame2
# setup_bigowlim # work in progress...


BSBM_SCALE_FACTOR_VALUES=( 1000 2000 )
BSBM_CONCURRENT_CLIENTS_VALUES=( 1 2 ) 


run_sesame2
for BSBM_SCALE_FACTOR in ${BSBM_SCALE_FACTOR_VALUES[@]} 
do
    generate_bsbmtools_dataset
    load_tdb
    load_sesame2
done
shutdown_sesame2


for BSBM_SCALE_FACTOR in ${BSBM_SCALE_FACTOR_VALUES[@]} 
do
    for BSBM_CONCURRENT_CLIENTS in ${BSBM_CONCURRENT_CLIENTS_VALUES[@]} 
    do
        test_fuseki
    done
done





















