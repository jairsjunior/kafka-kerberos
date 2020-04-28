FROM sequenceiq/kerberos

RUN mkdir -p /volumes/keytabs /volumes/kerberos /var/log/kerberos/
RUN touch /var/log/kerberos/krb5libs.log && \
    touch /var/log/kerberos/krb5kdc.log && \
    touch /var/log/kerberos/kadmind.log

ADD ./config.sh /config.sh
RUN chmod +x /config.sh
