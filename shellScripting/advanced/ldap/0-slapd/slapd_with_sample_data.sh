#!/usr/bin/bash 

mkdir /var/log/openldap && chown ldap.ldap /var/log/openldap && \
printf "local4.*                                                /var/log/openldap/openldap_debug.log" >> /etc/rsyslog.conf && \
systemctl restart rsyslog.service && \
systemctl restart slapd.service && \
ldapmodify -Y EXTERNAL  -H ldapi:/// -f 0-db.ldif && \
ldapmodify -Y EXTERNAL  -H ldapi:/// -f 1-monitor.ldif && \
cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG && \
chown ldap.ldap /var/lib/ldap/DB_CONFIG && \
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif && \
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif && \
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif && \
ldapadd -x -w password -D "cn=ldapadm,dc=ldaptest,dc=com" -f 2-base.ldif && \
ldapadd -x -w password -D "cn=ldapadm,dc=ldaptest,dc=com" -f 3-users.ldif && \
systemctl restart slapd.service  && \
printf "\nOpenLdap With Sample Data Configured Successfully !!! \n";

exit $?;



