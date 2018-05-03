FROM debian:stretch-slim

LABEL maintainer "Mario Castro Squella <yo@marcastr0.com>"

RUN apt-get clean && apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential autoconf curl chrpath pkg-config wget \
    ncurses-dev libreadline-dev libedit-dev \
    libunwind-dev \
    libgmp-dev \
    libssl-dev \
    unixodbc-dev \
    zlib1g-dev libarchive-dev \
    libossp-uuid-dev \
    libxext-dev libice-dev libjpeg-dev libxinerama-dev libxft-dev \
    libxpm-dev libxt-dev \
    libdb-dev \
    libpcre3-dev \
    libyaml-dev \
    && rm -rf /var/lib/apt/lists/*

ENV LANG C.UTF-8

RUN { \
        echo '#!/bin/sh'; \
        echo 'set -e'; \
        echo; \
        echo 'dirname "$(dirname "$(readlink -f "$(which javac || which java)")")"'; \
    } > /usr/local/bin/docker-java-home \
    && chmod +x /usr/local/bin/docker-java-home

RUN ln -svT "/usr/lib/jvm/java-8-openjdk-$(dpkg --print-architecture)" /docker-java-home
ENV JAVA_HOME /docker-java-home

ENV JAVA_VERSION 8u171
ENV JAVA_DEBIAN_VERSION 8u171-b11-1~deb9u1

ENV CA_CERTIFICATES_JAVA_VERSION 20170531+nmu1

RUN set -ex; \
    \
    if [ ! -d /usr/share/man/man1 ]; then \
        mkdir -p /usr/share/man/man1; \
    fi; \
    \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        openjdk-8-jdk="$JAVA_DEBIAN_VERSION" \
        ca-certificates-java="$CA_CERTIFICATES_JAVA_VERSION" \
    ; \
    rm -rf /var/lib/apt/lists/*; \
    \
    [ "$(readlink -f "$JAVA_HOME")" = "$(docker-java-home)" ]; \
    \
    update-alternatives --get-selections | awk -v home="$(readlink -f "$JAVA_HOME")" 'index($3, home) == 1 { $2 = "manual"; print | "update-alternatives --set-selections" }'; \
    update-alternatives --query java | grep -q 'Status: manual'

# see CA_CERTIFICATES_JAVA_VERSION notes above
RUN /var/lib/dpkg/info/ca-certificates-java.postinst configure

RUN set -eux; \
    SWIPL_VER=7.6.4; \
    SWIPL_CHECKSUM=2d3d7aabd6d99a02dcc2da5d7604e3500329e541c6f857edc5aa06a3b1267891; \
    mkdir /tmp/src; \
    cd /tmp/src; \
    wget http://www.swi-prolog.org/download/stable/src/swipl-$SWIPL_VER.tar.gz; \
    echo "$SWIPL_CHECKSUM  swipl-$SWIPL_VER.tar.gz" >> swipl-$SWIPL_VER.tar.gz-CHECKSUM; \
    sha256sum -c swipl-$SWIPL_VER.tar.gz-CHECKSUM; \
    tar -xzf swipl-$SWIPL_VER.tar.gz; \
    cd swipl-$SWIPL_VER/src; \
    ./configure; make; make install; \
    cd ../packages/jpl; \
    ./configure; make; make install; \
    mkdir -p /usr/local/lib/swipl-7.6.4/pack; \
    cd /usr/local/lib/swipl-7.6.4/pack; \
    rm -rf /tmp/src

# Add SWI-Prolog to the Java library path
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:$JAVA_HOME/jre/lib/amd64:/usr/local/lib/swipl-7.6.4/lib/x86_64-linux