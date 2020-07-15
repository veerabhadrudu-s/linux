#!/usr/bin/bash 

:<<'BOC'
 Current working directory should contain dc_tests directory or create symbolic in current directory pointing dc tests working directory.
BOC

#Variable Declerations
CODE_DIR="dc_tests";
USAGE="Current working directory should contain '${CODE_DIR}' directory or create symbolic '${CODE_DIR}' in current directory pointing dc tests working directory.";
THIS_SCRIPT_FILE_NAME=${0##*/};

#Validations

[[ -d "./${CODE_DIR}" ]] || { echo "${USAGE}"; exit 1; };

#Core Logic
echo "Switching into code directory";
pushd ./${CODE_DIR}/
git clean -fd && \
git reset --hard HEAD && \
git pull;
echo "Completed updating to latest code";
popd;
\cp config.js ./${CODE_DIR}/;
\cp *.sh ./${CODE_DIR}/;
\rm ./${CODE_DIR}/${THIS_SCRIPT_FILE_NAME};
echo "Completed configuring code w.r.to local environment";

exit 0;
