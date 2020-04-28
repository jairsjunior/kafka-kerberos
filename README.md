# Kafka using SASL_PLAINTEXT with Kerberos

## Getting Started

1. Run only the kerberos container using the command
```
docker-compose up -d kerberos
```

2. After the container is running and the files `kafka_broker.keytab` and `kafka_client1.keytab` are created under the *kerberos-keytabs* folder

3. Run the docker-compose file to create all another containers:
```
docker-compose up -d
```

4. Services and Ports:

    - Zookeeper: 
        - localhost:2181 or zookeeper:2181
    - Schema-registry:
        - http://localhost:8081
    - Kafka-UI:
        - http://localhost:9000
    - Kafka Broker:
        * With Kerberos
            - localhost:9093 or broker:9093
        * Without Kerberos
            - localhost:29092 or broker:29092

5. To test if everything is working you can produce and consume using this commands inside of zookeeper container.
    * Entering the container
    ```
        docker exec -it zookeeper bash
    ```
    * Produce some messages
    ```
        kafka-console-producer --broker-list SASL_PLAINTEXT://broker.kafka-kerberos_default:9093 --topic test-sasl --producer.config /tmp/producer.properties
    ```
    * Consume all messages
    ```
        kafka-console-consumer --bootstrap-server SASL_PLAINTEXT://broker.kafka-kerberos_default:9093 --topic test-sasl --consumer.config /tmp/consumer.properties --from-beginning
    ```

## TO DO

- [ ] Persistent volume for kerberos container

- [ ] Include rest-proxy using kerberos at docker-compose.yml