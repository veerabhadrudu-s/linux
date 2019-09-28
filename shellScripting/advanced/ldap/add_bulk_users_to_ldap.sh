#!/usr/bin/bash
# This script will perform bulk import of users to LDAP Server.

USAGE="Usage $0 START_USER_ID END_USER_ID";

[[ -z $1 || -z $2 ]] && { echo "$USAGE"; exit 1; };
{ echo "$1" | egrep "^[0-9]+$" &>/dev/null  && echo "$2" | egrep "^[0-9]+$" &>/dev/null ;} || { echo "START_USER_ID and END_USER_ID should be numerical"; exit 2; };
[[ "$2" -gt "$1" ]] || { echo "START_USER_ID should be less than END_USER_ID "; exit 3; }

#echo "Validation Completed";
#We have used eval operator in below code. This should be replaced with alternate approach to avoid security issues.
#VAL=$(eval echo {$1..$2});
#echo $VAL;

for USER_ID in $(eval echo {$1..$2});
do

ldapadd -x -w password -D "cn=ldapadm,dc=ldaptest,dc=com" <<HERE_DOC
	dn: uid=ldapuser_$USER_ID,ou=People,dc=ldaptest,dc=com
	objectClass: top
	objectClass: account
	objectClass: posixAccount
	objectClass: shadowAccount
	cn: ldapuser_$USER_ID
	uid: ldapuser_$USER_ID
	uidNumber: 9999
	gidNumber: 100
	homeDirectory: /home/ldapuser_$USER_ID
	loginShell: /bin/bash
	gecos: Ldapuser_1 [Admin (at) ldaptest]
	userPassword: userpassword
	shadowLastChange: 17058
	shadowMin: 0
	shadowMax: 99999
	shadowWarning: 7
HERE_DOC

done;



exit 0;
