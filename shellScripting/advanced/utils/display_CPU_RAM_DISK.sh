#!/usr/bin/bash
# This script will display no of cpus,RAM,Storage Space Configured.

: <<'BLC'
In the below awk command , first we are defining SUM variable in BEGIN BLOCK.
Next we are using a regular expression filter on $1 to filter sudo file systems and banner of df command.
In the Main BLOCK we are summing all the partitions size.
Finally, In the END Block we are calculating size in GB and printing the STORAGE SPACE Size.
BLC

STORAGE_SPACE="$(df -BK | awk 'BEGIN { SUM=0;} $1 ~ /\// { split($2, a, "K"); SUM=SUM+a[1]; } END {SUM=SUM/(1024*1024);  print SUM; }')";
echo "$(df -BK | awk 'BEGIN { SUM=0;} $1 ~ /\// { split($2, a, "K"); SUM=SUM+a[1]; print } END {SUM=SUM/(1024*1024);  print SUM; }')";
RAM_IN_GB="$(awk '$1 ~ /MemTotal/ {RAM_IN_GB=$2/(1024*1024); print RAM_IN_GB}' /proc/meminfo )";
NO_OF_CPUS="$(lscpu | awk  '$1 ~ /CPU\(/ { print $2}')";

printf "${NO_OF_CPUS},${STORAGE_SPACE},${RAM_IN_GB}\n";

exit;
