#!/bin/bash
#################################################################
#                                                               #
# Copyright (c) 2021 YottaDB LLC and/or its subsidiaries.       #
# All rights reserved.                                          #
#                                                               #
#   This source code contains the intellectual property         #
#   of its copyright holder(s), and is made available           #
#   under a license.  If you do not know the terms of           #
#   the license, please stop and do not read further.           #
#                                                               #
#################################################################
apt-get install -y build-essential cmake nodejs npm
npm install
./node_modules/@quasar/app/bin/quasar build
rm -rf cmake-build
mkdir cmake-build
cd cmake-build
export ydb_dist=$(pkg-config --variable=prefix yottadb)
cmake ../
make && make install