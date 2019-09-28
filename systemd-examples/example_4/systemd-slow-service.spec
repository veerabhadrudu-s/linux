Name: 	     	 systemd-slow-service 
Version:	 1
Release:    	 1%{?dist}
Summary:   	 This is a systemd slow service
License:   	 GPL
Source0:	 /root/rpmbuild/SPECS/systemd-slow-service-%{version}.gz.tar
BuildArch: 	 noarch
BuildRequires:	 systemd
Requires:	 systemd


%description
This is a systemd slow service rpm, which has 2 service files.

%prep
%setup -q

%build

%install
mkdir -p %{buildroot}/usr/bin/
install -m 755 dummy.sh %{buildroot}/usr/bin/dummy.sh

%files
/usr/bin/dummy.sh

%changelog
# let's skip this for now
