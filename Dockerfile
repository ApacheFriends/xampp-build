FROM ubuntu:22.04
LABEL maintainer="Apache Friends"
ARG IB_VERSION=26.8.0

ARG DEBIAN_FRONTEND=noninteractive

# Install necessary tools and dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates file m4 gcc g++ make perl patch unzip bzip2 curl python3 zip git ninja-build \
    p7zip-full p7zip-rar tcl tk tcllib itcl3 tcl-vfs tdom \
    && rm -rf /var/lib/apt/lists/*

# Download and install InstallBuilder
RUN curl -L -o installbuilder.run "https://releases.installbuilder.com/installbuilder/installbuilder-professional-${IB_VERSION}-linux-x64-installer.run" \
    && chmod 755 installbuilder.run \
    && ./installbuilder.run --mode unattended --prefix /opt/installbuilder \
    && rm installbuilder.run \
    && ln -sf /opt/installbuilder /root/installbuilder-${IB_VERSION}

# Create tarballs directory
RUN mkdir -p /tmp/tarballs

# Set working directory
WORKDIR /home/xampp-code/src

CMD ["bash"]