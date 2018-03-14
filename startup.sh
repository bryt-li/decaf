#!/bin/bash

cp -f xxl-conf-admin.properties xxl-conf/xxl-conf-admin/src/main/resources/xxl-conf-admin.properties

cd xxl-conf
mvn clean
mvn package
cd ..

rm -rf webapps
mkdir webapps
cp xxl-conf/xxl-conf-admin/target/xxl-conf-admin-1.4.1-SNAPSHOT.war webapps/ROOT.war
mkdir conf-mysql-db

docker-compose up
