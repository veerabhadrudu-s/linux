#!/usr/bin/bash

[[ -z "$1" ]] && { echo "Usage: $0 <child_process_counter>"; exit 1; };
#[[ "$1" -le "0" ]] && { echo "Child process argument should be grater than 0"; exit 1; };
[[ "$1" -le "0" ]] && exit 1; 

$0 "$(( $1 - 1 ))" & 

for((i=0;i<10000;i++))
do
        sleep 1;
        echo "Printing counter $i value from script $0 in child process instance id $(( ${1} - 1))";
done;

exit 0;
