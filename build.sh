#!/bin/bash

mkdir conf-mysql-db

cp -f xxl-conf-admin.properties xxl-conf/xxl-conf-admin/src/main/resources/xxl-conf-admin.properties
cd xxl-conf

mvn clean
mvn package
mkdir xxl-conf-admin/target/webapps
cp xxl-conf-admin/target/xxl-conf-admin-1.4.1-SNAPSHOT.war xxl-conf-admin/target/webapps/ROOT.war

cd ..

docker-compose up
