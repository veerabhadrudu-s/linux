#!/bin/bash

# This script will check whether this system is a systemd based Linux OS or not.


function isSystemctlBasedOS {

VAR_SYSTEMCTL=systemctl1;

# Redirect stdout and stderr to seperate files
type $VAR_SYSTEMCTL > /dev/null 2>/dev/null ;
# Redirect stdout to file and stderr to stdout
type $VAR_SYSTEMCTL > /dev/null 2>&1 ;
# Redirect both stdout and stderr to file
type $VAR_SYSTEMCTL &> /dev/null ;

if [ $? -eq 0 ];
then
	echo This is a systemd based Linux OS && return 0;
else
	echo This is not a systemd based Linus OS && return 1;
fi

}

isSystemctlBasedOS;
# echo $VAR_SYSTEMCTL;

exit $?;
