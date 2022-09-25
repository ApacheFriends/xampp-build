FROM docker.io/centos:7.3.1611
LABEL maintainer "Apache Friends"
ARG IB_VERSION=22.3.0

# Compilation tools
RUN yum install -y \
ca-certificates file m4 gcc gcc-c++ make perl patch unzip bzip2 epel-release \
&& yum install -y p7zip p7zip-plugins \
&& yum clean all

RUN curl > 'tclkit' 'https://tclkits.rkeene.org/fossil/raw/tclkit-8.5.17-rhel5-x86_64?name=76a197fe41359daaf4f90a2001f46675b3667e26' \
&& chmod 755 tclkit && mv tclkit /usr/local/bin

RUN curl -L > 'installbuilder.run' "https://installbuilder.com/installbuilder-professional-${IB_VERSION}-linux-x64-installer.run" \
&& chmod 755 installbuilder.run && ./installbuilder.run --mode unattended --prefix /opt/installbuilder \
&& rm installbuilder.run && ln -sf /opt/installbuilder /root/installbuilder-${IB_VERSION}

CMD [ "bash" ]