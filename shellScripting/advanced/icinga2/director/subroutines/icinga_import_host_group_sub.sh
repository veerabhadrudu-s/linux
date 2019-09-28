: <<BLK_CMT
This script will import host groups into icinga-director module using input csv file.
At present only single column host_group_name csv parameters should be present in the input file.
LIMITATION:- Assign filters to host group is not supported.
BLK_CMT

function create_host_groups() {

        local -a HOST_GROUP_NAMES;
	local HOST_GROUP_NAME;
	local USAGE="Usage $0 <host_groups.csv>";
#	local USAGE="Usage ${FUNCNAME[0]} <host_groups.csv>";

        [[ -z "$1" ]] && { echo "$USAGE"; exit 1; };
        [[ -f "$1" ]] || { echo "Input Host Groups file - $1 doesn't exit or it might not be a regular file"; exit 2; };

        mapfile HOST_GROUP_NAMES < "$1";
        for((i=0;i<${#HOST_GROUP_NAMES[@]};i++))
        do
                HOST_GROUP_NAME=${HOST_GROUP_NAMES[i]};
		HOST_GROUP_NAME=${HOST_GROUP_NAME//[$'\r\n']};
#		printf "${HOST_GROUP_NAME}" | od -An -vtu1; 
                [[ -n "${HOST_GROUP_NAME}" ]] && { icingacli director hostgroup create "${HOST_GROUP_NAME}" --json "{ \"display_name\" : \"${HOST_GROUP_NAME}\" }" || printf "Failed to create host group with name ${HOST_GROUP_NAME} at ROW VALUE $((i+1)) from input csv \n"; };

        done;
	return 0;
}

