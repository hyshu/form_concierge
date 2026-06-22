FROM ghcr.io/cirruslabs/flutter:stable

USER root

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/root/.pub-cache/bin:${PATH}"

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    clang \
    cmake \
    curl \
    dbus-x11 \
    git \
    libgtk-3-dev \
    ninja-build \
    pkg-config \
    unzip \
    xauth \
    xvfb \
    xz-utils \
    zip \
  && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
  && apt-get install -y --no-install-recommends nodejs \
  && rm -rf /var/lib/apt/lists/*

RUN dart pub global activate jaspr_cli 0.23.1

WORKDIR /workspace
