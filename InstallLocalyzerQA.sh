#!/bin/bash
#
# Install the LocalyzerQA  Server.
#
# Author: Lili Ji
# Copyright (c) Lingoport 2022


echo
echo "Installing the LocalyzerQA Servers ..."
echo

#
# read in config file
#
if [[ -e "install.conf" ]]; then
    source install.conf
    echo "Reading configured information from install.conf file."
fi

#
# get database_root_password if not set
#
if [ -z "$(echo $database_root_password)" ]
then
    echo
    read -rp "Please enter the MySQL Root Password you want to create [Q/q to quit install]: " result
    if [[ "$result" == "Q"  || "$result" == "q" ]]
	then
	    echo
        echo "Exiting LocalyzerQA Server Install."
        exit 1;
    elif [[ "$result" == "" ]]
    then
        echo
        echo "Failed to provide the MySQL Root Password."
        echo "Exiting LocalyzerQA Server Install."
        exit 1;
    else
        database_root_password=$result
    fi
fi

#
# get serverURL if not set
#
if [ -z "$(echo $serverURL)" ]
then
    echo
    read -rp "Please enter server url [Q/q to quit install]: " result
    if [[ "$result" == "Q"  || "$result" == "q" ]]
	then
	    echo
        echo "Exiting LocalyzerQA Server Install."
        exit 1;
    elif [[ "$result" == "" ]]
    then
        echo
        echo "Failed to provide a Server URL."
        echo "Exiting LocalyzerQA Server Install."
        exit 1;
    else
        serverURL=$result
    fi
fi

#
# get docker_username if not set
#
if [ -z "$(echo $docker_username)" ]
then
    echo
    read -rp "Please enter Docker Hub username [Q/q to quit install]: " result
    if [[ "$result" == "Q"  || "$result" == "q" ]]
	then
	    echo
        echo "Exiting LocalyzerQA Server Install."
        exit 1;
    elif [[ "$result" == "" ]]
    then
        echo
        echo "Failed to provide a Docker Hub username."
        echo "Exiting LocalyzerQA Server Install."
        exit 1;
    else
        docker_username=$result
    fi
fi

#
# get docker_account_token if not set
#
if [ -z "$(echo $docker_account_token)" ]
then
    echo
    read -rp "Please enter Docker Hub account token [Q/q to quit install]: " result
    if [[ "$result" == "Q"  || "$result" == "q" ]]
	then
	    echo
        echo "Exiting LocalyzerQA Server Install."
        exit 1;
    elif [[ "$result" == "" ]]
    then
        echo
        echo "Failed to provide a Docker Hub account token."
        echo "Exiting LocalyzerQA Server Install."
        exit 1;
    else
        docker_account_token=$result
    fi
fi


mkdir -p $home_directory/lingoport || true
mkdir -p $home_directory/localyzerqa/config || true
cd $home_directory/localyzerqa/config

sudo docker network ls|grep $database_network > /dev/null || sudo docker network create $database_network

cc_mysql_id=$(sudo docker run --restart unless-stopped -d --name localyzerqaDatabase --network-alias mysqlserverlocalyzerqa --network $database_network -e MYSQL_ROOT_PASSWORD=$database_root_password -e MYSQL_DATABASE=localyzerqadb -v $home_directory/mysql/conf.d:/etc/mysql/conf.d  mysql:8.0 --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci)
sudo echo $cc_mysql_id > cc_mysql_id.txt

echo $docker_account_token | sudo docker login -u $docker_username --password-stdin

cc_container_id=`sudo docker run -dp $serverPort:8080 --restart unless-stopped --network-alias qaservernet --network $database_network  $docker_image:$localyzerqa_image_version`

echo "LocalyzerQA starting, container id is  $cc_container_id "
sudo echo $cc_container_id > cc_container_id.txt

sleep 20s
sudo docker exec  $cc_container_id bash -c "sed -i 's/mysecretpw/$database_root_password/g' /usr/local/tomcat/lingoport/LocalyzerQAConfig.groovy"
sudo docker exec  $cc_container_id bash -c "echo 'grails.serverURL = $serverURL' >> /usr/local/tomcat/lingoport/LocalyzerQAConfig.groovy"

sleep 20s
sudo docker restart  $cc_container_id
