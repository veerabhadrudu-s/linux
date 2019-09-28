: <<BOC
This file has all the required subroutines related to redis server.
By default redis server is configured to lisen on all interfaces(0.0.0.0) , secured with password and configured ports are opened in firewall.
For Redis Master Server, we are configuring to have atleast one slave to accept write from clients(min-slaves-to-write),for more info on this refer redis doc. 
BOC

#REDIS_TAR_NAME="redis-4.0.14.tar.gz";
REDIS_TAR_NAME="redis-5.0.4.tar.gz";
REDIS_DIR="${REDIS_TAR_NAME%.tar*}";

function restartRedisService(){
#	systemctl daemon-reload && systemctl restart redis_${1}.service;
	service redis_${1} restart; 
}

function enablePortInFirewall(){
	firewall-cmd --add-port=${1}/tcp && firewall-cmd --add-port=${1}/tcp --permanent;
}

function makeRedisByDownloading(){
	local REDIS_CODE_URL="http://download.redis.io/releases/${REDIS_TAR_NAME}";
	printf "Downloading redis from URL - ${REDIS_CODE_URL}\n";
	wget "${REDIS_CODE_URL}" -O "./${REDIS_TAR_NAME}" &>/dev/null || \
	{ printf "Failed to download redis from the URL ${REDIS_CODE_URL}\n"; return 1; };
	printf "Completed downloading redis.\n";
	tar -xf ${REDIS_TAR_NAME} || { printf "Failed to extract redis ${REDIS_TAR_NAME} tar file.\n"; return 2; };
	pushd ${REDIS_DIR} >/dev/null  && make && make install;
}

function cleanRedisWorkDirectory(){
	popd >/dev/null && rm -fR ${REDIS_TAR_NAME} ${REDIS_DIR};
}
function validateRedisBasicProperties(){
	local USAGE="Usage: ${FUNCNAME[0]} <redis_port_number> <redis_password>";
	{ [[ -z "$1" || -z "$2" ]] || printf "$1" | egrep -v "^[1-9][0-9]{1,4}$" &>/dev/null; } && { printf "${USAGE}\n"; return 1; };
	return 0;
}

function configureRedisServer(){
	local REDIS_INIT_SED_CMD='s/$CLIEXEC -p $REDISPORT shutdown/$CLIEXEC -p $REDISPORT -a '"$2"' shutdown/';

	#printf "Init SED Replace Command is ${REDIS_INIT_SED_CMD}\n";
	validateRedisBasicProperties "$1" "$2" && printf "${1}\n\n\n\n\n" | utils/install_server.sh && \
	printf "requirepass ${2}\n" >>/etc/redis/${1}.conf && sed -i -e "$REDIS_INIT_SED_CMD" /etc/init.d/redis_${1} && \
	sed -i -e 's/^bind 127.0.0.1/bind 0.0.0.0/' /etc/redis/${1}.conf;  
}

function configureRedisStandaloneServer(){
	local FAILURE_MESSAGE="Failed to configure Redis Standalone Node\n";
	validateRedisBasicProperties "$1" "$2" || { printf "${FAILURE_MESSAGE}"; return 1; };
 
	makeRedisByDownloading && configureRedisServer "$1" "$2" && restartRedisService "$1" && enablePortInFirewall "$1" && \
	{ printf "Redis Standalone Node configured successfully \n"; cleanRedisWorkDirectory; return 0; } || \
	{ printf "${FAILURE_MESSAGE}"; cleanRedisWorkDirectory; return 1; };
	
}

: <<BOC
In below function "masterauth" password is configured same as it's password.This is under the assumption that all the servers in sentinel mode will have same password.
This password is used during sentinel mode.After master redis node is restarted , it will try to connect to cluster as slave, during this operation it uses this password to connect to new elected master (previously running as slave).
BOC

function configureRedisMasterServerProperties(){
	printf "min-slaves-to-write 1\nmin-slaves-max-lag 10\nmasterauth $2\n" >>/etc/redis/${1}.conf;
}

function configureRedisMasterServer(){
	configureRedisServer "$1" "$2" && configureRedisMasterServerProperties "$1" "$2" && restartRedisService "$1" && \
	enablePortInFirewall "$1" && { printf "Redis Master Node configured successfully \n"; return 0; } || \
	{ printf "Failed to configure Redis Master Node\n"; return 1; }; 
}
function configureRedisSlaveServerProperties(){
	printf "replicaof $2 $3\nmasterauth $4\nmin-slaves-to-write 1\nmin-slaves-max-lag 10\n" >>/etc/redis/${1}.conf;
}
 
function configureRedisSlaveServer(){
	local USAGE="Usage: ${FUNCNAME[0]} <redis_port_number> <redis_password> <redis_master_ip> <redis_master_port> <redis_master_password>";

	[[ -z "$1" || -z "$2" || -z "$3" || -z "$4" || -z "$5" ]] && { printf "${USAGE}\n"; return 1; };
	{ printf "$3" | egrep -v "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\$" &>/dev/null || printf "$4" | egrep -v "^[1-9][0-9]{1,4}*$" &>/dev/null;} && \
	{ printf "${USAGE}\n"; return 1; };

	configureRedisServer "$1" "$2" && configureRedisSlaveServerProperties "$1" "$3" "$4" "$5" && restartRedisService "$1" && \
	enablePortInFirewall "$1" && { printf "Redis Slave Node configured successfully \n"; return 0; } || \
	{ printf "Failed to configure Redis Slave Node\n"; return 1; };
}

function configureRedisClusterNodeProperties(){
	sed -i -e 's/^# masterauth <master-password>/masterauth '"$2"'/g' /etc/redis/${1}.conf &&
	sed -i -e 's/^# cluster-enabled yes/cluster-enabled yes/g' /etc/redis/${1}.conf && 
	sed -i -e 's:^# cluster-config-file nodes-6379.conf:cluster-config-file '"/etc/redis/cluster_${1}.conf"':g' /etc/redis/${1}.conf &&
	sed -i -e 's/^# cluster-node-timeout 15000/cluster-node-timeout 10000/g' /etc/redis/${1}.conf;
}

: <<BOC
In below function we are configuring redis cluster node with 2 ports enabled. first port is for general client communication and 2nd port is for cluster communication between nodes.Cluster port is always 10000 offset with respect general port,this is according to redis specification.So,we are opening cluster port also in the firewall.
BOC
function configureRedisClusterNode(){
	configureRedisServer "$1" "$2" && configureRedisClusterNodeProperties "$1" "$2" && restartRedisService "$1" && \
	enablePortInFirewall "$1" && enablePortInFirewall "$(( $1 + 10000 ))" && { printf "Redis Cluster Node configured successfully \n"; return 0; } || \
	{ printf "Failed to configure Redis Cluster Node\n"; return 1; };
}

