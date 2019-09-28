: <<BLK_CMT
This script will import host templates into icinga-director module using input csv file.
At present host_template_name,check_command,group_name[,service_temlate_name]+ ordered mandatory csv parameters should be present in the input file.
LIMITATION:- At present this script support's only one group assignment to host template.
BLK_CMT


function create_host_templates() {

        local -a CSV_ROWS SRVC_TEMPLTS=();
        local MANDTRY_COL_CNT=3 CSV_ROW HOST_TMPLT_NAME HOST_JSON i j;
        local USAGE="Usage $0 <host_template.csv>";
#       local USAGE="Usage ${FUNCNAME[0]} <host_template.csv>";

        [[ -z "$1" ]] && { echo "$USAGE"; exit 1; };
        [[ -f "$1" ]] || { echo "Input Host Template file - $1 doesn't exit or it might not be a regular file"; exit 2; };

        mapfile CSV_ROWS < "$1";
        for((i=0;i<${#CSV_ROWS[@]};i++)) ; do

                CSV_ROW=${CSV_ROWS[i]};
                CSV_ROW=${CSV_ROW//[$'\r\n']};
#               printf "ROW NUM $((i+1))- ${CSV_ROW}\n";
                IFS=',' read -r -a TOKENS <<< "$CSV_ROW";
                [[ "${#TOKENS[@]}" -lt "${MANDTRY_COL_CNT}" ]] && { echo "Skipping ROW NUM $((i+1)) due to lesser column count than mandatory column count of ${MANDTRY_COL_CNT}."; continue; };
#               echo "${TOKENS[@]}";
                HOST_TMPLT_NAME=${TOKENS[0]};
		HOST_JSON="{ \"object_type\" : \"template\"";
		[[ -n "${TOKENS[1]}" ]] && { HOST_JSON=${HOST_JSON}",\"check_command\" : \"${TOKENS[1]}\""; };
		[[ -n "${TOKENS[2]}" ]] && { HOST_JSON=${HOST_JSON}",\"groups\" : [ \"${TOKENS[2]}\" ]"; };
		HOST_JSON=${HOST_JSON}"}";
                icingacli director host create "$HOST_TMPLT_NAME" --json "${HOST_JSON}" || \
                { printf "Failed to create host template with name $HOST_TMPLT_NAME at ROW VALUE $((i+1)) from input csv \n"; continue; };
		if [[ "${#TOKENS[@]}" -gt "${MANDTRY_COL_CNT}" ]] ; then
	                SRVC_TEMPLTS=( ${TOKENS[@]:${MANDTRY_COL_CNT}:$(( ${#TOKENS[@]} - 1 ))} );
			for ((j=0;j<${#SRVC_TEMPLTS[@]};j++)) ; do
			   icingacli director service create "${SRVC_TEMPLTS[j]}" --json "{ \"imports\" : [ \"${SRVC_TEMPLTS[j]}\" ] ,\"host\": \"${HOST_TMPLT_NAME}\" }";				
			done
		fi
        done;
        unset -v TOKENS;
        return 0;

}

