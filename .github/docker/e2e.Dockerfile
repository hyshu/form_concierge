FROM ghcr.io/cirruslabs/flutter@sha256:46691e311715845de03a3ba4753a475476936805b29431b1f00f1816981033f8

ARG FLUTTER_VERSION=3.47.9

USER root

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/root/.pub-cache/bin:${PATH}"

RUN git -C /sdks/flutter fetch --depth=1 origin "refs/tags/${FLUTTER_VERSION}:refs/tags/${FLUTTER_VERSION}" \
  && git -C /sdks/flutter checkout --detach "${FLUTTER_VERSION}" \
  && rm -f /sdks/flutter/version /sdks/flutter/bin/cache/flutter.version.json \
  && flutter precache --linux \
  && flutter --version --machine | python3 -c \
    "import json, sys; data = sys.stdin.read(); assert json.loads(data[data.index('{'):])['frameworkVersion'] == '${FLUTTER_VERSION}'"

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
  && curl -fsSL https://deb.nodesource.com/setup_26.x | bash - \
  && apt-get install -y --no-install-recommends nodejs \
  && rm -rf /var/lib/apt/lists/*

RUN dart pub global activate jaspr_cli 0.23.5

WORKDIR /workspace
