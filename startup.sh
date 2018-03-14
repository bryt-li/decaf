#!/bin/bash

mkdir conf-mysql-db
mkdir webapps

cp -f xxl-conf-admin.properties xxl-conf/xxl-conf-admin/src/main/resources/xxl-conf-admin.properties

cd xxl-conf
mvn clean
mvn package

cd ..
cp xxl-conf/xxl-conf-admin/target/xxl-conf-admin-1.4.1-SNAPSHOT.war webapps/ROOT.war

docker-compose up
