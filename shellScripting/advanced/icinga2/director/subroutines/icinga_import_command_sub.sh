: <<BLK_CMT
This script will import commands into icinga-director module using input csv file.
At present command_name,command_type,timeout_in_seconds,command[,option_1,...option_n] ordered mandatory csv parameters should be present in the input file.
If option values has "," character, Use double quotes around option value to escape comma character.
BLK_CMT

# Below instruction imports common subroutine file using shell in built variable BASH_SOURCE.This array variable holds values related source command.
# We are using this approach because this script file can be imported in another file.In such cases , we have to import common subroutines module based on caller path of this file.
source $(dirname "${BASH_SOURCE[0]}")/icinga_common_subroutines.sh;


function create_commands() {

        local -a CSV_ROWS COMMAND_VALUES_ARR;
	local MANDTRY_COL_CNT=4 CSV_ROW COMMAND_NAME COMMAND_VALUES;
	local USAGE="Usage $0 <command_config.csv>";
#	local USAGE="Usage ${FUNCNAME[0]} <command_config.csv>";

        [[ -z "$1" ]] && { echo "$USAGE"; exit 1; };
        [[ -f "$1" ]] || { echo "Input Command Template file - $1 doesn't exit or it might not be a regular file"; exit 2; };

        mapfile CSV_ROWS < "$1";
        for((i=0;i<${#CSV_ROWS[@]};i++))
        do
                CSV_ROW=${CSV_ROWS[i]};
                CSV_ROW=${CSV_ROW//[$'\r\n']};
#               printf "${CSV_ROW}";
                IFS=',' read -r -a COMMAND_TOKENS <<< "$CSV_ROW";
                [[ "${#COMMAND_TOKENS[@]}" -lt "${MANDTRY_COL_CNT}" ]] && { echo "Skipping ROW NUM $((i+1)) due to lesser column count than mandatory column count of ${MANDTRY_COL_CNT}."; continue; };
#               echo "${COMMAND_TOKENS[@]}";
                COMMAND_NAME=${COMMAND_TOKENS[0]};
		COMMAND_VALUES_ARR=( ${COMMAND_TOKENS[@]:$(( ${MANDTRY_COL_CNT} - 1 )):$(( ${#COMMAND_TOKENS[@]} - 1 ))} );
#		printf "${COMMAND_VALUES_ARR[*]}\n";
                COMMAND_VALUES="$( restructureArgsUsingDoubleQuotesEscapeChar ${COMMAND_VALUES_ARR[@]} )";
                COMMAND_VALUES="\""${COMMAND_VALUES// /\",\"}"\"";
#               printf  "{ \"methods_execute\" : \"${COMMAND_TOKENS[1]}\" , \"command\" : [ $COMMAND_VALUES ] , \"timeout\" : ${COMMAND_TOKENS[2]:-60} }\n"
                icingacli director command create "$COMMAND_NAME" --json "{ \"methods_execute\" : \"${COMMAND_TOKENS[1]}\" , \"command\" : [ ${COMMAND_VALUES} ] , \"timeout\" : ${COMMAND_TOKENS[2]:-60} }" || \
                printf "Failed to create command with name $COMMAND_NAME at ROW VALUE $((i+1)) from input csv \n";

        done;
	unset -v COMMAND_TOKENS;
	return 0;
}

