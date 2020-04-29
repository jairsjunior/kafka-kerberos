#!/bin/bash

docker-compose build
docker-compose up -d kerberos

while [ ! -f kerberos-keytabs/kafka_rest-proxy.keytab ]; 
do sleep 5;
done

sleep 5;

docker-compose up -d