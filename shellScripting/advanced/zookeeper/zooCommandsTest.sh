#!/bin/bash 
# This is a simple script to test all zookeeper supported commands.

VAR_USAGE="Usage: $0 <ZOOKEEOER_IP_ADDRESS> <PORT>";
VAR_COMMANDS_LIST=("conf" "cons" "crst" "dump" "envi" "ruok" "srst" "srvr" "stat" "wchs" "wchc" "wchp" );

[[  -z "$1" || -z "$2" ]] && { echo $VAR_USAGE ; exit 1; };

for COMMAND in ${VAR_COMMANDS_LIST[@]} ;
do 
	printf "$COMMAND RESPONSE IS  **********************************\n\n ";
	echo $COMMAND | nc $1 $2;
	printf "\n********************************** \n\n";
done;

exit 0;

