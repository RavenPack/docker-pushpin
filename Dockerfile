#
# Pushpin Dockerfile
#
# https://github.com/fanout/docker-pushpin
#

# Pull the base image
FROM ubuntu:22.04 as build

# Install deps
RUN \
  apt-get update && \
  apt-get install -y git pkg-config make g++ rustc cargo libssl-dev qtbase5-dev libzmq3-dev libboost-dev

WORKDIR /build

ENV VERSION 1.40.1

ADD https://github.com/fastly/pushpin/releases/download/v${VERSION}/pushpin-${VERSION}.tar.bz2 .

RUN tar xf pushpin-${VERSION}.tar.bz2 && mv pushpin-${VERSION} pushpin

WORKDIR /build/pushpin

RUN make RELEASE=1 PREFIX=/usr CONFIGDIR=/etc
RUN make RELEASE=1 PREFIX=/usr CONFIGDIR=/etc check
RUN make RELEASE=1 PREFIX=/usr CONFIGDIR=/etc INSTALL_ROOT=/build/out install

FROM ubuntu:22.04
MAINTAINER Justin Karneges <jkarneges@fastly.com>

RUN \
  apt-get update && \
  apt-get install -y --no-install-recommends libqt5core5a libqt5network5 libzmq5 && \
  apt-get -y autoremove && \
  apt-get -y clean && \
  rm -rf /var/lib/apt/lists/*

COPY --from=build /build/out/ /

# Add entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/

# Define default entrypoint and command
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["pushpin", "--merge-output"]

# Expose ports.
# - 7999: HTTP port to forward on to the app
# - 5560: ZMQ PULL for receiving messages
# - 5561: HTTP port for receiving messages and commands
# - 5562: ZMQ SUB for receiving messages
# - 5563: ZMQ REP for receiving commands
EXPOSE 7999
EXPOSE 5560
EXPOSE 5561
EXPOSE 5562
EXPOSE 5563
