FROM docker.io/centos:7.9.2009
LABEL maintainer="Apache Friends"
ARG IB_VERSION=25.10.1

# Fix CentOS 7 mirror URLs to use vault.centos.org
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*.repo && \
    sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*.repo

# Compilation tools
RUN yum install -y \
ca-certificates file m4 gcc gcc-c++ make perl patch unzip bzip2 epel-release wget curl \
&& yum install -y p7zip p7zip-plugins \
&& yum clean all

# Install tclkit
RUN curl -L -o tclkit 'https://tclkits.rkeene.org/fossil/raw/tclkit-8.5.17-rhel5-x86_64?name=76a197fe41359daaf4f90a2001f46675b3667e26' \
&& chmod 755 tclkit && mv tclkit /usr/local/bin

# Download and install InstallBuilder
RUN curl -L -o installbuilder.run "https://releases.installbuilder.com/installbuilder/installbuilder-professional-${IB_VERSION}-linux-x64-installer.run" \
&& chmod 755 installbuilder.run \
&& ./installbuilder.run --mode unattended --prefix /opt/installbuilder \
&& rm installbuilder.run \
&& ln -sf /opt/installbuilder /root/installbuilder-${IB_VERSION} \
&& echo $IB_VERSION > /opt/installbuilder/ibversion

# Create tarballs directory
RUN mkdir -p /tmp/tarballs

# Set working directory
WORKDIR /opt/xampp-build


CMD [ "bash" ]