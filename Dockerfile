# Updating Dockerfile to a maintained distro, also latest releases are no longer building with the default
# versions of GCC included on CentOS7 (GCC-4.8.5). Default GCC version must be upgraded in order for this repository
# to remain up to date with latest release

FROM ubuntu:24.04
LABEL maintainer="Apache Friends"
ARG IB_VERSION=26.5.1

# Install necessary tools and dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates file m4 gcc g++ make perl patch unzip bzip2 curl python3 zip git ninja-build \
    p7zip-full p7zip-rar tcl tk tcllib itcl3 tcl-vfs tdom \
    && apt-get clean

# Download and install InstallBuilder
RUN curl -L -o installbuilder.run "https://releases.installbuilder.com/installbuilder/installbuilder-enterprise-${IB_VERSION}-linux-x64-installer.run" \
    && chmod 755 installbuilder.run \
    && ./installbuilder.run --mode unattended --prefix /opt/installbuilder \
    && rm installbuilder.run \
    && ln -sf /opt/installbuilder /root/installbuilder-${IB_VERSION}

# Create tarballs directory
RUN mkdir -p /tmp/tarballs

# Set working directory
WORKDIR /home/xampp-code/src

CMD ["bash"]
