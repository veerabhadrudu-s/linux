#!/usr/bin/bash
: <<BOC 
This script will insert key-value data into redis cluster using input range.
Following high level steps are happening in the script.
-> In generateRedisInsertScrip function ,we are preparing all insert key operations(Redis SET commands) in one shot.
-> Above generated script string is fed to executeRedisCliScript function.This function uses redis-cli command using HERE documenti and inserts data. 
-> redis-cli fails to insert input key due to hash key slot migration/MOVED. In such cases as result of failure, redis-cli provides migrated hash key slot and cluster master node holding that slot (which includes IP and port info of master). Redis hash key slots are internally used by Redis cluster to manage distributed data in the cluster. This is not to be confused with input keys we are inserting.For more info on this study redis cluster documentation).
-> Result of executeRedisCliScript function is fed to identifyMovedKeySlotsInTheClusterNodes function. This function segregates input keys according to master nodes in which input keys has to be inserted.
-> Finally, we are inserting keys using bulk insert script (already created script in identifyMovedKeySlotsInTheClusterNodes function) in each master cluster node and verifying total inserted key count.
BOC

: <<BOC
In below function,awk command identifies insertion failed keys in the cluster with respect to present connected cluster node and generated bulk insert script w.r.to each master.
After identifing an failed key using 'MOVED' regex , we are appending that failed key ( key from previous line which was echoed in redis script) to a array index who's index value is equal to cluster node instance(ip_address:port).
Here in key appending step it self, we are appending it as REDIS SET command.This way it saves us writing logic to parse all keys with respect to each IP(cluster instance) and create set commands for each instance of redis master cluster node.
In below Awk comamnd , we are using switch statement and Assosiative Arrays(which works like hashmap).
To understand this logic clearly , observe the input to below awk program by uncommenting print statement in function and then check awk program logic.
BOC
function identifyMovedKeySlotsInTheClusterNodes(){
	#printf "${1}\n";
	printf "${1}" | \
	awk '
		{
			switch ($1) {
			   case /^[0-9]+$/ :
			      FAILED_KEY_TO_INSERT=$1;
			      break;
			   case /MOVED/ :
			      MOVED_KEYS[$3]=MOVED_KEYS[$3]"SET "FAILED_KEY_TO_INSERT" "FAILED_KEY_TO_INSERT"\\n";
			      break;
			}
		}
		END { for(REDIS_INSTANCE in MOVED_KEYS){ print REDIS_INSTANCE " " MOVED_KEYS[REDIS_INSTANCE]; } }
	';

} 

: <<BOC
Here in below function, we are using eval command to dinamically expand the input key range to be inserted.
We are echoing(Redis echo command) for each key before inserting, this is need to identify migrated hash key slots in case of input keys are failed to get inserted in currently connected redis cluster node.
BOC
function generateRedisInsertScript(){
	#eval echo "{$1..$2}";
	local REDIS_INSERT_SCRIPT;
	for VAL in $(eval echo "{$1..$2}");
	do 
		REDIS_INSERT_SCRIPT=${REDIS_INSERT_SCRIPT}"ECHO $VAL"$'\n'"SET $VAL $VAL"$'\n';
	done;
	printf "${REDIS_INSERT_SCRIPT}";
}

function findInsertedKeyCountInClusterNode(){
	printf "${1}" | awk 'BEGIN { INSERTED_COUNT=0; } $1 ~ /OK/{ INSERTED_COUNT++; } END { print INSERTED_COUNT; }';
}

function executeRedisCliScript(){
	redis-cli -h "$1" -p "$2" -a "$3" 2>/dev/null <<-HEREDOC
	${4}
	HEREDOC
}

function performValidation(){
	local USAGE="Usage: $0 <ip_address> <port> <password> <start_range> <end_range>";
	[[ -z  "$1" || -z "$2" || -z "$3" || -z "$4" || -z "$5" ]] && { printf "${USAGE}\n"; exit 1; };
	{ printf "$4" | egrep "^[0-9]+$" &>/dev/null && printf "$5" | egrep "^[0-9]+$" &>/dev/null ; } || \
	{ printf "Start Range and End Range should be numeric.\n"; exit 2; };
	[[ "$4" -gt "$5" ]] && { printf "Start Range can't be grater than End Range.\n"; exit 3; };
	type redis-cli &>/dev/null || { printf "Redis-cli not installed on this host\n"; exit 1; };
	redis-cli -h "$1" -p "$2" -a "$3" PING 2>&1 | grep "PONG" &>/dev/null || \
	{ printf "Invalid Redis IP Address,Port and Password combination (OR) Server might not be reachable.\n"; exit 4; };
	redis-cli -h "$1" -p "$2" -a "$3" cluster info 2>/dev/null | awk -F ':' '/cluster_state/ { if ( toupper($2) ~ /OK/ ) exit 0; else exit 1; } ' || \
	{ printf "Cluster is in down state at present.Please make sure cluster is running and operational.\n"; exit 1; }; 
}

######## Main Program Starts #########

declare -A INSERTED_KEYS_COUNT_IN_CLUSTER;
declare -i TOTAL_INSERTED_KEYS=0;

performValidation "$1" "$2" "$3" "$4" "$5";
REDIS_INSERT_SCRIPT=$( generateRedisInsertScript "$4" "$5" );
#printf "${REDIS_INSERT_SCRIPT}";
RESULT=$( executeRedisCliScript "$1" "$2" "$3" "${REDIS_INSERT_SCRIPT}" );
RESULT=$(printf "${RESULT}" | grep -v '^ *$');
INSERTED_KEY_COUNT=$( findInsertedKeyCountInClusterNode "${RESULT}" );
[[ ${INSERTED_KEY_COUNT} -eq 0 ]] && printf "We have connected to slave node. All keys will be inserted in master nodes.\n" || \
{ INSERTED_KEYS_COUNT_IN_CLUSTER["$1:$2"]=${INSERTED_KEY_COUNT}; };
MOVED_KEYS_IN_CLUSTER=$(identifyMovedKeySlotsInTheClusterNodes "${RESULT}");
#echo "$MOVED_KEYS_IN_CLUSTER";
#IFS=$'\n' read -a MOVED_KEYS_IN_CLUSTER_ARR <<< "${MOVED_KEYS_IN_CLUSTER}";
mapfile MOVED_KEYS_IN_CLUSTER_ARR <<< "${MOVED_KEYS_IN_CLUSTER}";
for((i=0;i<${#MOVED_KEYS_IN_CLUSTER_ARR[@]};i++));
do
	CLUSTER_MASTER_NODE=${MOVED_KEYS_IN_CLUSTER_ARR[$i]%% *};
	MASTER_CLUSER_INSERT_SCRIPT=${MOVED_KEYS_IN_CLUSTER_ARR[$i]#* };
	#echo "Keys to be inserted in the master - ${CLUSTER_MASTER_NODE} is - ${MASTER_CLUSER_INSERT_SCRIPT}";
	MASTER_CLUSER_INSERT_SCRIPT=${MASTER_CLUSER_INSERT_SCRIPT//"\n"/$'\n'};
	RESULT=$( executeRedisCliScript "${CLUSTER_MASTER_NODE%:*}" "${CLUSTER_MASTER_NODE#*:}" "$3" "${MASTER_CLUSER_INSERT_SCRIPT}" );
	INSERTED_KEYS_COUNT_IN_CLUSTER["${CLUSTER_MASTER_NODE}"]=$( findInsertedKeyCountInClusterNode "${RESULT}");
	#printf "${RESULT}\n";
done

printf "Report of Total Inserted keys in the cluster - \n";
for CLUSTER_NODE in ${!INSERTED_KEYS_COUNT_IN_CLUSTER[@]}; do
	printf "Cluster Node - ${CLUSTER_NODE} inserted key count - ${INSERTED_KEYS_COUNT_IN_CLUSTER[${CLUSTER_NODE}]}\n";
	TOTAL_INSERTED_KEYS+=${INSERTED_KEYS_COUNT_IN_CLUSTER[${CLUSTER_NODE}]};
done

[[ "${TOTAL_INSERTED_KEYS}" -eq $(( ($5 - $4) + 1  )) ]] || { printf "Inserted count is ${TOTAL_INSERTED_KEYS} but actaul keys to be is $(( $5 - $4 ))\n"; exit 5;  };
printf "Total inserted keys is ${TOTAL_INSERTED_KEYS}\n" && exit 0;

