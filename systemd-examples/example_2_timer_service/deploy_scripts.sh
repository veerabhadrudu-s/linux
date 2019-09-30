#!/usr/bin/bash

SLEEP_TIME=10;
type systemctl &>/dev/null || { echo "This is not a systemd based OS.Could be not proceed.."; exit 1; };

systemctl --now disable systemd-slow-service.timer;
systemctl --now disable systemd-cleanup-service.timer;
systemctl --now disable systemd-slow-service.service;
systemctl --now disable systemd-cleanup-service.service;
\cp systemd-* /etc/systemd/system/;
systemctl daemon-reload;
systemctl --now enable systemd-cleanup-service.timer;
echo "Creating scheduling time differences between timer using sleep time of ${SLEEP_TIME}. Please wait..." && sleep ${SLEEP_TIME};
systemctl --now enable systemd-slow-service.timer;
