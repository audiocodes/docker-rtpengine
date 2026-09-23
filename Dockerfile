FROM debian:trixie-slim

VOLUME ["/rec"]
ENTRYPOINT ["/entrypoint.sh"]
CMD ["rtpengine"]
ENV RTPENGINE_VER=26.2.1.2

EXPOSE 23000-65535/udp 22222/udp

RUN groupadd --gid 1000 rtpengine \
  && useradd --uid 1000 --gid rtpengine -G sudo --shell /bin/bash --create-home rtpengine \
  && apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  curl \
  less \
  libavcodec-extra \
  net-tools \
  sudo \
  && ARCH=$(dpkg --print-architecture) \
  && curl -kLO https://github.com/sipwise/rtpengine/releases/download/mr${RTPENGINE_VER}/rtpengine-daemon_${RTPENGINE_VER}+0.mr${RTPENGINE_VER}+gh+trixie_${ARCH}.deb \
  && curl -kLO https://github.com/sipwise/rtpengine/releases/download/mr${RTPENGINE_VER}/rtpengine-recording-daemon_${RTPENGINE_VER}+0.mr${RTPENGINE_VER}+gh+trixie_${ARCH}.deb \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ./*.deb \
  && apt-get clean && rm -rf *.deb /var/lib/apt/lists/*

COPY ./entrypoint.sh /entrypoint.sh
RUN echo '%sudo   ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/nopasswd
USER rtpengine
WORKDIR /home/rtpengine
COPY --chown=rtpengine:rtpengine ./rtpengine.conf .
