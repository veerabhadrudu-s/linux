#!/usr/bin/bash 


USAGE="Usage: $0 <Test Case Folder> <Starting Range> <Ending Range>";

[[ -z "$1" || -z "$2" || -z "$3" ]] && { echo "${USAGE}"; exit 1; }; 
ls $1 &>/dev/null || { echo "Test Folder $1 doesn't Exist.Please enter valid test directory in 1st argument."; exit 1; };

TEST_DIR="${1%/}";

echo "Following Testcases will be executed";
ls ${TEST_DIR}/*.js | head -n $2 | tail -n $3;


npx mocha $(ls ${TEST_DIR}/*.js | head -n $2 | tail -n $3);

exit 0;
