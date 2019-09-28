#!/usr/bin/bash
: <<BLK_CMT
This script will configure commands,services and hosts into icinga director component using input csv files.
BLK_CMT

#Below approach of source command allows us to import subroutines from any where into these files.
#This allows us to run this script from any where (Provided script directory path should be added under PATH variable).
#That means, Along with below source command way of import and script directory path in PATH variable allows us to execute these scripts from any directory.
source $(dirname $(which "$0"))/subroutines/icinga_import_command_sub.sh;
source $(dirname $(which "$0"))/subroutines/icinga_import_service_tmplt_sub.sh;
source $(dirname $(which "$0"))/subroutines/icinga_import_host_group_sub.sh;
source $(dirname $(which "$0"))/subroutines/icinga_import_host_tmplt_sub.sh;
source $(dirname $(which "$0"))/subroutines/icinga_import_host_config_sub.sh;

USAGE="Usage : $0 <command_config.csv> <service_template.csv> <host_groups.csv> <host_template.csv> <host_config.csv>";       

[[ $# -lt 5 ]] && { printf "${USAGE}\n"; exit 1; };
for INPUT_FILE in $@ ;
do 
	[[ -f "${INPUT_FILE}" ]] || { printf "File with name ${INPUT_FILE} doesn't exist or it might not be regular file.\n"; exit 2; };
done
type icingacli &>/dev/null || { "This Host is not configured with Icinga"; exit 3; };
icingacli module list | egrep "^director" &>/dev/null || { printf "Icinga Director Module is not configured\n"; exit 4; };

create_commands "$1";
create_service_tmplts "$2";
create_host_groups "$3";
create_host_templates "$4";
create_hosts "$5";

exit 0;
