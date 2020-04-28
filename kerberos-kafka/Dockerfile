FROM sequenceiq/kerberos

RUN mkdir -p /volumes/keytabs 
RUN ln -s /var/kerberos /volumes/kerberos

ADD ./config.sh /config.sh
