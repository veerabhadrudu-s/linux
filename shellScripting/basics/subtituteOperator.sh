#!/bin/bash

# Example script for substitution operator.

DATE=
#DATE=$(date +%d-%m-%y);

echo "${DATE:-today}";
echo "DATE Variable value is $DATE";
$(${DATE:?Date variable not set} 2>/dev/null) ;
echo "DATE Variable value is $DATE";
echo "${DATE:=$(date +%d-%m-%y)}";
echo "DATE Variable value is $DATE";

exit 0;
