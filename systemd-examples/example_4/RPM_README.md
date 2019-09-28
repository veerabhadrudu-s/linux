
-> In this example, we are bulding rpm file which is packaged with our scripts,systemd unit files.
-> Follow below steps to genrate rpm file using rpm-buils tools

->Install below rpm build tools from repository.
# yum install gcc rpm-build rpm-devel rpmlint make python bash coreutils diffutils patch rpmdevtools
-> Run below command to setup rpm devlopment directories
# rpmdev-setuptree 
-> Above command should generate "rpmbuild" directory under home directory.
-> Run below script to generate rpm file. For more info on this read the script.
# ./generate_rpm_file.sh


Ref Links:-
https://linuxconfig.org/how-to-create-an-rpm-package
https://rpm-packaging-guide.github.io/
https://rpm.org/documentation.html


