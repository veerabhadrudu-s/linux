#!/usr/bin/bash
: <<BOC 
This script will download the redis source code,makes the binaries from source code and configures redis in cluster mode.
This script configures Redis cluster in same host with cluster nodes listening on different ports
This script by default configures same password for all cluster nodes.
This script configures by default to listen on all interfaces(0.0.0.0) for all cluster nodes.
BOC

source ../subroutines/configure_redis_server_sub.sh
USAGE="Usage: $0 <redis_cluster_starting_port-redis_cluster_ending_port> <password> <cluster-replicas> <host_ip_address>";
REDIS_START_PORT=${1%-*};
REDIS_END_PORT=${1#*-};
CLUSTER_NODES="";

[[ -z "$1" || -z "$2" || -z "$3" || -z "$4" ]] && { printf "${USAGE}\n"; exit 1; };
printf "$1" | egrep -v "^[1-9][0-9]{0,4}-[1-9][0-9]{0,4}$" &>/dev/null  && \
{ printf "Starting and ending port syntax is \"starting_port_number-ending_port_number\" \n"; exit 1; };
[[ ${REDIS_START_PORT} -ge ${REDIS_END_PORT} ]] && { printf "Starting port can't be grater than or equal to end port \n"; exit 1; };
printf "$3" | egrep -v "^[1-9]$" &>/dev/null && { printf "cluster-replicas should be single digit integer between 1-9\n"; exit 1; };
printf "$4" | egrep -v "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$" &>/dev/null && { printf "Invalid redis master ip address\n"; exit 1;};
TOTAL_PORTS=$(( (REDIS_END_PORT + 1) - REDIS_START_PORT ));
MASTER_REPLICA_COUNT=$(( $3 +1 ));
[[ ${MASTER_REPLICA_COUNT} -ge ${TOTAL_PORTS} ]] && { printf "Master replicas count (1 Master + cluster-replicas count ) can't be grater than or equal to total port count \n"; exit 1; };
[[ $(( TOTAL_PORTS  %  MASTER_REPLICA_COUNT )) -eq "0" ]] || \
{ printf "Make sure to provide proper cluster replicas count with respect to port range.\nMaster replicas count (1 Master + input cluster-replicas count ) should arithmetically divide input port range - $TOTAL_PORTS.\n"; exit 1; };


makeRedisByDownloading;
#Code to configure Redis Cluster Nodes.
for PORT in $( eval echo "{${REDIS_START_PORT}..${REDIS_END_PORT}}") ;do
	configureRedisClusterNode "$PORT" "$2"; 
	CLUSTER_NODES=${CLUSTER_NODES}"$4:$PORT ";
done
cleanRedisWorkDirectory;

printf "Cluster Nodes are ${CLUSTER_NODES}\n";
printf "yes\n" | redis-cli -a "$2" --cluster create ${CLUSTER_NODES} --cluster-replicas "$3";

exit 0;

