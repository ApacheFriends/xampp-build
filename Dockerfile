FROM ubuntu:24.04
LABEL maintainer="Apache Friends"
ARG IB_VERSION=24.7.0

# Install necessary tools and dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates file m4 gcc g++ make perl patch unzip bzip2 curl \
    p7zip-full p7zip-rar tcl tk tcllib itcl3 tcl-vfs tdom \
    && apt-get clean

# Download and install InstallBuilder
RUN curl -L -o installbuilder.run "https://releases.installbuilder.com/installbuilder/installbuilder-enterprise-${IB_VERSION}-linux-x64-installer.run" \
    && chmod 755 installbuilder.run \
    && ./installbuilder.run --mode unattended --prefix /opt/installbuilder \
    && rm installbuilder.run \
    && ln -sf /opt/installbuilder /root/installbuilder-${IB_VERSION}

CMD ["bash"]
