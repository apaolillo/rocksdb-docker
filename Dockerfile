FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        file \
        git \
        less \
        locales \
        locales-all \
        sudo \
        vim \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends \
        libbz2-dev \
        libgflags-dev \
        liblz4-dev \
        libsnappy-dev \
        libzstd-dev \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Set locales
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

RUN echo 'root:root' | chpasswd

ARG USER_NAME=user
RUN adduser --disabled-password --gecos "" ${USER_NAME}
RUN adduser ${USER_NAME} sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER ${USER_NAME}

WORKDIR /home/${USER_NAME}
RUN touch ~/.sudo_as_admin_successful
RUN mkdir workspace
RUN mkdir imagebuild

WORKDIR /home/${USER_NAME}/imagebuild
ARG ROCKSDB_VERSION=v6.26.0
RUN git clone --branch ${ROCKSDB_VERSION} --depth 1 https://github.com/facebook/rocksdb.git 2> /dev/null
WORKDIR /home/${USER_NAME}/imagebuild/rocksdb

RUN mkdir -p build
RUN make -j "$(nproc)" release OBJ_DIR=build/

ARG DB_PATH=/tmp/db_test
RUN ./db_bench --threads=1 --benchmarks=fillseq --db=${DB_PATH}

RUN ./db_bench \
        --threads=3 \
        --benchmarks=readrandom \
        --use_existing_db=1 \
        --db=${DB_PATH} \
        --duration=3
