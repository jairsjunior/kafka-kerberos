# Kafka using SASL_PLAINTEXT with Kerberos

## Getting Started

1. Start the services using the `start.sh` script. This script will build and start the kerberos server, create users and keytabs. When the keytabs files are created, start another services (Zookeeper, Kafka Broker, Kafka UI, Schema-Registry and Rest-Proxy).
```
bash start.sh
```

2. Services and Ports:
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

5. To test if everything is working you can use this 2 ways: 

### using rest proxy script
* Run the file `test-using-rest-proxy.sh` under the *tests* folder
```
./test-using-rest-proxy.sh
```

### produce and consume using this command-line inside of zookeeper container
- Entering the container:
```
docker exec -it zookeeper bash
```
- Produce some messages
```
kafka-console-producer --broker-list SASL_PLAINTEXT://broker.kafka-kerberos_default:9093 --topic test-sasl --producer.config /tmp/producer.properties
```
- Consume all messages
```
kafka-console-consumer --bootstrap-server SASL_PLAINTEXT://broker.kafka-kerberos_default:9093 --topic test-sasl --consumer.config /tmp/consumer.properties --from-beginning
```

## Kerberos Users

There are 2 types of user that can be created, using keytab or password. At this project the users of broker and zookeeper are using keytabs to login and at the schema-registry and rest-proxy we are using user/password.

### User with keytab

To create a new user with a keytab add a new line to the `kerberos-users/users.csv` file with this information

```
kafka,yourServiceHostname,keytabFilename
```

Sample Jaas conf file for Kafka Java Client

```
KafkaClient {
    com.sun.security.auth.module.Krb5LoginModule required
    useKeyTab=true
    storeKey=true
    keyTab="/tmp/kafka_client1.keytab"
    principal="kafka/zookeeper@KERBEROS";
};
```

### User with password

To create a new user with a keytab add a new line to the `kerberos-users/users.csv` file with this information

```
kafka,yourUserName,YourServiceName,yourPassword
```

**To use any of Kafka java clients with username and password you need to import the lib/krb5loginmodule-wrapper-0.0.1.jar at your project and use this configuration at your jaas conf file**

```
KafkaClient {
    br.com.jairsjunior.krb5loginmodule.Krb5AuthLoginModule required
    useFirstPass=true
    username="kafka/schema-registry"
    password="schema1234"
    principal="kafka/schema-registry@KERBEROS";
};
```