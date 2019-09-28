#!/bin/bash
####################################################
# This Script will take backup of monitoring plugins.
####################################################

VAR_MONITORING_PLUGINS_PATH="/opt/Monitoring/Isildur";
VAR_MONITORING_PLUGINS_CONF_PATH="/etc/Isildur/";
VAR_MONITORING_PLUGINS_CONF_ROOT_DIR=${VAR_MONITORING_PLUGINS_CONF_PATH#/};
VAR_MONITORING_PLUGINS_CONF_ROOT_DIR=${VAR_MONITORING_PLUGINS_CONF_ROOT_DIR%%/*}/;
VAR_MONITORING_PLUGINS_ROOT_DIR=${VAR_MONITORING_PLUGINS_PATH#/};
VAR_MONITORING_PLUGINS_ROOT_DIR=${VAR_MONITORING_PLUGINS_ROOT_DIR%%/*}/;
VAR_BACK_UP_TAR_FILE_NAME="modified_scripts.tar.gz";

[ -a "$VAR_BACK_UP_TAR_FILE_NAME" ] && { echo "Removing old $VAR_BACK_UP_TAR_FILE_NAME file" ;  rm -f $VAR_BACK_UP_TAR_FILE_NAME; };

cp --parents -R "$VAR_MONITORING_PLUGINS_PATH" . && \
cp --parents -R "$VAR_MONITORING_PLUGINS_CONF_PATH" . && \
rm -f ${VAR_MONITORING_PLUGINS_PATH:1}/Logs/* && \
rm -fR ${VAR_MONITORING_PLUGINS_PATH:1}/WebPages/* && \
tar -czf  $VAR_BACK_UP_TAR_FILE_NAME $VAR_MONITORING_PLUGINS_ROOT_DIR $VAR_MONITORING_PLUGINS_CONF_ROOT_DIR && \
rm -fR $VAR_MONITORING_PLUGINS_ROOT_DIR $VAR_MONITORING_PLUGINS_CONF_ROOT_DIR;

[ "$?" ] || { echo "Failed to take back try taking it manually" ; exit 2;}
echo "Completed taking back up of plugins scripts to new $VAR_BACK_UP_TAR_FILE_NAME file ";
exit 0;

