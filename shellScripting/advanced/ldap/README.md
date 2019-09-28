# OpenLdap Configuration Standalone and Replication 

## Prerequisites:- Make sure to study basic concepts of OpenLdap from Admin Guide - https://www.openldap.org/doc/

## Introduction:-

### This document explaines how to setup OpenLDAP Server with sample data in Standalone and Replication. This directory also has bulk insert script.

## **Stanalone Configuration**

#### **Prerequisites**:- Make sure to study basic concepts of OpenLdap from Admin Guide- https://www.openldap.org/doc/
``` 
mkdir /var/log/openldap && chown ldap.ldap /var/log/openldap ;
printf "local4.*                                                /var/log/openldap/openldap_debug.log" >> /etc/rsyslog.conf;
systemctl restart rsyslog.service
systemctl restart slapd.service 
```

#### Use contents of **0-slapd** directory for configuration and follow below instructions to setup standalone configuration of OpenLdap (slapd - Slandalone LDAP Daemon),

1. Import 0-db.ldif file using below shell command.This file will configure olcSuffix,olcRootDN and password for our user LDAP DB.
``` 
ldapmodify -Y EXTERNAL  -H ldapi:/// -f 0-db.ldif
```
2. Import 1-monitor.ldif file using below shell command. This configuration allows **DN with name (BindDN)** cn=ldapadm,dc=ldaptest,dc=com to access LDAP monitoring db/componnent.
```
ldapmodify -Y EXTERNAL  -H ldapi:/// -f 1-monitor.ldif
```
3. Import of HDB configuration should be completed using below shell commands.
```
cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
chown ldap.ldap /var/lib/ldap/DB_CONFIG
```
4. Import the schema's into LDAP DB using below commands.
```
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif 
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif
```
5. Import 2-base.ldif configuration file using below ldapadd command.This command will create intital top level LDAP entries in user LDAP DB
```
ldapadd -x -W -D "cn=ldapadm,dc=ldaptest,dc=com" -f 2-base.ldif
```
6. Import this file using below shell command.This command will import one user LDAP entry into user LDAP DB.
```
ldapadd -x -W -D "cn=ldapadm,dc=ldaptest,dc=com" -f 3-users.ldif
```
7. Now you can start using add_bulk_users_to_ldap.sh to bulk import users into LDAP.

* Above created steps are refered from below link.

https://www.itzgeek.com/how-tos/linux/centos-how-tos/step-step-openldap-server-configuration-centos-7-rhel-7.html


## **Replication Configuration**

OpenLdap support's different replication modes 

* Syncrepl - Simple Provider and Consumer (Master Slave Configuration).
* Syncrepl Multi Master Configuration - This configuration will contain Multiple Providers (Masters) and Each Provider(Master) will contains multiple consumer. 
* Syncrepl Mirror Mode - This configuration requires 2 LDAP Server. Both will works as Provider and Consumer and they replicate each other. This is hybrid configuration of above 2 replication modes.

In this document we will cover Syncrepl and Syncrepl Mirror Mode.

### Syncrepl - Simple Provider and Consumer 

#### **Prerequisites**:- Make sure 2 instances of standalone slapd servers configured using above **Stanalone Configuration** setup.

#### Use contents of **1-syncrepl** directory for configuration and follow below instructions,

1. In provider(master) server, Import 0-provider-1.ldif file using below command to enable/configure syncprov Module (syncrepl) at provider side.
```
ldapadd -Y EXTERNAL -H ldapi:/// -f 0-provider-1.ldif
```
2. In provider(master) server, Import 0-provider-2.ldif file using below command to configure indexes for entryCSN,entryUUID attributes. These are meta attibutes , for more information on this refer Replication chapter in Admin Guide.
```
ldapmodify -Y EXTERNAL  -H ldapi:/// -f 0-provider-2.ldif
```
3. In consumer(slave) server, Import 1-consumer.ldif file using below command to configure syncrepl configuration at consumer side. 
```diff 
- Make sure to update provider url in 1-consumer.ldif file before importing.
```
```
ldapmodify -Y EXTERNAL  -H ldapi:/// -f 1-consumer.ldif
```
4. Above steps complete Syncrepl - Simple Provider and Consumer. Start adding the data using add_bulk_users_to_ldap.sh script and observe data replicated in consumer server.


### Syncrepl Mirror Mode

#### **Prerequisites**:- Make sure 2 instances of standalone slapd servers configured using above **Stanalone Configuration** setup.

#### Use contents of **2-syncrepl_mirror_mode** directory for configuration and follow below instructions,

1. In server 1, Import 0-server_1-1.ldif and 0-server_1-2.ldif files using below commands. This will enable/configure syncprov Module (syncrepl) in server-1 and also it will assign serverID to Ldap Server,Mirror Mode Enabled and SyncRepl Consumer Configuration configured to point server 2.
```diff 
- Make sure to update provider url in 0-server_1-2.ldif file before importing.
```
```
ldapadd -Y EXTERNAL -H ldapi:/// -f 0-server_1-1.ldif
ldapmodify -Y EXTERNAL  -H ldapi:/// -f 0-server_1-2.ldif
```
2. In server 2, Import 1-server_2-1.ldif and 1-server_2-2.ldif files using below commands. This will enable/configure syncprov Module (syncrepl) in server-2 and also it will assign serverID to Ldap Server,Mirror Mode Enabled and SyncRepl Consumer Configuration configured to point server 1.
```diff 
- Make sure to update provider url in 1-server_2-2.ldif file before importing.
```
```
ldapadd -Y EXTERNAL -H ldapi:/// -f 1-server_2-1.ldif
ldapmodify -Y EXTERNAL  -H ldapi:/// -f 1-server_2-2.ldif
```
3. Above steps complete Syncrepl Mirror Mode. Start adding the data in both servers using add_bulk_users_to_ldap.sh script and observe data replicated in both servers.


