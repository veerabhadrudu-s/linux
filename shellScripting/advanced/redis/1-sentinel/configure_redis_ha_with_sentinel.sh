#!/usr/bin/bash
: <<BOC 
This script will download the redis source code,makes the binaries from source code and configures redis in sentinel mode.
This script configures in total m sentinels,n redis servers(1 master and n-1 slaves).
This script by default configures same password for Master and slaves.
This script configures by default to listen on all interfaces(0.0.0.0) for all servers.
BOC

source ../subroutines/configure_redis_server_sub.sh
USAGE="Usage: $0 <redis_servers_starting_port-redis_server_ending_port> <sentinel_starting_port-sentinel_ending_port> <password> <redis_master_ip>";
REDIS_START_PORT=${1%-*};
REDIS_END_PORT=${1#*-};
SENTINEL_START_PORT=${2%-*};
SENTINEL_END_PORT=${2#*-};

[[ -z "$1" || -z "$2" || -z "$3" || -z "$4" ]] && { printf "${USAGE}\n"; exit 1; };
{ printf "$1" | egrep -v "^[1-9][0-9]{0,4}-[1-9][0-9]{0,4}$" &>/dev/null || printf "$2" | egrep -v "^[1-9][0-9]{0,4}-[1-9][0-9]{0,4}$" &>/dev/null; } && \
{ printf "Starting and ending port syntax is \"starting_port_number-ending_port_number\" \n"; exit 1; };
[[ ${REDIS_START_PORT} -ge ${REDIS_END_PORT} || ${SENTINEL_START_PORT} -ge ${SENTINEL_END_PORT} ]] && \
{ printf "Starting port can't be grater than or equal to end port \n"; exit 1; };
printf "$4" | egrep -v "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$" &>/dev/null && { printf "Invalid redis master ip address\n"; exit 1;};

makeRedisByDownloading;
#Code to configure Redis Master and Slave Nodes.
configureRedisMasterServer "${REDIS_START_PORT}" "$3";
for PORT in $( eval echo "{$((REDIS_START_PORT + 1 ))..${REDIS_END_PORT}}") ;do
	configureRedisSlaveServer "$PORT" "$3" "$4" "${REDIS_START_PORT}" "$3";
done
cleanRedisWorkDirectory;

#Code to configure Sentinal Nodes.
QUORUM=$(( (( (SENTINEL_END_PORT + 1) - SENTINEL_START_PORT ) / 2 ) + 1 ));
[[ "${QUORUM}" -eq "0" ]] && { QUORUM="1"; };# This is when Start port and end port values are same.
for PORT in $( eval echo "{${SENTINEL_START_PORT}..${SENTINEL_END_PORT}}" );do
	# Sentinel configuration file creation.
	\cp sentinel_template.conf sentinel_${PORT}.conf;
	sed -i -e 's/^port 26379/port '"${PORT}"'/g' sentinel_${PORT}.conf;
	sed -i -e 's:^dir /tmp:dir /var/lib/redis/sentinel/'"${PORT}"':g' sentinel_${PORT}.conf;
	mkdir -p "/var/lib/redis/sentinel/${PORT}";
	sed -i -e 's/^sentinel monitor mymaster 127.0.0.1 6379 2/sentinel monitor mymaster '"$4 ${REDIS_START_PORT} ${QUORUM}"'/g' sentinel_${PORT}.conf;
	sed -i -e 's/^# sentinel auth-pass <master-name> <password>/sentinel auth-pass mymaster '"$3"'/g' sentinel_${PORT}.conf;	
	#printf "daemonize yes\nsupervised systemd\nlogfile /var/log/redis_${PORT}.log\n" >> sentinel_${PORT}.conf;
	printf "daemonize yes\nlogfile /var/log/redis_${PORT}.log\n" >> sentinel_${PORT}.conf;
	\mv sentinel_${PORT}.conf /etc/redis/;
	# Sentinel service file creation.
	\cp sentinel_template.service sentinel_${PORT}.service;
	sed -i -e 's/__PORT__/'"$PORT"'/g' sentinel_${PORT}.service;
	\mv sentinel_${PORT}.service /etc/systemd/system/; 
	systemctl enable sentinel_${PORT}.service;
	systemctl restart sentinel_${PORT}.service; 
	firewall-cmd --add-port=${PORT}/tcp && firewall-cmd --add-port=${PORT}/tcp --permanent;
done


exit 0;

