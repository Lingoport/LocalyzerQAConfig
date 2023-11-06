#!/bin/bash
#
# Install the LocalyzerQA Server.
#
# Author: Lili Ji
# Copyright (c) Lingoport 2022


echo
echo "Uninstalling the LocalyzerQA Servers ..."
echo

if [[ -e "install.conf" ]]; then
    source install.conf
    echo "Reading configured information from install.conf file."
fi

cd $home_directory/localyzerqa/config

oldID=`cat cc_container_id.txt`

sudo docker stop $oldID

sudo docker rm $oldID

db=`cat cc_mysql_id.txt`

sudo docker stop $db

sudo docker rm $db
