Name:           coovachilli
Version:        1.8
Release:        1.el6
# Disable Python bytecode generation (EL6)
%global __brp_python_bytecompile %{nil}
Summary:        Open-source captive portal access controller

Group:          System Environment/Daemons
License:        GPLv2
URL:            https://github.com/coova/coova-chilli
Source0:        coova-chilli-1.8.tar.gz

BuildRequires:  gcc
BuildRequires:  make
BuildRequires:  libtool
BuildRequires:  autoconf
BuildRequires:  automake
BuildRequires:  openssl-devel
BuildRequires:  libnl-devel
BuildRequires:  libcap-devel
BuildRequires:  iptables-devel
BuildRequires:  curl-devel

Requires:       iptables
Requires:       openssl

BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root

%description
CoovaChilli is an open-source captive portal access controller derived
from the ChiliSpot project. It is commonly used to control network access
for public and private Wi-Fi hotspots, providing authentication,
authorization, and accounting features.

%prep
%setup -q -n coova-chilli-%{version}

# Provide empty cmdline.patch to satisfy build dependency
: > src/cmdline.patch

%build
export LANG=C
export PATH=/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin

# Generate autotools files
./bootstrap

# Configure for EL6 paths
./configure \
  --sysconfdir=/etc \
  --localstatedir=/var \
  --sbindir=/usr/sbin

make %{?_smp_mflags}

%install
rm -rf %{buildroot}
make DESTDIR=%{buildroot} install
# Remove invalid RPATHs added by libtool
chrpath --delete %{buildroot}/usr/local/lib/libchilli.so.0.0.0 || :
chrpath --delete %{buildroot}/usr/sbin/chilli* || :


# Runtime directories
mkdir -p %{buildroot}/var/run/chilli
mkdir -p %{buildroot}/var/log/chilli

# Default config handling
if [ -f %{buildroot}/etc/chilli.conf.example ] && [ ! -f %{buildroot}/etc/chilli.conf ]; then
  cp %{buildroot}/etc/chilli.conf.example %{buildroot}/etc/chilli.conf
fi

# Remove libtool + static archives (not shipped in runtime RPMs)
rm -f %{buildroot}/usr/local/lib/*.la
rm -f %{buildroot}/usr/local/lib/*.a

%post
/sbin/chkconfig --add chilli || :
/sbin/chkconfig chilli on || :

%preun
if [ $1 -eq 0 ]; then
    /sbin/service chilli stop || :
    /sbin/chkconfig --del chilli || :
fi


%files
%defattr(-,root,root,-)

# Exclude auto-generated Python bytecode (EL6)
%exclude /usr/local/lib/python/CoovaChilliLib.pyc
%exclude /usr/local/lib/python/CoovaChilliLib.pyo


%doc COPYING README ChangeLog NEWS

# Binaries
/usr/sbin/chilli
/usr/sbin/chilli_opt
/usr/sbin/chilli_query
/usr/sbin/chilli_radconfig
/usr/sbin/chilli_response

# Init script
/etc/init.d/chilli

# Configuration (own ONCE, includes www/)
%config(noreplace) /etc/chilli
%config(noreplace) /etc/chilli.conf

# Runtime directories
/var/run/chilli
/var/log/chilli

# Shared libraries (runtime only)
/usr/local/lib/libchilli.so*
/usr/local/lib/libbstring.so*

# Headers (acceptable for single-package client RPM)
/usr/local/include/chilli

# Python helper
/usr/local/lib/python/CoovaChilliLib.py

# Man pages
/usr/local/share/man/man1/*
/usr/local/share/man/man5/*
/usr/local/share/man/man8/*

%clean
rm -rf %{buildroot}

%changelog
* Tue Jan 27 2026 Your Name <you@example.com> - 1.8-1.el6
- Initial EL6 RPM build for CoovaChilli 1.8

