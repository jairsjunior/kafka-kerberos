#!/bin/bash

[[ "TRACE" ]] && set -x

: ${REALM:=NODE.DC1.CONSUL}
: ${DOMAIN_REALM:=node.dc1.consul}
: ${KERB_MASTER_KEY:=masterkey}
: ${KERB_ADMIN_USER:=admin}
: ${KERB_ADMIN_PASS:=admin}
: ${SEARCH_DOMAINS:=search.consul node.dc1.consul}

fix_nameserver() {
  cat>/etc/resolv.conf<<EOF
nameserver $NAMESERVER_IP
search $SEARCH_DOMAINS
EOF
}

fix_hostname() {
  sed -i "/^hosts:/ s/ *files dns/ dns files/" /etc/nsswitch.conf
}

create_config() {
  : ${KDC_ADDRESS:=$(hostname -f)}

  cat>/etc/krb5.conf<<EOF
[logging]
 default = FILE:/var/log/kerberos/krb5libs.log
 kdc = FILE:/var/log/kerberos/krb5kdc.log
 admin_server = FILE:/var/log/kerberos/kadmind.log
[libdefaults]
 default_realm = $REALM
 dns_lookup_realm = false
 dns_lookup_kdc = false
 ticket_lifetime = 24h
 renew_lifetime = 7d
 forwardable = true
[realms]
 $REALM = {
  kdc = $KDC_ADDRESS
  admin_server = $KDC_ADDRESS
 }
[domain_realm]
 .$DOMAIN_REALM = $REALM
 $DOMAIN_REALM = $REALM
EOF
}

create_kdc_config() {
  cat>/var/kerberos/krb5kdc/kdc.conf<<EOF
[kdcdefaults]
 kdc_ports = 88
 kdc_tcp_ports = 88

[realms]
 $REALM = {
  #master_key_type = aes256-cts
  database_name = /volumes/kerberos/principal
  acl_file = /volumes/kerberos/kadm5.acl
  dict_file = /volumes/kerberos/kadm5.dict
  admin_keytab = /volumes/kerberos/kadm5.keytab
  key_stash_file = /volumes/kerberos/.k5.$REALM
  supported_enctypes = aes256-cts:normal aes128-cts:normal des3-hmac-sha1:normal arcfour-hmac:normal des-hmac-sha1:normal des-cbc-md5:normal des-cbc-crc:normal
 }
EOF
}

create_db() {
  /usr/sbin/kdb5_util -P $KERB_MASTER_KEY -r $REALM create -s
}

start_kdc() {
  mkdir -p /var/log/kerberos

  /etc/rc.d/init.d/krb5kdc start
  /etc/rc.d/init.d/kadmin start

  chkconfig krb5kdc on
  chkconfig kadmin on
}

restart_kdc() {
  /etc/rc.d/init.d/krb5kdc restart
  /etc/rc.d/init.d/kadmin restart
}

create_admin_user() {
  kadmin.local -q "addprinc -pw $KERB_ADMIN_PASS $KERB_ADMIN_USER/admin"
  echo "*/admin@$REALM *" > /volumes/kerberos/kadm5.acl
}

create_users() {
  #Create broker keytab
  kadmin.local -q 'addprinc -pw broker123456 kafka/broker.kafka-kerberos_default@KERBEROS.KAFKA-KERBEROS_DEFAULT'
  kadmin.local -q "ktadd -k /volumes/keytabs/kafka_broker.keytab kafka/broker.kafka-kerberos_default@KERBEROS.KAFKA-KERBEROS_DEFAULT"

  #Create client keytab
  kadmin.local -q 'addprinc -pw zookeeper123456 kafka/zookeeper.kafka-kerberos_default@KERBEROS.KAFKA-KERBEROS_DEFAULT'
  kadmin.local -q "ktadd -k /volumes/keytabs/kafka_client1.keytab kafka/zookeeper.kafka-kerberos_default@KERBEROS.KAFKA-KERBEROS_DEFAULT"

  #Create Schema Registry keytab
  kadmin.local -q 'addprinc -pw schemaregistry123456 kafka/schema-registry.kafka-kerberos_default@KERBEROS.KAFKA-KERBEROS_DEFAULT'
  kadmin.local -q "ktadd -k /volumes/keytabs/kafka_schema-registry.keytab kafka/schema-registry.kafka-kerberos_default@KERBEROS.KAFKA-KERBEROS_DEFAULT"

  #Create Rest Proxy keytab
  kadmin.local -q 'addprinc -pw restproxy123456 kafka/rest-proxy.kafka-kerberos_default@KERBEROS.KAFKA-KERBEROS_DEFAULT'
  kadmin.local -q "ktadd -k /volumes/keytabs/kafka_rest-proxy.keytab kafka/rest-proxy.kafka-kerberos_default@KERBEROS.KAFKA-KERBEROS_DEFAULT"
}

main() {
  fix_nameserver
  fix_hostname

  if [ ! -f /volumes/kerberos/kerberos_initialized ]; then
    create_kdc_config
    create_config
    create_db
    create_admin_user
    create_users
    start_kdc
    cp /etc/krb5.conf /volumes/kerberos/krb5.conf

    touch /volumes/kerberos/kerberos_initialized
  fi

  if [ ! -f /volumes/kerberos/principal ]; then
    while true; do sleep 1000; done
  else
    create_kdc_config
    create_config
    start_kdc
    tail -F /var/log/kerberos/krb5kdc.log
  fi
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"