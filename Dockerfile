FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

RUN apt-get update && apt-get install -y \
    bash-completion bc bison build-essential ccache clang flex \
    git g++-arm-linux-gnueabihf libcap-dev libelf-dev libssl-dev \
    llvm lld m4 python3-dev rsync wget xz-utils zip \
    gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu \
    libb64-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN cd /opt && wget -q https://github.com/ZyCromerZ/Clang/releases/download/16.0.6-20260510-release/Clang-16.0.6-20260510.tar.gz \
    && tar -xzf Clang-16.0.6-20260510.tar.gz -C /opt \
    && rm Clang-16.0.6-20260510.tar.gz \
    && ln -s /opt/aarch64-linux-android-14-arm64/ /opt/zyc-clang

ENV PATH="/opt/zyc-clang/bin:${PATH}"

RUN mkdir -p /workspace
WORKDIR /workspace
