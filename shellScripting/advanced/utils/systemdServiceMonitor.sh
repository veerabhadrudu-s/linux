#!/bin/bash

# This is a service monitoring script which monitors systemd service.
# Restarts the service in case if it fails/stops and sends email to root user.

VAR_SERVICE=$1
IS_MONTR_CAN_RUN=true;

trap "IS_MONTR_CAN_RUN=false" SIGINT SIGTERM;


[ -z "$VAR_SERVICE" ] && echo "Service to be monitored cannot be empty" && exit 1;
systemctl is-enabled "$VAR_SERVICE.service" &>/dev/null;
[ $? -gt 0 ] && echo "Service with name $VAR_SERVICE  is not installed or disable" && exit 1;

#echo "Monitoring $VAR_SERVICE service ";
logger -p "local0.debug" "Monitoring $VAR_SERVICE service started ";

while $IS_MONTR_CAN_RUN
do
	systemctl status "$VAR_SERVICE.service" &>/dev/null;
	if [ "$?" -gt 0 ]
	then 
	   # echo "$VAR_SERVICE service is not running. Restarting the service";
	   logger -p "local0.info" "$VAR_SERVICE service is not running. Restarting the service";
	   mail -s "$VAR_SERVICE service is not running. Restarting the service" root < . &>/dev/null ;
           systemctl restart  "$VAR_SERVICE.service" &>/dev/null;
  	fi	
	sleep 5;
done

echo "Monitoring $VAR_SERVICE service is stopped due to SIGINT or SIGTERM.";
logger -p "local0.info" "Monitoring $VAR_SERVICE service is stopped due to SIGINT or SIGTERM.";

exit 0;

 
