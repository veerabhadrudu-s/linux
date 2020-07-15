#!/usr/bin/bash

#Variable Decleartions
USAGE="${0} <config_file_tmpt_file> <OPTIONAL_PROPERTY_VAL_SEPERATOR_CHAR>";
DEF_PROP_VAL_SEP=":";
CONFIG_FILE="config.js";

#Validations
[[ -z ${1} ]] && { echo "${USAGE}"; exit 1; };
[[ -a ${1} ]] || { echo "Input file ${1} doesn't exist."; exit 1; };
[[ -f ${1} && -r ${1} ]] || { echo "Input file ${1} is not a readable text file."; exit 1; };
[[ -a ${CONFIG_FILE} ]] || { echo "Config file ${CONFIG_FILE} doesn't exist."; exit 1; };
[[ -f ${CONFIG_FILE} && -r ${CONFIG_FILE} ]] || { echo "Config file ${CONFIG_FILE} not a readable text file."; exit 1; };
[[ -z ${2} ]] && echo "Optional Property value seperator not provided.So using default one ${DEF_PROP_VAL_SEP}";


PROP_VAL_SEP=${2:-${DEF_PROP_VAL_SEP}};
IFS=$'\n' PROP_VALUES=( $(cat ${1}) );
#echo "Property value array length -> ${#PROP_VALUES[@]}";
echo "Original file backup with name ${CONFIG_FILE}.bac";
cp ${CONFIG_FILE} ${CONFIG_FILE}.bac;
printf "Started configuring config file -> ${CONFIG_FILE} \n\n\n";

for((INDEX=0;INDEX<${#PROP_VALUES[@]};INDEX++));
do
	IFS=${PROP_VAL_SEP} PROP_VALUE=( ${PROP_VALUES[${INDEX}]} );
	echo "Identified property place holder is  ${PROP_VALUE[0]} and will be replaced with value ${PROP_VALUE[1]}";
	sed -i "s/${PROP_VALUE[0]}/${PROP_VALUE[1]}/g" ${CONFIG_FILE};
done;

printf "\n\nCompleted configuring config file -> ${CONFIG_FILE} \n";

exit 0;


