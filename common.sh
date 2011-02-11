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


if [ ! -d "$BSBM_ROOT_PATH" ]; then
    mkdir $BSBM_ROOT_PATH
fi

if [ ! -d "$BSBM_ROOT_PATH/results" ]; then
    mkdir $BSBM_ROOT_PATH/results
fi


free_os_caches() {
    echo "==== Freeing OS caches..."
    sync
    sudo bash -c "echo 3 > /proc/sys/vm/drop_caches"
    echo "== Done."
}
