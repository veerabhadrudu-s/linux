#!/bin/bash

# This example explains about command substitution , grouping commands using '()' and '{}'

VAR1=$( cat /etc/os-release );
echo "$VAR1";
# Command substition can be executed on multiple commands 
VAR2=$( cat /etc/hosts ; ls -ltra);
echo "$VAR2";
# Command grouping using  '()' executes in a sub-shell
( 
 echo "This is a grouping command syntax " ;
 echo "using '()' which runs in sub-shell ";
)
# Command grouping using  '{}' executes in a same shell context.
{ 
 echo "This is a grouping command syntax" ;
 echo "using '{}' which run's in same shell context ";
}

exit 0;
