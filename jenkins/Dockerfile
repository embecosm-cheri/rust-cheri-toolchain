# Use Ubuntu 22.04 (latest LTS at time of writing)
FROM ubuntu:22.04

# Install necessary dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    curl \
    git \
    libarchive-dev \
    libglib2.0-dev \
    libpixman-1-dev \
    libtool \
    netcat-openbsd \
    ninja-build \
    pkg-config \
    python3 \
    time \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -u 1001 jenkins
USER jenkins

WORKDIR /home/jenkins
