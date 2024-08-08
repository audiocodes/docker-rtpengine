FROM debian:bookworm-slim AS build

RUN apt-get update && apt-get install -y --no-install-recommends \
  build-essential \
  ca-certificates \
  curl \
  default-libmysqlclient-dev \
  g++ \
  gcc \
  git \
  gperf \
  iproute2 \
  iptables \
  libavcodec-extra \
  libavfilter-dev \
  libcurl4-openssl-dev \
  libevent-dev \
  libhiredis-dev \
  libiptc-dev \
  libjson-glib-dev \
  libmnl-dev \
  libnftnl-dev \
  libopus-dev \
  libpcap-dev \
  libpcre3-dev \
  libspandsp-dev \
  libssl-dev \
  libwebsockets-dev \
  libxmlrpc-core-c3-dev \
  make \
  markdown \
  pandoc

WORKDIR /usr/src
RUN git clone --depth 1 --branch mr12.4.1.8 https://github.com/sipwise/rtpengine

FROM build AS rtpengine
WORKDIR /usr/src/rtpengine/daemon
RUN make -j$(nproc)

FROM build AS rtpengine-recording
WORKDIR /usr/src/rtpengine/recording-daemon
RUN make -j$(nproc)

FROM debian:bookworm-slim

VOLUME ["/rec"]
ENTRYPOINT ["/entrypoint.sh"]
CMD ["rtpengine"]

EXPOSE 23000-65535/udp 22222/udp

RUN apt-get update && apt-get install -y --no-install-recommends \
  curl \
  iproute2 \
  iptables \
  libglib2.0-0 \
  libavcodec-extra \
  libavfilter8 \
  libcurl4 \
  libevent-2.1-7 \
  libevent-pthreads-2.1-7 \
  libhiredis0.14 \
  libip6tc2 \
  libiptc0 \
  libjson-glib-1.0-0 \
  libmariadb3 \
  libmnl0 \
  libnftnl11 \
  libopus0 \
  libpcap0.8 \
  libpcre3 \
  libspandsp2 \
  libssl3 \
  libwebsockets17 \
  libxmlrpc-core-c3 \
  net-tools \
  procps \
  sudo \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=rtpengine /usr/src/rtpengine/daemon/rtpengine /usr/local/bin/
COPY --from=rtpengine-recording /usr/src/rtpengine/recording-daemon/rtpengine-recording /usr/local/bin/
COPY ./entrypoint.sh /entrypoint.sh
RUN echo '%sudo   ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/nopasswd && \
  groupadd --gid 1000 rtpengine && \
  useradd --uid 1000 --gid rtpengine -G sudo --shell /bin/bash --create-home rtpengine
USER rtpengine
WORKDIR /home/rtpengine
COPY ./rtpengine.conf .
