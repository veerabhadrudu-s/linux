#!/usr/bin/bash


#Variable Declarations.
MAX_ALOWD_DUR=5;
#MAX_ALOWD_DUR=200;
#MAX_ALOWD_DUR=1;
#MAX_ALOWD_DUR=2;
SCRIPT_PATH=${0%/*};

#Validations
echo "Running stop hanging node mocha process @ $(date)";
:<<'BOC'
 Below command will identify running npx prrocess running mocha test runner.
 Above grep command output is filtered using command. 
 Awk command will give output format as <MOCHA_PROCESS_D>@<MOCHA_PARENT_PRO_ID>@<RUNNING_SINCE>
BOC

NPX_MOCHA_PROCESS_PS_OUT=$(ps -ef | egrep 'npx mocha' | grep -v grep);
NPX_MOCHA_PROCESS=$(printf "${NPX_MOCHA_PROCESS_PS_OUT}" | awk -F ' *' '/npx mocha/ && !/awk/  {print $2 "@" $3 "@" $5 }');
[[ -z ${NPX_MOCHA_PROCESS} ]] && { printf "Mocha process not running !!!\n\n\n"; exit 0; };

echo "Identifed node mocha ps command output -> ${NPX_MOCHA_PROCESS_PS_OUT}";
echo "Identified running mocha process -> ${NPX_MOCHA_PROCESS}";


#Logic to identify running since time of node mocha process and process killing hanged node mocha process if it breaches max allowed durations.

TODAYS_DATE=$( date +%m/%d/%Y );
MOCHA_PROCESS_ID=${NPX_MOCHA_PROCESS%%@*};
MOCHA_RUNNING_SINCE=${NPX_MOCHA_PROCESS##*@};
# TODO: Logic for day change after 12 pm to be implemented.
# MOCHA_RUNNING_SINCE=printf ${MOCHA_RUNNING_SINCE} |  egrep "[0-9]+:[0-9]+" &>/dev/null 
MOCHA_RUNNING_SINCE="${TODAYS_DATE} ${MOCHA_RUNNING_SINCE}:00";
CURRENT_TIME_IN_SEC=$(date +%s);
MOCHA_RUNNING_SINCE_IN_SEC=$( date -d "${MOCHA_RUNNING_SINCE}"  +%s );
TIME_DIFF_IN_MIN=$(( ( ${CURRENT_TIME_IN_SEC} - ${MOCHA_RUNNING_SINCE_IN_SEC} ) / 60 ));
TESTCASES_FILES=${NPX_MOCHA_PROCESS_PS_OUT#*mocha};
TESTCASES_DIR=${TESTCASES_FILES%%/*};
TESTCASES_DIR=$(printf "${TESTCASES_DIR}" | tr -d '[:space:]');

echo "Node mocha process ID -> ${MOCHA_PROCESS_ID} , running since -> ${MOCHA_RUNNING_SINCE} and test case files -> ${TESTCASES_FILES}";
echo "Node mocha running since -> ${MOCHA_RUNNING_SINCE} , current time -> $(date) and time diff in minute ${TIME_DIFF_IN_MIN}";

[[ ${TIME_DIFF_IN_MIN} -lt ${MAX_ALOWD_DUR} ]] && { printf "Mocha process started in less than allowed max duration of ${MAX_ALOWD_DUR}\n\n\n"; exit 0; };

:<<'BOC'
 Below command will identify node mocha process and corresponding descendant node and java process. 
 java.+jar regex will identify any java process started with jar and node.+mocha regex will identify any node mocha process.
 gsub will is used for sub string replacement. This needed to clean/restructure the output of pstree command.
 After that kills the processes in the loop logic.
BOC

MOCHA_PROCESS_TREE=$( pstree -gap ${MOCHA_PROCESS_ID} | awk -F ',' '/java.+jar/ || /node.+mocha/ { gsub(/.+-/, "",$1);  print $1 ":" $2 }' );

for PROCESS in ${MOCHA_PROCESS_TREE} ; 
do
	echo "Process type is -> ${PROCESS%:*} and process ID is -> ${PROCESS#*:}";
	kill ${PROCESS#*:}
done;

mkdir -p ${SCRIPT_PATH}/logs/"${TESTCASES_DIR}_logs";
echo "${TESTCASES_FILES}" >> ${SCRIPT_PATH}/logs/"${TESTCASES_DIR}_logs"/hanged_batch_test_cases.log;

printf "Completed killing hanged node mocha process tree\n\n\n";

exit 0;
