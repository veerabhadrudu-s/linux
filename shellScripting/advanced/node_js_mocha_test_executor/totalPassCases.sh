#!/usr/bin/bash

#Variable declerations
DIR="${1%/}";
USAGE="Usage : $0 <LOG_DIR> ";
LOG_DIR_PATH="logs/${DIR}_logs/tc_logs";
TOTAL_TESTCASES=0;
TOTAL_PASS_CASES=0;
TOTAL_FAIL_CASES=0;
CUR_FILE_PASS_CNT=0;
CUR_FILE_FAIL_CNT=0;
FAILED_TC_LOG_FILES=();
POSBL_HNGD_BATCH_TS_CASES=();

#VALIDATIONS
[[ -z ${DIR} ]] && { echo "${USAGE}"; exit 1; }; 
[[ -d ${LOG_DIR_PATH} ]] || { echo "Following log directory path must exist ${LOG_DIR_PATH}"; exit 1; };

#Read each log file and identify total test cases results.
for LOG_FILE in $(ls -tr ${LOG_DIR_PATH}/*.log 2>/dev/null );
do
	
	CUR_FILE_PASS_CNT=$( awk -F ' *' '/^ *[0-9]+ passing/  { print $2}' ${LOG_FILE} );
	CUR_FILE_FAIL_CNT=$( awk -F ' *' '/^ *[0-9]+ failing/  { print $2}' ${LOG_FILE} );
	# If pass count and fail count result in log file is empty then it could be because of hanged testcase in that batch.
	[[ -z ${CUR_FILE_PASS_CNT} && -z ${CUR_FILE_FAIL_CNT} ]] && { POSBL_HNGD_BATCH_TS_CASES[${#POSBL_HNGD_BATCH_TS_CASES[@]}]=${LOG_FILE}; };
	CUR_FILE_PASS_CNT=${CUR_FILE_PASS_CNT:-0}; # If awk comamnd result's empty string means 0 success cases.
	CUR_FILE_FAIL_CNT=${CUR_FILE_FAIL_CNT:-0}; # If awk comamnd result's empty string means 0 failure cases.
#	echo "Reading log file ${LOG_FILE} pass count -> ${CUR_FILE_PASS_CNT} and fail count -> ${CUR_FILE_FAIL_CNT}";
	TOTAL_PASS_CASES=$(( ${TOTAL_PASS_CASES} + ${CUR_FILE_PASS_CNT} ));
	TOTAL_FAIL_CASES=$(( ${TOTAL_FAIL_CASES} + ${CUR_FILE_FAIL_CNT} ));
	TOTAL_TESTCASES=$(( ${TOTAL_TESTCASES} + ${CUR_FILE_PASS_CNT} + ${CUR_FILE_FAIL_CNT} ));
	[[ ${CUR_FILE_FAIL_CNT} -gt 0 ]] && { FAILED_TC_LOG_FILES[${#FAILED_TC_LOG_FILES[@]}]=${LOG_FILE}; };
done;	

printf "\nTotal Test cases executed for ${DIR} is ${TOTAL_TESTCASES}\n";
echo "Total Test cases passed for ${DIR} is ${TOTAL_PASS_CASES}";
printf "Total Test cases failed for ${DIR} is ${TOTAL_FAIL_CASES}\n";

#Printing failure test cases log files.
if [[ ${TOTAL_FAIL_CASES} -gt 0 ]]; 
then
	printf "\nCheck below log files for failures\n\n";
	for FAIL_LOG_FILE in ${FAILED_TC_LOG_FILES[@]}; do echo ${FAIL_LOG_FILE}; done;
fi;
echo "";

#Printing possible hanged batch test cases log files and other errors.
printf "\nCheck logs/${DIR}_logs/hanged_batch_test_cases.log file for hanged batch test cases log files.\n";

if [[ ${#POSBL_HNGD_BATCH_TS_CASES[@]} -gt 0 ]]; 
then
	printf "\nCheck below log files for possible hanged test cases failures,compilation failure and abnoraml exit testcases \n\n";
	for POSBLE_HANGD_BATCH in ${POSBL_HNGD_BATCH_TS_CASES[@]}; do echo ${POSBLE_HANGD_BATCH}; done;
fi;
echo "";
exit 0;

