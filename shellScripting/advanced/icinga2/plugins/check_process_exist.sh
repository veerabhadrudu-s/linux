#!/bin/bash
# Nagios Plugin Bash Script 
# This script checks if process is running

# Check for missing parameters
# Input Validation
#if  [[ -z "$1" || -z "$2" ]]
if [ -z "$1" -o -z "$2" ]
then
        echo "Missing parameters! Syntax: ./$0 hostname process_name"
        exit 3
fi

# echo $( ssh hpeiotmon@$1  "ps -ef | grep -v grep | grep -v $0 | grep $2");
RES=$( ssh hpeiotmon@$1  "ps -ef | grep -v grep | grep -v $0 | grep \"$2\" | wc -l");
if [ $RES -gt 0 ]
then
	echo "OK, $2 process is running | $2_process_result_count=$RES"
        exit 0
else
	echo "CRITICAL , $2 process is not running | $2_process_result_count=$RES"
        exit 2
fi
