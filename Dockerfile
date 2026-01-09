ARG ALPINE_VERSION=latest
FROM alpine:${ALPINE_VERSION} AS builder

ARG LIBTORRENT_VERSION
ARG RTORRENT_VERSION
ARG FLOOD_VERSION
ARG TARGETARCH

RUN set -eux; \
    apk add --no-cache \
      build-base \
      autoconf \
      automake \
      libtool \
      git \
      curl-dev \
      openssl-dev \
      zlib-dev \
      linux-headers \
      pkgconf \
      libsigc++-dev \
      xmlrpc-c-dev \
      ncurses-dev \
      nodejs \
      npm \
      ca-certificates \
	  curl \
	  pkgconfig \
	  cppunit-dev \
	  tar \
	  xz

WORKDIR /src

RUN set -eux; \
    git clone \
    --branch "$LIBTORRENT_VERSION" \
    --depth 1 \
    --single-branch \
    https://github.com/rakshasa/libtorrent.git; \
    git clone \
    --branch "$RTORRENT_VERSION" \
    --depth 1 \
    --single-branch \
    https://github.com/rakshasa/rtorrent.git; \
    git clone \
    --branch "$FLOOD_VERSION" \
    --depth 1 \
    --single-branch \
    https://github.com/jesec/flood.git

WORKDIR /src/libtorrent
RUN set -eux; \
    autoreconf -ivf; \
    ./configure; \
    make -j"$(($(nproc) - 1))"; \
	make install; \
    make install DESTDIR=/libtorrent-root

WORKDIR /src/rtorrent
RUN set -eux; \
    autoreconf -ivf; \
    ./configure --with-xmlrpc-c; \
    make -j"$(($(nproc) - 1))"; \
    make install DESTDIR=/rtorrent-root

WORKDIR /src/flood
RUN set -eux; \
    npm install; \
    npm run build

RUN set -eux; \
	mkdir -p /s6-overlay; \
    case "$TARGETARCH" in \
      amd64) S6_ARCH=x86_64 ;; arm64) S6_ARCH=aarch64 ;; \
      arm) S6_ARCH=armhf ;; ppc64le) S6_ARCH=powerpc64le ;; \
      s390x) S6_ARCH=s390x ;; *) S6_ARCH="$TARGETARCH" ;; \
    esac; \
    URL=https://github.com/just-containers/s6-overlay/releases/latest/download; \
    for pkg in noarch ${S6_ARCH} symlinks-noarch symlinks-arch; do \
        curl -fsSL -O "$URL/s6-overlay-${pkg}.tar.xz"; \
        tar -xJf s6-overlay-${pkg}.tar.xz -C /s6-overlay; \
    done

RUN set -eux; \
	mkdir -p /target /target/flood; \
	rm -rf /libtorrent-root/usr/local/include; \
	rm -rf /libtorrent-root/usr/local/lib/libtorrent.la; \
	rm -rf /libtorrent-root/usr/local/lib/pkgconfig; \
	cp -a /libtorrent-root/. /target; \
	cp -a /rtorrent-root/. /target; \
	cp -a /src/flood/dist/. /target/flood; \
	cp -a /s6-overlay/. /target


FROM alpine:${ALPINE_VERSION}

RUN set -eux; \
    apk add --no-cache \
        libstdc++ \
        libgcc \
        openssl \
        zlib \
        ncurses-libs \
        libsigc++ \
        xmlrpc-c \
        tzdata \
        nodejs \
        shadow \
        ca-certificates \
		coreutils \
		curl

COPY --from=builder /target /
COPY rootfs/ /
COPY rtorrent.rc /

ENV PUID=1000 \
    PGID=1000 \
    CONFIG_DIR=/config \
    FLOOD_PORT=3000 \
    DOWNLOAD_DIR=/downloads \
    WATCH_DIR=/watched \
    LD_LIBRARY_PATH=/usr/local/lib \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2

EXPOSE 3000 49164 49164/udp

ENTRYPOINT ["/init"]
