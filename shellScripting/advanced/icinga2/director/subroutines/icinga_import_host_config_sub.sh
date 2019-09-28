: <<BLK_CMT
This script will import host configuration into icinga-director module using input csv file.
At present host_name,host_ip_address,check_command,:[,host_template]+,:[,service_template]+,:[,vars.key,vars.value]+ ordered mandatory csv parameters should be present in the input file. Atleast check_command or one host_template should be present.
In this script, we are using 2 separators :(colon) and ,(comma). Colon is high level seperator of row and comma is next level seperator after applying colon separator.
That means each row is splitted using colon separator and then colon splitted strings are further splitted using comma seperator to get individual tokens. This appraoch is taken because each row can have multiple host_templates,service_templates and vars key-value pair , using just comma separator we can't identfify indivdual sections in the row.
BLK_CMT

# Below instruction imports common subroutine file using shell in built variable BASH_SOURCE.This array variable holds values related source command.
# We are using this approach because this script file can be imported in another file.In such cases , we have to import common subroutines module based on caller path of this file. 
source $(dirname "${BASH_SOURCE[0]}")/icinga_common_subroutines.sh;

function generateVarsJSON() {
	
	[[ $# -eq 0 ]] && { printf ""; return 0; };

	local NEW_VARS_STRING="$( restructureArgsUsingDoubleQuotesEscapeChar $@ )"; 
        local -a NEW_VARS_ARGS=( ${NEW_VARS_STRING} );
#       printf "NEW VARS ARGS Length is - ${#NEW_VARS_ARGS[@]}\n";
        # Below condition checks for length of restructured arguments as odd number.If it's odd number it returns empty string.
        [[ $(( ${#NEW_VARS_ARGS[@]} % 2 )) -eq 1 ]] && { printf ""; return 1; }; 
	# Below code creates json string using re-structured vars key-values string.
	local VARS_JSON=$( printf "${NEW_VARS_STRING}" | awk 'BEGIN { VARS_JSON=""; } { VARS_JSON="{ \""; for(i=1;i<=NF;i++){ VARS_JSON=VARS_JSON$i;  if(i%2==1) VARS_JSON=VARS_JSON"\":\""; else if(i!=NF) VARS_JSON=VARS_JSON"\",\"";  }  } END{ VARS_JSON=VARS_JSON"\" }"; printf VARS_JSON"\n"; }' );
	printf "\"vars\": ${VARS_JSON}" && return 0;
}


function create_hosts(){

        local -a CSV_ROWS;
        local MANDTRY_COL_CNT=3  SPCIAL_SEPRTR=":";
	local i CSV_ROW SERVICE_VARS_KEY_VALUE_PAIRS JSON VARS_JSON HOST_JSON SRVC_TMPLT;
        local USAGE="Usage $0 <host_config.csv>";
	local FORMAT_SYNTAX="host_name,host_ip_address,check_command,:[,host_template]+,:[,service_template]+,:[,vars.key,vars.value]+ ordered mandatory csv parameters should be present in the $1 input file"; 

        [[ -z "$1" ]] && { echo "$USAGE"; exit 1; };
        [[ -f "$1" ]] || { echo "Input Host Config file - $1 doesn't exit or it might not be a regular file"; exit 2; };

        mapfile CSV_ROWS < "$1";
        for((i=0;i<${#CSV_ROWS[@]};i++))
        do
                CSV_ROW=${CSV_ROWS[i]};
                CSV_ROW=${CSV_ROW//[$'\r\n']};
#               printf "Input CSV ROW - ${CSV_ROW}\n";
		IFS="${SPCIAL_SEPRTR}" read -r -a MANDRY_TOKNS_USNG_SPEC_SEP <<< "$CSV_ROW";
		IFS=',' read -r -a MANDRY_COLMNS <<< "${MANDRY_TOKNS_USNG_SPEC_SEP[0]}";
		IFS=',' read -r -a SRVC_TEMPLTS <<< "${MANDRY_TOKNS_USNG_SPEC_SEP[2]}";
		IFS=',' read -r -a VARS_KEY_VALUES <<< "${MANDRY_TOKNS_USNG_SPEC_SEP[3]}";
#		for TKN in ${MANDRY_TOKNS_USNG_SPEC_SEP[@]} ;do printf "ROW Number $i Token using special separator $SPCIAL_SEPRTR  ${TKN}\n"; done;
              	# Below Validation First checks for existense of mandatory column count ,If count don't exists it skips that row.
		# If column count exist , it looks for existance of atleast check_command or one host_template.
                { [[ "${#MANDRY_COLMNS[@]}" -lt "$MANDTRY_COL_CNT" ]] || { { [[ -z ${MANDRY_COLMNS[2]} ]] || printf "${MANDRY_COLMNS[2]}" | egrep "^ *$" &>/dev/null; } && printf "${MANDRY_TOKNS_USNG_SPEC_SEP[1]}" | egrep '^ *, *$' &>/dev/null; }; } && \
                { echo "Skipping ROW NUM $((i+1)). Please check the Format Syntax - ${FORMAT_SYNTAX}"; continue; };
#		printf "\${MANDRY_COLMNS[2]} value is "; printf "${MANDRY_COLMNS[2]}" | od -An -vtu1;
#		printf "\${MANDRY_TOKNS_USNG_SPEC_SEP[1]} value is "; printf "${MANDRY_TOKNS_USNG_SPEC_SEP[1]}" | od -An -vtu1;printf "\n";
#		printf "VALID ROW $((i+1))\n";
		VARS_JSON=$( generateVarsJSON ${VARS_KEY_VALUES[@]} ) || { printf "Skipping ROW NUM $((i+1)) due to odd number of vars key-pair count.\n"; continue; };
		HOST_JSON="{\"address\" : \"${MANDRY_COLMNS[1]}\"";

		[[ -n ${MANDRY_COLMNS[2]} ]] && printf "${MANDRY_COLMNS[2]}" | egrep -v "^ *$" &>/dev/null && { HOST_JSON="${HOST_JSON} , \"check_command\" : \"${MANDRY_COLMNS[2]}\""; };
		#Code for Importing Host Templates from input row.
		[[ -n ${MANDRY_TOKNS_USNG_SPEC_SEP[1]} ]] && printf "${MANDRY_TOKNS_USNG_SPEC_SEP[1]}" | egrep -v "^ *$" &>/dev/null && \
		{
			MANDRY_TOKNS_USNG_SPEC_SEP[1]=${MANDRY_TOKNS_USNG_SPEC_SEP[1]#,};
			MANDRY_TOKNS_USNG_SPEC_SEP[1]=${MANDRY_TOKNS_USNG_SPEC_SEP[1]%,};
			HOST_JSON="${HOST_JSON} , \"imports\" : [ \"${MANDRY_TOKNS_USNG_SPEC_SEP[1]//,/\",\"}\" ]";
		};
		[[ -n ${VARS_JSON} ]] && { HOST_JSON="${HOST_JSON} , ${VARS_JSON} "; }; 
		HOST_JSON=${HOST_JSON}" }";
#		printf	"icingacli director host create ${MANDRY_COLMNS[0]} --json ${HOST_JSON}\n";
		icingacli director host create "${MANDRY_COLMNS[0]}" --json "${HOST_JSON}" || \
		{ printf "Failed to create host with name ${MANDRY_COLMNS[0]} at ROW NUMBER $((i+1)) from input csv \n"; continue; };
		#Code for creating services for newly created host.
		for SRVC_TMPLT in ${SRVC_TEMPLTS[@]} 
		do
			printf "${SRVC_TMPLT}" | egrep -v "^ *$" &>/dev/null &&	\
			{ 
			icingacli director service create "${SRVC_TMPLT}" --json "{ \"host_name\" : \"${MANDRY_COLMNS[0]}\" , \"imports\" : [ \"${SRVC_TMPLT}\" ] }" || \
			printf "Failed to attach service template ${SRVC_TMPLT} to host ${MANDRY_COLMNS[0]} at ROW NUMBER $((i+1))";
			};
		done;

		printf "Processing ROW $((i+1)) completed successfully.\n\n";
        done;
        unset -v  MANDRY_COLMNS SRVC_TEMPLTS VARS_KEY_VALUES MANDRY_TOKNS_USNG_SPEC_SEP;
        return 0;
}

