#!/usr/bin/bash
: <<BOC 
This script will download the redis source code,makes the binaries from source code and configures redis in cluster mode.
This script configures redis cluster across multiple hosts/remote machines.
This script by default configures same password for all cluster nodes.
This script configures by default to listen on all interfaces(0.0.0.0) for all servers.
BOC

source ../subroutines/configure_redis_server_sub.sh
USAGE="Usage: $0 <redis_cluster_start_ip_addr-redis_cluster_end_ip_addr> <redis_cluster_start_port> <redis_password> <cluster-replicas>";
REDIS_CONF_PATH="etc/redis";
SYSTEMD_CONF_PATH="etc/systemd/system";
REDIS_START_IP=${1%-*};
REDIS_END_IP=${1#*-};
STRTNG_IP_NODE_ID=${REDIS_START_IP##*.};
ENDING_IP_NODE_ID=${REDIS_END_IP##*.};
TMP_TAR_FILE="tmp.gz.tar";
FIREWALLD_CMDS="";
SYSTEM_CTL_CMDS=""
MKDIR_CMDS="";
CLUSTER_NODES_SED=""
CLUSTER_NODES="";


[[ -z "$1" || -z "$2" || -z "$3" || -z "$4" ]] && { printf "${USAGE}\n"; exit 1; };
printf "$1" | egrep -v "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}-[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$" &>/dev/null  && \
{ printf "Invalid start and end ip address syntax.Example of starting and ending ip address syntax is \"192.168.190.115-192.168.190.120\" \n"; exit 1; };
[[ ${REDIS_START_IP%.*} = ${REDIS_END_IP%.*} ]] || { printf "Starting ip address subnet should be same as ending ip address subnet \n"; exit 1; };
[[ ${STRTNG_IP_NODE_ID} -ge ${ENDING_IP_NODE_ID} ]] && { printf "Starting ip address node id - ${REDIS_START_IP##*.} can't be grater than or equal to ending ip address node id - ${REDIS_END_IP##*.} \n"; exit 1; };
printf "$2" | egrep -v "^[1-9][0-9]{0,4}$" &>/dev/null && { printf "Invalid Redis cluster start port $2\n"; exit 1; };
printf "$4" | egrep -v "^[1-9]$" &>/dev/null && { printf "cluster-replicas should be single digit integer between 1-9\n"; exit 1; };
CLUSTER_NODE_COUNT=$(( (ENDING_IP_NODE_ID + 1) - STRTNG_IP_NODE_ID ));
MASTER_REPLICA_COUNT=$(( $4 +1 ));
printf "This script configures redis cluster with total instances count of $(( CLUSTER_NODE_COUNT * MASTER_REPLICA_COUNT ))\n";
printf "All these redis cluster node instances are equally distributed between input ip address range $1 with each ip address having ${MASTER_REPLICA_COUNT} instances\n";
printf "In each ip address cluster nodes will be started and they will listen between port range $2-$(( $2 + $4 ))\n";
printf "Make sure to have ssh connectivity between current host and all hosts using public key\n";
read -p "Would you like to continue [y/n]:" YES_OR_NO;
[[ ${YES_OR_NO} = "y" || ${YES_OR_NO} = "Y" ]] || { printf "Stoping configuration as per your request \n"; exit 1; };

for IP_ADDRESS in $( eval echo "${REDIS_START_IP%.*}.{${STRTNG_IP_NODE_ID}..${ENDING_IP_NODE_ID}}" ); do
	ssh $(whoami)@${IP_ADDRESS} exit &>/dev/null || { printf "${IP_ADDRESS} not reachable\n"; exit 1; }; 
done

mkdir -p "${REDIS_CONF_PATH}";
mkdir -p "${SYSTEMD_CONF_PATH}";
#Code to configure Redis Cluster Nodes.
: <<BOC
We are configuring redis cluster node with 2 ports enabled. first port is for general client communication and 2nd port is for cluster communication between nodes.Cluster port is always 10000 offset with respect general port,this is according to redis specification.So,we are opening cluster port also in the firewall.
BOC
for PORT in $( eval echo "{$2..$(( $2 + $4))}" ); do 
	cp cluster_template.conf ${REDIS_CONF_PATH}/cluster_${PORT}.conf && \
	cp redis_cluster_template.service ${SYSTEMD_CONF_PATH}/redis_cluster_${PORT}.service && \
	sed -i -e 's/^port 6379/port '"${PORT}"'/g' ${REDIS_CONF_PATH}/cluster_${PORT}.conf && \
	sed -i -e 's/^# requirepass foobared/requirepass '"$3"'/g' ${REDIS_CONF_PATH}/cluster_${PORT}.conf && \
	sed -i -e 's/^# masterauth <master-password>/masterauth '"$3"'/g' ${REDIS_CONF_PATH}/cluster_${PORT}.conf && \
	sed -i -e 's:^pidfile /var/run/redis_6379.pid:pidfile /var/run/redis_'"${PORT}"'.pid:g' ${REDIS_CONF_PATH}/cluster_${PORT}.conf && \
	sed -i -e 's:^logfile /var/log/redis_6379.log:logfile /var/log/redis_'"${PORT}"'.log:g' ${REDIS_CONF_PATH}/cluster_${PORT}.conf && \
	sed -i -e 's:^dir /var/lib/redis/6379:dir /var/lib/redis/'"${PORT}"':g' ${REDIS_CONF_PATH}/cluster_${PORT}.conf && \
        sed -i -e 's/^# cluster-enabled yes/cluster-enabled yes/g' ${REDIS_CONF_PATH}/cluster_${PORT}.conf && \
        sed -i -e 's:^# cluster-config-file nodes-6379.conf:cluster-config-file '"/etc/redis/cluster_nodes_${PORT}.conf"':g' ${REDIS_CONF_PATH}/cluster_${PORT}.conf && \
        sed -i -e 's/^# cluster-node-timeout 15000/cluster-node-timeout 10000/g' ${REDIS_CONF_PATH}/cluster_${PORT}.conf && \
	sed -i -e 's/__PORT__/'"${PORT}"'/g' ${SYSTEMD_CONF_PATH}/redis_cluster_${PORT}.service;
	FIREWALLD_CMDS=${FIREWALLD_CMDS}"firewall-cmd --add-port=${PORT}/tcp && firewall-cmd --add-port=${PORT}/tcp --permanent && firewall-cmd --add-port=$((PORT+10000))/tcp && firewall-cmd --add-port=$((PORT+10000))/tcp --permanent && ";
	MKDIR_CMDS=${MKDIR_CMDS}"mkdir -p /var/lib/redis/${PORT} && "
	SYSTEM_CTL_CMDS=${SYSTEM_CTL_CMDS}"systemctl enable redis_cluster_${PORT}.service && systemctl restart redis_cluster_${PORT}.service && "
	CLUSTER_NODES_SED=${CLUSTER_NODES_SED}"IP_ADD:${PORT} ";
done
FIREWALLD_CMDS=${FIREWALLD_CMDS%&&*};
MKDIR_CMDS=${MKDIR_CMDS%&&*};
SYSTEM_CTL_CMDS=${SYSTEM_CTL_CMDS%&&*};

makeRedisByDownloading && cleanRedisWorkDirectory;
tar -czf ${TMP_TAR_FILE} /usr/local/bin/ etc/;

for IP_ADDRESS in $( eval echo "${REDIS_START_IP%.*}.{${STRTNG_IP_NODE_ID}..${ENDING_IP_NODE_ID}}" ); do
#	printf "scp ${TMP_TAR_FILE} $(whoami)@${IP_ADDRESS}:/tmp/ && ssh $(whoami)@${IP_ADDRESS} \"tar -xzvf /tmp/${TMP_TAR_FILE} -C / && rm -f /tmp/${TMP_TAR_FILE} && ${MKDIR_CMDS} && ${SYSTEM_CTL_CMDS} && ${FIREWALLD_CMDS}; \"\n\n";
	scp ${TMP_TAR_FILE} $(whoami)@${IP_ADDRESS}:/tmp/ && ssh $(whoami)@${IP_ADDRESS} "tar -xzvf /tmp/${TMP_TAR_FILE} -C / && rm -f /tmp/${TMP_TAR_FILE} && ${MKDIR_CMDS} && ${SYSTEM_CTL_CMDS} && ${FIREWALLD_CMDS}; ";
	CLUSTER_NODES="${CLUSTER_NODES}"$( printf "${CLUSTER_NODES_SED}" | sed  -n -e 's/IP_ADD/'"${IP_ADDRESS}"'/g p' )" ";
done
rm -fR ${TMP_TAR_FILE} etc/;
printf "Sleeping 3 seconds to allow servers to start\n" && sleep 3; 
#printf "Cluster Nodes are ${CLUSTER_NODES}\n";
printf "yes\n" | redis-cli -a "$3" -h "${REDIS_START_IP}" -p "${2}"  --cluster create ${CLUSTER_NODES} --cluster-replicas "$4";


exit 0;

