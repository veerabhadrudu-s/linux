: <<BLK_CMT
This script will import service template into icinga-director module using input csv file.
At present service_name,check_command,check_interval_in_seconds,retry_interval_in_seconds,max_check_attempts,enable_active_checks,enable_passive_checks,enable_notifications,enable_event_handler,enable_perfdata,enable_flapping,volatile,[vars.key,vars.value]+ ordered mandatory csv parameters should be present in the input file.
BLK_CMT

function create_service_json_tmplt_without_vars() {
	printf "{ \"object_type\" : \"template\" ,\"check_command\" : \"$1\" ,\"check_interval\" : $2,\"retry_interval\" : $3,\"max_check_attempts\" : $4,\"enable_active_checks\" : $5,\"enable_passive_checks\" : $6,\"enable_notifications\" : $7,\"enable_event_handler\" : $8,\"enable_perfdata\" : $9,\"enable_flapping\" : ${10},\"volatile\" : ${11} }" ;
}

function create_service_json_tmplt_with_vars() {
	printf "{ \"object_type\" : \"template\" ,\"check_command\" : \"$1\" ,\"check_interval\" : $2,\"retry_interval\" : $3,\"max_check_attempts\" : $4,\"enable_active_checks\" : $5,\"enable_passive_checks\" : $6,\"enable_notifications\" : $7,\"enable_event_handler\" : $8,\"enable_perfdata\" : $9,\"enable_flapping\" : ${10},\"volatile\" : ${11}, \"vars\" : { "${12}" } }" ;
}


function create_service_tmplts() {

        local -a CSV_ROWS;
	local MANDTRY_COL_CNT=12 CSV_ROW SERVICE_VARS_KEY_VALUE_PAIRS JSON;
	local USAGE="Usage $0 <service_template.csv>";
#	local USAGE="Usage ${FUNCNAME[0]} <service_template.csv>";

        [[ -z "$1" ]] && { echo "$USAGE"; exit 1; };
	[[ -f "$1" ]] || { echo "Input Service Template file - $1 doesn't exit or it might not be a regular file"; exit 2; };	

        mapfile CSV_ROWS < "$1";
        for((i=0;i<${#CSV_ROWS[@]};i++))
        do
	        CSV_ROW=${CSV_ROWS[i]};
                CSV_ROW=${CSV_ROW//[$'\r\n']};
#               printf "${CSV_ROW}";
                IFS=',' read -r -a SRVC_TOKNS <<< "$CSV_ROW";
#               echo "${SRVC_TOKNS[@]}";
		[[ "${#SRVC_TOKNS[@]}" -lt "$MANDTRY_COL_CNT" ]] && \
	        { echo "Skipping ROW NUM $((i+1)) due to lesser column count than mandatory column count of ${MANDTRY_COL_CNT}."; continue; };
		[[ $(( ( ${#SRVC_TOKNS[@]} - $MANDTRY_COL_CNT ) % 2 )) -eq 1 ]] && \
		{ echo "Skipping Service Template with name ${SRVC_TOKNS[0]} at ROW NUM $((i+1)) which has odd number of VARS KEY-VALUE PAIR."; continue; };
		if [[ "${#SRVC_TOKNS[@]}" -gt "$MANDTRY_COL_CNT" ]] ; then
	                SERVICE_VARS_KEY_VALUE_PAIRS="${SRVC_TOKNS[@]:${MANDTRY_COL_CNT}:$(( ${#SRVC_TOKNS[@]} - 1 ))}";
		        SERVICE_VARS_KEY_VALUE_PAIRS="$( printf "${SERVICE_VARS_KEY_VALUE_PAIRS}" | awk '{ printf "\""; for(i=1;i<=NF;i++) { printf $i; if( i%2 == 1) printf "\":\""; else if(i!=NF) printf "\",\"" ; } printf "\"";}' )";
			JSON=$( create_service_json_tmplt_with_vars ${SRVC_TOKNS[1]} ${SRVC_TOKNS[2]} ${SRVC_TOKNS[3]} ${SRVC_TOKNS[4]} ${SRVC_TOKNS[5]} ${SRVC_TOKNS[6]} ${SRVC_TOKNS[7]} ${SRVC_TOKNS[8]} ${SRVC_TOKNS[9]} ${SRVC_TOKNS[10]} ${SRVC_TOKNS[11]} "${SERVICE_VARS_KEY_VALUE_PAIRS}" ) ;
		else
			JSON=$( create_service_json_tmplt_without_vars ${SRVC_TOKNS[1]} ${SRVC_TOKNS[2]} ${SRVC_TOKNS[3]} ${SRVC_TOKNS[4]} ${SRVC_TOKNS[5]} ${SRVC_TOKNS[6]} ${SRVC_TOKNS[7]} ${SRVC_TOKNS[8]} ${SRVC_TOKNS[9]} ${SRVC_TOKNS[10]} ${SRVC_TOKNS[11]} ) ;
		fi;

#	       printf "${SRVC_TOKNS[0]} --json $JSON\n\n";
               icingacli director service create "${SRVC_TOKNS[0]}" --json "$JSON" || \
               printf "Failed to create service template with name ${SRVC_TOKNS[0]} at ROW NUMBER $((i+1)) from input csv \n";

        done;
	unset -v SRVC_TOKNS;
	return 0;
}


