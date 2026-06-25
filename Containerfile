FROM ubuntu:22.04 AS build

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    cmake \
    git \
    libconfig-dev \
    libcurl4-openssl-dev \
    libedit-dev \
    libgnutls28-dev \
    libjansson-dev \
    libmicrohttpd-dev \
    libnuma-dev \
    libpcap-dev \
    libsystemd-dev \
    libtinfo-dev \
    m4 \
    meson \
    ninja-build \
    pkg-config \
    python3-pyelftools \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src/openupf
COPY . .
ARG OPENUPF_TRACE_ENABLE=0
RUN if [ "${OPENUPF_TRACE_ENABLE}" = "1" ]; then \
      export CFLAGS="${CFLAGS} -DOPENUPF_TRACE_ENABLE"; \
    fi; \
    DPDK_MESON_ARGS="-Dtests=false" ./build/build.sh

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libatomic1 \
    libbsd0 \
    libconfig9 \
    libcurl4 \
    libedit2 \
    libgnutls30 \
    libjansson4 \
    libmicrohttpd12 \
    libnuma1 \
    libpcap0.8 \
    libsystemd0 \
    libtinfo6 \
    pciutils \
    procps \
    zlib1g \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /src/openupf/install /opt/upf
COPY deploy/kubernetes/entrypoint.sh /opt/upf/script/kubernetes-entrypoint.sh

WORKDIR /opt/upf
ENV PATH=/opt/upf/bin:${PATH}
ENV LD_LIBRARY_PATH=/opt/upf/lib
CMD ["/bin/bash"]
