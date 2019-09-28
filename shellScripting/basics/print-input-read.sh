#!/bin/bash

# This script reads input and prints those values.

echo "Enter variable and press enter";
read VAR;
echo "Enter three variable values by space separator";
read VAR1 VAR2 VAR3;
echo "Enter array values using space seperator";
read -a VAR_ARRAY;

echo "VAR Value = $VAR";
echo "VAR1 Value = $VAR1";
echo "VAR2 Value = $VAR2";
echo "VAR3 Value = $VAR3";
echo "VAR_ARRAY Value = ${VAR_ARRAY[*]}";

exit 0
