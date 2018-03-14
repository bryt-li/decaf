#!/bin/bash

cp -f xxl-conf-admin.properties xxl-conf/xxl-conf-admin/src/main/resources/xxl-conf-admin.properties

cd xxl-conf
mvn clean
mvn package
cd ..

rm -rf _webapps
mkdir _webapps
cp xxl-conf/xxl-conf-admin/target/xxl-conf-admin-1.4.1-SNAPSHOT.war _webapps/ROOT.war

mkdir _conf_data
mkdir _zoo_data
mkdir _zoo_data/data
mkdir _zoo_data/datalog

docker-compose up -d
