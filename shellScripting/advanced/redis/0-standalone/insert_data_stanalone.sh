#!/usr/bin/bash
: <<BOC 
This script will insert key-value data into redis standalone server based on input arguments range.
BOC

USAGE="Usage: $0 <ip_address> <port> <password> <start_range> <end_range>";
REDIS_CMD_STR="";
[[ -z  "$1" || -z "$2" || -z "$3" || -z "$4" || -z "$5" ]] && { printf "${USAGE}\n"; exit 1; };
{ printf "$4" | egrep "^[0-9]+$" &>/dev/null && printf "$5" | egrep "^[0-9]+$" &>/dev/null ; } || { printf "Start Range and End Range should be numeric.\n"; exit 2; };
[[ "$4" -gt "$5" ]] && { printf "Start Range can't be grater than End Range.\n"; exit 3; };
redis-cli -h "$1" -p "$2" -a "$3" PING 2>&1 | grep "PONG" &>/dev/null || { printf "Invalid Redis IP Address,Port and Password combination.\n"; exit 4; };

#eval echo "{$4..$5}";

for VAL in $(eval echo "{$4..$5}");
do 
	REDIS_CMD_STR=${REDIS_CMD_STR}"SET $VAL $VAL"$'\n';
done; 
#printf "${REDIS_CMD_STR}";
RESULT=$(redis-cli -h "$1" -p "$2" -a "$3" 2>/dev/null <<HEREDOC
${REDIS_CMD_STR}
HEREDOC
);
printf "${RESULT}" | awk '$1 !~ /^OK$/ {exit 1; }'|| { printf "Failed to insert keys.Following lines are the generated logs\n${RESULT}\n"; exit 5; };
#printf "${RESULT}\n";
#printf "Redis cli exit code is $?\n";
RESULT_COUNT=$(printf "${RESULT}" | wc -l);

[[ "${RESULT_COUNT}" -eq $(( $5 - $4 )) ]] || { printf "Inserted count is ${RESULT_COUNT} but actaul keys to be is $(( $5 - $4 ))\n"; exit 5;  };
printf "Total inserted keys is ${RESULT_COUNT}\n" && exit 0;

