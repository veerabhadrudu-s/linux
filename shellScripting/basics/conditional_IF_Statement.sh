#!/bin/bash


echo $(test -z $1 ) ; 

if [ -z "$1" ] ;
then
	echo "Requires input argument as either \"y/n\" " && exit 1;
elif [ "n" = $1 ] ;
then
	echo "Returning from script due to \"n\" argument" && exit 0;
elif [ "y" = $1 ] ;
then
	echo "$([ "y" = $1 ]) Result of previous command $?";
	echo "Executed script successfully" && exit 0;
else 
	echo "Invalid argument , Input argument can be either \"y/n\" " && exit 1;
fi

