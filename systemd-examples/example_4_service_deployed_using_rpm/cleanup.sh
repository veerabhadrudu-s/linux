#!/usr/bin/bash

type systemctl &>/dev/null || { echo "This is not a systemd based OS.Could be not proceed.."; exit 1; };
[[ -z "$1" ]] && { echo "Usage: $0 <systemd service unit file> "; exit 1; };
# systemctl show "$1";
mapfile -t RUNNING_STATE_OF_SERVICE < <(systemctl show "$1" | egrep "LoadState|ActiveState|SubState")

echo "RUNNING STATE OF SERVICE $1 is - ${RUNNING_STATE_OF_SERVICE[@]}";
[[ "${RUNNING_STATE_OF_SERVICE[0]#*=}" = "not-found" ]] && { echo "$1 - systemd service unit file not installed/enabled"; exit 2; };
[[ "${RUNNING_STATE_OF_SERVICE[0]#*=}" = "loaded" &&  "${RUNNING_STATE_OF_SERVICE[1]#*=}" = "inactive" && "${RUNNING_STATE_OF_SERVICE[2]#*=}" = "dead" ]] && \
{ echo "$1 - systemd service unit file already stopped"; exit 0; };
[[ "${RUNNING_STATE_OF_SERVICE[0]#*=}" = "loaded" &&  "${RUNNING_STATE_OF_SERVICE[1]#*=}" = "active" && "${RUNNING_STATE_OF_SERVICE[2]#*=}" = "running" ]] && \
{ { systemctl stop "$1" && exit 0; } || { echo "Failed to stop $1 systemd service unit file.Please check journal logs."; exit 3; }; };

echo "Invalid running states of $1 systemd service unit file - ${RUNNING_STATE_OF_SERVICE[@]}" && exit 4;

