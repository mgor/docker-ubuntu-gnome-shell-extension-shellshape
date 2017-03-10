FROM mgor/docker-ubuntu-pkg-builder:zesty

MAINTAINER Mikael Göransson <github@mgor.se>

ENV DEBIAN_FRONTEND noninteractive
ENV BUILD_DIRECTORY /usr/local/src
ENV BUILD_SCRIPT /usr/local/bin/build.sh

# Using apt-get due to warning with apt:
# WARNING: apt does not have a stable CLI interface. Use with caution in scripts.
RUN apt-get update && \
    apt-get install -y apt-utils && \
    apt-get install -y \
        sudo \
        libglib2.0-dev \
        npm \
        nodejs-legacy \
        && \
    # Clean up!
    rm -rf /var/lib/apt/lists/*

COPY build.sh ${BUILD_SCRIPT}

RUN chmod 755 ${BUILD_SCRIPT}

WORKDIR ${BUILD_DIRECTORY}

CMD ${BUILD_SCRIPT}
