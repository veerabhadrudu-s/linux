#!/usr/bin/bash 
: <<BLK_CMT
This script will execute dc test cases in batch.
BLK_CMT

USAGE="Usage: $0 <Test Case Folder> <Batch Size>";
TEST_DIR="${1%/}";

[[ -z "$1" || -z "$2" ]] && { echo "${USAGE}"; exit 1; }; 
ls ${TEST_DIR} &>/dev/null || { echo "Test Folder $1 doesn't Exist.Please enter valid test directory in 1st argument."; exit 1; };
[[ $(ls ${TEST_DIR}/*.js | wc -l) > 1 ]] || { echo "Atleast one test case should exist in Test Folder $1"; exit 1; };
printf "$2" | egrep '^[1-9][0-9]*$' &>/dev/null || { echo "Batch size - $2 should be an Integer grater than 0 "; exit 1; };

BATCH_SIZE=$2;
VAR_LOG_PATH="/var/log/dc_automation"
TOTAL_TESTCASES_COUNT=$(ls ${TEST_DIR}/*.js | wc -l);
TOTAL_BATCHES_COUNT=$(( ${TOTAL_TESTCASES_COUNT}/${BATCH_SIZE} ));
TOTAL_BATCHES_COUNT=$(( TOTAL_TESTCASES_COUNT % BATCH_SIZE > 0 ? TOTAL_BATCHES_COUNT+1 : TOTAL_BATCHES_COUNT ));
TAIL_COUNT=$BATCH_SIZE;
TIMESTAMP=$(date "+%d_%m_%y_%H_%M_%S");
TEST_DIR_LOWER=$(echo "${TEST_DIR##*/}" | tr [:upper:] [:lower:] );

mkdir -p "${VAR_LOG_PATH}";
echo "TOTAL_TESTCASES_COUNT : $TOTAL_TESTCASES_COUNT , TOTAL_BATCHES_COUNT : $TOTAL_BATCHES_COUNT";

for((BATCH_COUNTER=1;BATCH_COUNTER<=TOTAL_BATCHES_COUNT;BATCH_COUNTER++));
do
	#echo "Printing batch ${BATCH_COUNTER} files";
	TAIL_COUNT=$(( TOTAL_TESTCASES_COUNT >= BATCH_COUNTER*BATCH_SIZE ? BATCH_SIZE : TOTAL_TESTCASES_COUNT % BATCH_SIZE ));
	BATCH_START_INDEX=$(( (BATCH_COUNTER-1)*BATCH_SIZE+1 ));
	BATCH_END_INDEX=$(( (BATCH_COUNTER-1)*BATCH_SIZE+TAIL_COUNT ));
	LOG_FILE_PATH="${VAR_LOG_PATH}/${TEST_DIR_LOWER}_${TIMESTAMP}_${BATCH_START_INDEX}_${BATCH_END_INDEX}.log";
	echo "BATCH Staring value is ${BATCH_START_INDEX} and BATCH ending value is ${BATCH_END_INDEX}";
	ls ${TEST_DIR}/*.js | head -n $(( BATCH_COUNTER*BATCH_SIZE )) | tail -n ${TAIL_COUNT};
	npx mocha $(ls ${TEST_DIR}/*.js | head -n $(( BATCH_COUNTER*BATCH_SIZE )) | tail -n ${TAIL_COUNT}) 2>&1 > ${LOG_FILE_PATH} ;
	echo -e "\n\n";
done

tar -cvzf ${VAR_LOG_PATH}/${TEST_DIR_LOWER}_${TIMESTAMP}.gz.tar  ${VAR_LOG_PATH}/${TEST_DIR_LOWER}_${TIMESTAMP}*log;
rm -f ${VAR_LOG_PATH}/${TEST_DIR_LOWER}_${TIMESTAMP}*log;

exit 0;

