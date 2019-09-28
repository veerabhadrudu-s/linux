#!/usr/bin/bash
: <<BOC 
This script will download the redis source code,makes the binaries from source code and configures the stanalone server.
This script configures password for the server,configures to listen on all ip address (0.0.0.0) and modifies init script to allow proper shutdown using redis password.
BOC

source ../subroutines/configure_redis_server_sub.sh
configureRedisStandaloneServer "$1" "$2";

exit 0;

