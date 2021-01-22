#!/bin/bash

docker-compose build
docker-compose up -d kerberos

while [ ! -f kerberos-keytabs/kafka_client1.keytab ]; 
do sleep 5;
done

sleep 5;

docker-compose down

sleep 5;

docker stack deploy -c docker-compose.yml kafka-kerberos