#!/usr/bin/bash

for((i=0;i<10000;i++))
do
        sleep 1;
        echo "Printing counter $i value from script $0";
done;

exit 0;