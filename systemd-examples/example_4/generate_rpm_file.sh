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
RPM_VERSION="1";
RPM_NAME_WITH_VERSION="${RPM_NAME}-${RPM_VERSION}";
TAR_NAME="${RPM_NAME}-${RPM_VERSION}.gz.tar";
RPM_BUILD_PATH="${HOME}/rpmbuild";
RPM_SPEC_FILE="systemd-slow-service.spec";
RPM_SPEC_FILE_PATH="${RPM_BUILD_PATH}/SPECS/${RPM_SPEC_FILE}";
SED_VERSION_EXPR='s/__VERSON_PLACE_HOLDER__/'${RPM_VERSION}'/g';

{ mkdir -p ${RPM_NAME_WITH_VERSION} && cp [cd]*.sh *.service *.timer ${RPM_NAME_WITH_VERSION} && \
tar -czvf ${TAR_NAME} "${RPM_NAME_WITH_VERSION}/"; } || { echo "Failed to create ${TAR_NAME}"; exit 1; };
echo "Completed creating ${TAR_NAME} file";
mv "${TAR_NAME}" "${RPM_BUILD_PATH}/SOURCES/${TAR_NAME}" && rm -fR "${RPM_NAME_WITH_VERSION}/";
cp "${RPM_SPEC_FILE}.tmplt" ${RPM_SPEC_FILE_PATH};
sed -ie ${SED_VERSION_EXPR} ${RPM_SPEC_FILE_PATH};
rpmbuild -ba ${RPM_SPEC_FILE_PATH};
