#!/usr/bin/bash

source ./common_functions.sh;
validate_execute_all_tc_args ${1} ${2};
validiate_any_node_mocha_process_already_running;
validate_state_of_iot_system;

DIR_NAME="${1%/}";
LOG_TAR_FILE=${DIR_NAME}_tc_stats.gz.tar;
echo "Starting executon of ${DIR_NAME} in background.Tail for logs using ' tail -f  ${DIR_NAME}_nohup.log '";

nohup ./execute_all_test_cases.sh ${DIR_NAME} ${2} &> ${DIR_NAME}_nohup.log && \
tar -czvf ${LOG_TAR_FILE} ${DIR_NAME}_nohup.log logs/${DIR_NAME}_logs/ && \
rm -fR logs/"${DIR_NAME}_logs"/* && rm -f ${DIR_NAME}_nohup.log  && \
echo "Completed executing test cases for ${DIR_NAME} and ${LOG_TAR_FILE} has been generated." & 

