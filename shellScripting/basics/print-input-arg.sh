#!/bin/bash

#This script prints input arguments supplied to the script.

VAR_WITHOUT_QUOTES=$@;
VAR_WITH_QUOTES="$@";

echo "Printing arguments using \$@";
for i in "$@"
do
   echo "$i";
done

echo "Printing arguments using \$*";
for j in "$*"
do
   echo $j;
done

echo "Printing VAR_WITHOUT_QUOTES using quotes in foreach";
for j in "$VAR_WITHOUT_QUOTES"
do
   echo $j;
done

echo "Printing VAR_WITHOUT_QUOTES without quotes in foreach";
for j in $VAR_WITHOUT_QUOTES
do
   echo $j;
done

echo "Printing VAR_WITH_QUOTES using quotes in foreach";
for j in "$VAR_WITH_QUOTES"
do
   echo $j;
done

echo "Printing VAR_WITH_QUOTES without quotes in foreach";
for j in $VAR_WITH_QUOTES
do
   echo $j;
done


exit 0
