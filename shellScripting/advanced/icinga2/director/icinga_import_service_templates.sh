#!/usr/bin/bash

#Below approach of source command allows us to import subroutines from any where into these files.
#This allows us to run this script from any where (Provided script directory path should be added under PATH variable).
#That means, Along with below source command way of import and script directory path in PATH variable allows us to execute these scripts from any directory.
source $(dirname $(which "$0"))/subroutines/icinga_import_service_tmplt_sub.sh

create_service_tmplts "$1";

exit $?;
