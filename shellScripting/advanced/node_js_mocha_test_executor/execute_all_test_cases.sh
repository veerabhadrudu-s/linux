#!/usr/bin/bash

source ./common_functions.sh;
validate_execute_all_tc_args $1 $2;
validiate_any_node_mocha_process_already_running;
validate_state_of_iot_system;

#echo "IFS Value $IFS";

#Variable Declerations
BATCH_SIZE=${2:-10};
declare -a BATCHES=();
DIR_NAME="${1%/}";
LOG_DIR_NAME="logs/${DIR_NAME}_logs";
TC_LOG_DIR_NAME="${LOG_DIR_NAME}/tc_logs";
TC_COUNT=$( ls "${DIR_NAME}"/*.js 2>/dev/null | wc -l );
BATCH_COUNT=$(( ${TC_COUNT} / ${BATCH_SIZE} ));
#Logic to find batch arguments require to invoke ./runTestcasesInBatch.sh script
for((BATCH_COUNTER=1;${BATCH_COUNTER}<=${BATCH_COUNT};BATCH_COUNTER++));
do
	BATCHES[$(( ${BATCH_COUNTER} - 1 ))]="$(( ${BATCH_COUNTER} * ${BATCH_SIZE} )):${BATCH_SIZE}";
done;
#Logic to find batch arguments for special case of last batch.
if [[ $(( ${TC_COUNT} % ${BATCH_SIZE} )) -gt 0 ]];
then
	BATCHES[${#BATCHES[@]}]="${TC_COUNT}:$(( ${TC_COUNT} % ${BATCH_SIZE} ))";
fi;

# Clear existing logs
rm -fR ${LOG_DIR_NAME}/*;
#Create or ignore existing  log directory path
mkdir -p ${TC_LOG_DIR_NAME};
#Creating or clearing hanged test cases log file. This file will be filled by another stopHangedTestCases.sh that runs as a cron Job.
> ${LOG_DIR_NAME}/hanged_batch_test_cases.log;
echo "Check below batch specific log file for hanged test cases." >> ${LOG_DIR_NAME}/hanged_batch_test_cases.log;
printf "If any test case is hanged in a batch all the remaning testcases in that batch will be stopped executing.\n\n" >> ${LOG_DIR_NAME}/hanged_batch_test_cases.log; 

#Invoke the test cases in batch and save log files 
for BATCH in ${BATCHES[@]} ;
do 
#	echo "Current Batch ${BATCH}" 
#	echo "Starting index -> ${BATCH%:*} and ending index ->  ${BATCH#*:}";
	TEST_CASE_CURNT_BATCH_COUNT=${BATCH%:*};
	TEST_CASE_CURNT_BATCH_SIZE=${BATCH#*:};
	TEST_CASE_START_NUM=$(( ${TEST_CASE_CURNT_BATCH_COUNT} < ${BATCH_SIZE} ? 1 : (( ${TEST_CASE_CURNT_BATCH_COUNT} - (( ${TEST_CASE_CURNT_BATCH_SIZE} - 1 )) )) ));
	TEST_CASE_END_NUM=$(( ${TEST_CASE_START_NUM} + (( ${TEST_CASE_CURNT_BATCH_SIZE} - 1 )) ));
	echo "Current batch starting id -> ${TEST_CASE_START_NUM} and ending id ->  ${TEST_CASE_END_NUM}";
	./runTestcasesInBatch.sh ${DIR_NAME}  ${BATCH%:*} ${BATCH#*:} &> ${TC_LOG_DIR_NAME}/${DIR_NAME}_${TEST_CASE_START_NUM}_${TEST_CASE_END_NUM}.log;

done;

printf "\nCompleted executing test cases of ${DIR_NAME} \n";
printf "Printing testcases execution results of ${DIR_NAME} \n\n";
./totalPassCases.sh ${DIR_NAME};


exit 0;

