#!/usr/bin/bash
: <<BLOCK_CMT
-> This script will generate rpm file. Following steps are happening in this script.
-> First we are creating tar file which includes systemd unit files and corresponding scripts.
-> This Tar file is refered as input program source code in systemd-slow-service.spec file.
-> move generated tar file under ~/rpmbuild/SOURCES/ directory.
-> move systemd-slow-service.spec file under ~/rpmbuild/SPECS/ 
-> systemd-slow-service.spec has information/instructions on how to generate rpm file.For more info on this use reference links.
-> Run rpmbuild command to generate rpm file.  

Ref Links:-
https://linuxconfig.org/how-to-create-an-rpm-package
https://rpm-packaging-guide.github.io/
https://rpm.org/documentation.html
BLOCK_CMT

RPM_NAME="systemd-slow-service";
RPM_VERSTION="1";



