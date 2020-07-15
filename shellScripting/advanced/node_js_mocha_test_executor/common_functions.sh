#!/usr/bin/bash

function validate_execute_all_tc_args() {
	local USAGE="Usage : $0 <TESTCASE_DIR> <BATCH_SIZE_OPTIONAL>";
	[[ -d $1 ]] || { echo "${USAGE}"; exit 1; };
	[[ -n $2 ]] && { echo "$2" | egrep "^[1-9][0-9]*$" &>/dev/null || { echo "Batch size in the second arg should be grater than 0."; exit 1; }; };
}

function validiate_any_node_mocha_process_already_running(){

	NPX_MOCHA_PROCESS_PS_OUT=$(ps -ef | egrep 'npx mocha' | grep -v grep);
	[[ -n ${NPX_MOCHA_PROCESS_PS_OUT} ]] && \
{ printf "Below Node mocha process  already running either wait/kill before executing tests \n ${NPX_MOCHA_PROCESS_PS_OUT}\n"; exit 1; };

}

function validate_state_of_iot_system(){
	echo "Make sure to have ssh connectivity using public key between this VM and LDAP,EDB VM";
	validate_applications_subscriptions;	
}


function validate_applications_subscriptions(){
	#Application Names to be validated
	APP_NAMES=( 'dc-test-app' 'lpgaz_app_2_automation');

	LDAP_URL=$( egrep 'url.+ldap' config.js | head -n 1 );
	LDAP_LOGIN_DN=$( egrep 'login_dn' config.js | head -n 1 );
	LDAP_LOGIN_PSWD=$( egrep 'login_dn_password' config.js | head -n 1 );
	LDAP_URL=${LDAP_URL%\',*};
	LDAP_URL=${LDAP_URL#*//};
	OLDIFS=$IFS;
	IFS=':' LDAP_IP_PORT=( ${LDAP_URL} );
	IFS=${OLDIFS};
	LDAP_LOGIN_DN=${LDAP_LOGIN_DN%\',*};
	LDAP_LOGIN_DN=${LDAP_LOGIN_DN#*\'};
	LDAP_LOGIN_PSWD=${LDAP_LOGIN_PSWD%\',*};
	LDAP_LOGIN_PSWD=${LDAP_LOGIN_PSWD#*\'};
	echo "LDAP Details : Ldap Ip and port -> ${LDAP_IP_PORT[@]} LDAP Login DN -> ${LDAP_LOGIN_DN} LDAP Login Password -> ${LDAP_LOGIN_PSWD}";
	echo "Applications that are validated ${APP_NAMES[@]}";
	APP_DN_PREFIX="'uid=HPE_IoT/"
	APP_DN_SUFFIX=",ou=alias,ou=AuthNZ,ou=M2M,dc=UIoT,dc=org' aliasedObjectName";
	for APP_NAME in ${APP_NAMES[@]} ;
	do
		printf "Connecting to LDAP Server ${LDAP_IP_PORT[0]} over SSH.\n";
 		printf "If you see script hanging after this statement for long time then ssh connectivity is not established between VM's\n\n";
		AE_ID=$( ssh -q root@${LDAP_IP_PORT[0]} "ldapsearch -LLL -h ${LDAP_IP_PORT[0]} -p ${LDAP_IP_PORT[1]} -D '${LDAP_LOGIN_DN}' -w '${LDAP_LOGIN_PSWD}' -b ${APP_DN_PREFIX}${APP_NAME}${APP_DN_SUFFIX}" );
		AE_ID=$( printf "${AE_ID}" | egrep "aliasedObjectName" );
		AE_ID=${AE_ID%%,*};
		AE_ID=${AE_ID#*=};
		echo "AE ID Read from Ldap for Application ${APP_NAME} is ${AE_ID}";
		[[ -z ${AE_ID} ]] && { printf "Application ${APP_NAME} AE ID retrieved from ldap is empty. Make sure application is already onboarded in UIOT\n\n\n"; exit 1; };
		validate_ae_id_subscriptions "${APP_NAME}" "${AE_ID}";
		printf "\n\n\n"
	done;
}


function validate_ae_id_subscriptions(){

	echo "Validating for subscriptions for application ${1} having AE ID ${2}";
	EDB_IP=$( egrep 'postgres_ip' config.js | head -n 1);
	EDB_PORT=$( egrep 'postgres_port' config.js | head -n 1 );
	EDB_UNAME=$( egrep 'postgres_username' config.js | head -n 1 );
	EDB_PSWD=$( egrep 'postgres_password' config.js | head -n 1 );
	EDB_DB=$( egrep 'postgres_dbname' config.js | head -n 1 );
	EDB_SCHEMA=$( egrep 'postgres_schema' config.js | head -n 1 );
	EDB_IP=${EDB_IP%\',*};
	EDB_IP=${EDB_IP#*\'};
	EDB_PORT=${EDB_PORT%\',*};
	EDB_PORT=${EDB_PORT#*\'};
	EDB_UNAME=${EDB_UNAME%\',*};
        EDB_UNAME=${EDB_UNAME#*\'};
	EDB_PSWD=${EDB_PSWD%\',*};
        EDB_PSWD=${EDB_PSWD#*\'};
	EDB_DB=${EDB_DB%\',*};
        EDB_DB=${EDB_DB#*\'};
	EDB_SCHEMA=${EDB_SCHEMA%\'*};
        EDB_SCHEMA=${EDB_SCHEMA#*\'};
	
	echo "Following EDB details are used -> IP ${EDB_IP} PORT ${EDB_PORT} DB Username ${EDB_UNAME} DB Password ${EDB_PSWD} DB Name ${EDB_DB} Schema ${EDB_SCHEMA}";
	DB_QUERY_PREFIX="\"select count(resource_id) from ${EDB_SCHEMA}.subscription where creator = '";
	DB_QUERY_SUFIX="'\"";
	printf "If you see script hanging after this statement for long time then ssh connectivity is not established between VM's\n\n";
#	SUBS_COUNT=$( ssh -q root@${EDB_IP} "psql -Aqtw -h ${EDB_IP} -p ${EDB_PORT} -U ${EDB_UNAME} -d ${EDB_DB} -c ${DB_QUERY_PREFIX}${2}${DB_QUERY_SUFIX}" );
	SUBS_COUNT=$( ssh -q root@${EDB_IP} "psql -Aqtw -U ${EDB_UNAME} -d ${EDB_DB} -c ${DB_QUERY_PREFIX}${2}${DB_QUERY_SUFIX}" );
	echo "Subscription count identified for Application ${1} is ${SUBS_COUNT}";
	printf "${SUBS_COUNT}" | egrep "^[0-9]+$" &>/dev/null;
	[[ $? -eq 1 ]] && { printf "Subscription count returned for application ${1} is not valid number.Make sure application is already onboarded in UIOT "; exit 1; };
	[[ ${SUBS_COUNT} -gt 0 ]] && { printf "Application ${1} has existing subscriptions.Please remove existing applications in DSM.\n\n\n"; exit 1; };

}



