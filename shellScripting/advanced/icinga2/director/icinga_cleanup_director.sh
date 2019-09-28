#!/usr/bin/bash
: <<BOC
This script will clean up Icinga director component.
BOC

declare -A FILE_TYPE_MAPPER=([1]="host" [2]="host" [3]="hostgroup" [4]="service" [5]="command"); 
USAGE="Usage : $0 <host_config.csv> <host_template.csv> <host_groups.csv> <service_template.csv> <command_config.csv>"

[[ -z "$1" || -z "$2" || -z "$3" || -z "$4" || -z "$5" ]] && { echo "$USAGE"; exit 1; };

for((i=1;i<=${#FILE_TYPE_MAPPER[@]};i++)); do
#	echo "Identified object type is ${FILE_TYPE_MAPPER[$i]}";
#	awk -F ',' 'BEGIN{ i=0;} {i++; print $1; } END{ print "No of lines read from files is " i; }' ${!i};
	OBJECT_NAMES=( $(awk -F ',' '{ print $1; }' ${!i} ));
	for((j=0;j<${#OBJECT_NAMES[@]};j++)) ; do
		OBJECT_NAME=${OBJECT_NAMES[j]};
		OBJECT_NAME=${OBJECT_NAME//[$'\n\r']};
#		echo "icingacli director ${FILE_TYPE_MAPPER[$i]} delete ${OBJECT_NAME} ;";
		icingacli director ${FILE_TYPE_MAPPER[$i]} delete ${OBJECT_NAME} ;
	done;
done;

exit 0;
