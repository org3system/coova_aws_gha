FROM centos:6

# Use CentOS vault (EOL mirrors)
RUN sed -i \
    -e 's|^mirrorlist=|#mirrorlist=|g' \
    -e 's|^#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' \
    /etc/yum.repos.d/CentOS-Base.repo

# Enable EPEL 6 (required for gengetopt)
RUN yum install -y \
    https://archives.fedoraproject.org/pub/archive/epel/6/x86_64/epel-release-6-8.noarch.rpm

# Install build dependencies and AWS CLI v1 (compatible with Python 2.6 on EL6)
RUN yum clean all && \
    yum install -y \
        rpm-build \
        redhat-rpm-config \
        gcc \
        gcc-c++ \
        make \
        autoconf \
        automake \
        libtool \
        gengetopt \
        openssl-devel \
        iptables-devel \
        libnl-devel \
        libcap-devel \
        curl-devel \
        python \
        chkconfig \
        wget \
        tar \
        which \
        unzip && \
    yum clean all

# Install AWS CLI via pip (Python 2.6 compatible version)
RUN wget -q https://bootstrap.pypa.io/pip/2.6/get-pip.py -O /tmp/get-pip.py && \
    python /tmp/get-pip.py && \
    pip install "awscli==1.11.13" && \
    rm /tmp/get-pip.py

# Pre-create rpmbuild tree
RUN mkdir -p /root/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}

COPY packaging/coova-chilli.spec /root/rpmbuild/SPECS/coova-chilli.spec

COPY scripts/build-rpm-ecs.sh /usr/local/bin/build-rpm-ecs.sh
RUN chmod +x /usr/local/bin/build-rpm-ecs.sh

ENV LANG=C
ENV LC_ALL=C

ENTRYPOINT ["/usr/local/bin/build-rpm-ecs.sh"]
