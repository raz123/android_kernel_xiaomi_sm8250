FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

RUN apt-get update && apt-get install -y \
    bash-completion bc bison build-essential ccache clang flex \
    git g++-arm-linux-gnueabihf libcap-dev libelf-dev libssl-dev \
    llvm lld m4 python3-dev rsync wget xz-utils zip \
    gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu \
    dos2unix \
    libb64-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/zyc-clang && cd /opt/zyc-clang \
    && wget -q https://github.com/ZyCromerZ/Clang/releases/download/16.0.6-20260510-release/Clang-16.0.6-20260510.tar.gz \
    && tar -zxf Clang-16.0.6-20260510.tar.gz \
    && rm Clang-16.0.6-20260510.tar.gz \
    && ln -sf /opt/zyc-clang/bin/clang /usr/local/bin/clang \
    && ln -sf /opt/zyc-clang/bin/ld.lld /usr/local/bin/ld.lld \
    && ln -sf /opt/zyc-clang/bin/lld /usr/local/bin/lld \
    && ln -sf /opt/zyc-clang/bin/llvm-ar /usr/local/bin/llvm-ar \
    && ln -sf /opt/zyc-clang/bin/llvm-nm /usr/local/bin/llvm-nm \
    && ln -sf /opt/zyc-clang/bin/llvm-objcopy /usr/local/bin/llvm-objcopy \
    && ln -sf /opt/zyc-clang/bin/llvm-objdump /usr/local/bin/llvm-objdump \
    && ln -sf /opt/zyc-clang/bin/llvm-strip /usr/local/bin/llvm-strip

ENV PATH="/opt/zyc-clang/bin:${PATH}"

RUN mkdir -p /workspace
WORKDIR /workspace
