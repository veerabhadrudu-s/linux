#!/usr/bin/bash

[[ -z $1 || -z $2 || -z $3 ]] && { echo "Usage: $0 <CODE_BASE_ABS_PATH> <TEST_DIR_STR> <BATCH_SIZE>"; exit 1; };
ls $1 &>/dev/null || { echo "Code base directory $1 doesn't Exist.Please enter valid code base directory in 1st argument."; exit 1; };
printf "$3" | egrep '^[1-9][0-9]*$' &>/dev/null || { echo "Batch size - $3 should be an Integer grater than 0 "; exit 1; };

#CODE_BASE_PATH="/home/veeras/dc-tests";
#TEST_DIR_STR="http mqtt coap";
#BATCH_SIZE=2;
CODE_BASE_PATH="${1%/}";
TEST_DIR_STR="$2";
TEST_DIRS=(${TEST_DIR_STR});
BATCH_SIZE="$3";

#Below approach is used to find path of current script.This is way it's working with systemd.
CURRENT_PID_CMD=$(ps -o cmd $$);
#echo "Current command ${CURRENT_PID_CMD}";
FULL_COMMAND_PATH=$(printf "${CURRENT_PID_CMD}" | awk '{print $2}');
echo "Current command ${FULL_COMMAND_PATH}";

for TEST_DIR in ${TEST_DIRS[@]};
do 
	echo "Executing test cases of directory - ${CODE_BASE_PATH}/${TEST_DIR} with batch size ${BATCH_SIZE}";
	ls "${CODE_BASE_PATH}/${TEST_DIR}" &>/dev/null || { echo "Test case directory ${CODE_BASE_PATH}/${TEST_DIR} doesn't Exist.Ignoring the directory."; continue; };
	${FULL_COMMAND_PATH%/*}/run_nodejs_testcases_in_batch.sh "${CODE_BASE_PATH}/${TEST_DIR}" ${BATCH_SIZE};
done

exit 0;
