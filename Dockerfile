#
# jdownloader-2 Dockerfile
#
# https://github.com/jlesage/docker-jdownloader-2
#
# ##############################################################################
# 7-Zip-JBinding Workaround
#
# JDownloader works well with the native openjdk8-jre package.  There is one
# exception: the auto archive extractor.  This feature uses 7-Zip-JBinding,
# which provides a platform-specific library (.so).  The one for Linux x86_64
# has been compiled against glibc and this is not loading correctly on Alpine.
#
# To work around this issue (until we get a proper support of 7-Zip-JBinding on
# Alpine), we need to:
#     - Get glibc, by using the glibc version of the baseimage.
#     - Use Oracle JRE, to have a glibc-based Java VM.
# ##############################################################################

# Pull base image.
# NOTE: glibc version of the image is needed for the 7-Zip-JBinding workaround.
FROM lsiobase/gui:latest

# Docker image version is provided via build arg.
ENV TERM="xterm" APPNAME="jdownloader2"
ARG DEBIAN_FRONTEND=noninteractive
ARG DOCKER_IMAGE_VERSION=unknown

# Define software versions.
ARG JAVAJRE_VERSION=8

# Define working directory.
WORKDIR /tmp

# Install dependencies.
RUN \
    apt-get update && \
    apt-get install -y \
        # For the 7-Zip-JBinding workaround, Oracle JRE is needed instead of
        # the Alpine Linux's openjdk native package.
        # The libstdc++ package is also needed as part of the 7-Zip-JBinding
        # workaround.
        #openjdk8-jre \
        libstdc++-5-dev \
        ttf-dejavu \
        # For ffmpeg and ffprobe tools.
        ffmpeg \
        # For rtmpdump tool.
        rtmpdump \
        wget \
        python \
        python-pip && \
    pip install pyxdg

# Download and install Oracle JRE.
# NOTE: This is needed only for the 7-Zip-JBinding workaround.
RUN \
    export DEBIAN_FRONTEND=noninteractive && \
    apt-get install -y --no-install-recommends build-essential curl && \
    mkdir /opt/jre

# Download JDownloader 2.
# Determinate CPU Arch.
# Define software download URLs.
RUN \
  dpkgArch="$(uname -m)" && \
  case "${dpkgArch##*-}" in \
    x86_64) ARCH='x64';; \
    aarch64) ARCH='aarch64';; \
    *) echo "unsupported architecture"; exit 1 ;; \
  esac && \
  echo “Running on ${ARCH}” && \
  export JDOWNLOADER_URL="http://installer.jdownloader.org/JDownloader.jar" && \
  export JAVAJRE_URL="https://corretto.aws/downloads/latest/amazon-corretto-${JAVAJRE_VERSION}-${ARCH}-linux-jdk.tar.gz" && \
  mkdir -p /defaults && \
  wget ${JDOWNLOADER_URL} -O /defaults/JDownloader.jar && \
  echo "Downloading from" ${JAVAJRE_URL} && \
  cd /defaults && \
  wget ${JAVAJRE_URL} -O /defaults/amazon-corretto.tar.gz && \
  tar -xzf /defaults/amazon-corretto.tar.gz && \
  cp -r /defaults/amazon-corretto-*/jre /opt && \
  apt-get remove -y build-essential

# Maximize only the main/initial window.
RUN \
    sed -i 's/<application type="normal">/<application type="normal" title="JDownloader 2">/' \
        /etc/xdg/openbox/rc.xml

# Add files.
COPY rootfs/ /

# Generate and install favicons.
#RUN \
#    APP_ICON_URL=https://raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/jdownloader-2-icon.png && \
#    chmod +x /usr/local/bin/install_app_icon.sh && \
#    install_app_icon.sh "$APP_ICON_URL"

# Set environment variables.
ENV APP_NAME="JDownloader 2" \
    S6_KILL_GRACETIME=8000

# Define mountable directories.
VOLUME ["/config"]
VOLUME ["/output"]

# Expose ports.
#   - 3129: For MyJDownloader in Direct Connection mode.
EXPOSE 3129
