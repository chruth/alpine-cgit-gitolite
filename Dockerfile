FROM chruth/alpine-base:latest

# build options
ARG \
  MAKEOPTS=" \
    LUA_PKGCONFIG=lua5.4 \
    NO_GETTEXT=YesPlease \
    NO_ICONV=YesPlease \
    NO_REGEX=NeedsStartEnd \
    NO_SVN_TESTS=YesPlease \
    NO_TCLTK=YesPlease \
    prefix=/usr"

COPY rootfs /

# install packages
RUN \
  # build packages
  apk add --update --no-cache --virtual=build-dependencies \
    g++ \
    gcc \
    make \
    lua5.4-dev \
    zlib-dev \
    openssl-dev \
    asciidoc && \
  # runtime packages
  apk add --update --no-cache \
    busybox-suid \
    uwsgi \
    uwsgi-cgi \
    git-daemon \
    lua5.4 \
    lua5.4-ossl \
    nginx \
    py3-markdown \
    py3-pygments \
    python3 \
    tar \
    xz \
    perl \
    openssh && \
  # build cgit
  git clone https://git.zx2c4.com/cgit /tmp/cgit && cd /tmp/cgit && \
  git submodule init && git submodule update && \
  git apply --unsafe-paths --directory /tmp/cgit /files/patches/cgit/*.patch && \
  make all ${MAKEOPTS} && \
  make install ${MAKEOPTS} CGIT_SCRIPT_PATH=/app CGIT_CONFIG=/config/cgitrc && \
  # install gitolite
  git clone https://github.com/sitaramc/gitolite /tmp/gitolite && \
  git apply --unsafe-paths --directory /tmp/gitolite /files/patches/gitolite/*.patch && \
  mkdir -p /usr/lib/gitolite && \
  /tmp/gitolite/install -to /usr/lib/gitolite/ && \
  # make scripts executable
  chmod +x /etc/s6-overlay/scripts/* && \
  # cleanup
  apk del --purge build-dependencies && \
  rm -rf /tmp/*

EXPOSE 80 22

VOLUME ["${APP_DIR}"]
