#!/bin/bash
# This script will deploy UIOT_OVERALL_STATUS_CHECK plugin into icinga.
# Example to test it ./deployUIoT_Overall_Status_Check.sh 155vm2 155vm2 /opt/hcutil/logs 

[[ -z $1 || -z $2 || -z $3 ]] && { echo "Usage : $0 <Icinga hostname> <Icinga host FQDN>  <Icinga Host UIOT Monitoring Plugin Log Path>" && exit 1;}

MON_PLUGIN="UIoT_Overall_Status_Check.pl";
MON_PLUGIN_NAME="UIoT_Overall_Status_Check";
UIOT_MONIT_LOG_PATH_KEY="UIOT_MONIT_LOG_PATH";
#UIOT_MONIT_LOG_PATH_VAL="/opt/hcutil/logs";
UIOT_MONIT_LOG_PATH_VAL="$3";
MON_CONFIG_FILE="/etc/Isildur/Configuration/Narsil.cfg";
MON_HOM="$(grep MONITORING_HOME $MON_CONFIG_FILE | awk -F = '{ print $2}')";

{ grep $UIOT_MONIT_LOG_PATH_KEY $MON_CONFIG_FILE >/dev/null || printf "#UIOT OVERALL MONITORING CHECK LOG DIR \n$UIOT_MONIT_LOG_PATH_KEY=\"$UIOT_MONIT_LOG_PATH_VAL\"" >> $MON_CONFIG_FILE ;} && \
\cp Write_HTML_Page.pm "$MON_HOM/Repository/" && \
\cp $MON_PLUGIN "$MON_HOM/Plugins/" && \
{ icingacli director command show $MON_PLUGIN_NAME &>/dev/null || icingacli director command create $MON_PLUGIN_NAME --json "{ \"command\" : [ \"$MON_HOM/Plugins/$MON_PLUGIN\" , \"\$host.name\$\" , \"\$service.name\$\" , \"\$FQDN\$\", \"\$host.address\$\" ] , \"timeout\" : \"90s\" }" &>/dev/null ; } && \
{ icingacli director service show $MON_PLUGIN_NAME &>/dev/null || icingacli director service create "$MON_PLUGIN_NAME" --json "{ \"object_type\": \"template\" , \"check_command\" : \"$MON_PLUGIN_NAME\" , \"max_check_attempts\" : \"2\" , \"check_interval\" : \"5m\" , \"retry_interval\" : \"2m\" ,  \"enable_notifications\" : true , \"enable_active_checks\" : true  ,  \"enable_passive_checks\" : true , \"enable_event_handler\" : true , \"enable_flapping\" : true , \"enable_perfdata\" : true , \"volatile\" : true }" &>/dev/null ; };
[ $? -gt 0 ] && { echo "Command or Service templete Registration failed"; exit 2; };
{ icingacli director service show $MON_PLUGIN_NAME --host "$1" &>/dev/null || icingacli director service create $MON_PLUGIN_NAME --imports $MON_PLUGIN_NAME --host  "$1" &>/dev/null ; } && \
{ icingacli director host show $1 | grep 'vars\.FQDN' &>/dev/null || icingacli director host set $1 --vars.FQDN "$2" &>/dev/null ;};
[ $? -gt 0 ] && { echo "Host doesn't exist with name $1" ; exit 3; };
icingacli director config deploy &>/dev/null || { echo "Deployment Failed in icinga "; exit 4;};

echo "Plugin Registration completed successfully" && exit 0;

