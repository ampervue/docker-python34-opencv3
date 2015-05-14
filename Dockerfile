FROM ubuntu:trusty

# https://github.com/ampervue/docker-python34-opencv3

MAINTAINER David Karchmer <dkarchmer@ampervue.com>

#####################################################################
#
# Image based on Ubuntu:14.04
#
#   with
#     - Python 3.4
#     - OpenCV 3 (built)
#     - FFMPEG (built)
#   plus a bunch of build/web essentials via wheezy
#   including MySQL and Postgres clients:
#      https://github.com/docker-library/docs/tree/master/buildpack-deps
#
#####################################################################

ENV PYTHON_VERSION 3.4.3
ENV YASM_VERSION    1.3.0
ENV NUM_CORES 4

RUN apt-get -qq remove ffmpeg
# remove several traces of python
RUN apt-get purge -y python.*

RUN echo deb http://archive.ubuntu.com/ubuntu precise universe multiverse >> /etc/apt/sources.list; \
    apt-get update -qq && apt-get install -y --force-yes \
    ant \
    autoconf \
    automake \
    build-essential \
    curl \
    checkinstall \
    cmake \
    default-jdk \
    git \
    g++ \
    libavcodec-dev \
    libavformat-dev \
    libdc1394-22-dev \
    libfaac-dev \
    libgstreamer0.10-dev \
    libgstreamer-plugins-base0.10-dev \
    libgtk2.0-dev \
    libjpeg-dev \
    libjasper-dev \
    libmp3lame-dev \
    libopencore-amrnb-dev \
    libopencore-amrwb-dev \
    libpq-dev \
    libpng-dev \
    libssl-dev \
    libswscale-dev \
    libtbb-dev \
    libtheora-dev \
    libtiff4-dev \
    libtool \
    libxine-dev \
    libxvidcore-dev \
    libv4l-dev \
    libvorbis-dev \
    mercurial \
    openssl \
    pkg-config \
    postgresql-client \
    v4l-utils \
    wget \
    unzip; \
    apt-get clean

# gpg: key F73C700D: public key "Larry Hastings <larry@hastings.org>" imported
RUN gpg --keyserver ha.pool.sks-keyservers.net --recv-keys 97FC712E4C024BBEA48A61ED3A5CA953F73C700D

RUN set -x \
	&& mkdir -p /usr/src/python \
	&& curl -SL "https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tar.xz" -o python.tar.xz \
	&& curl -SL "https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tar.xz.asc" -o python.tar.xz.asc \
	&& gpg --verify python.tar.xz.asc \
	&& tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz \
	&& rm python.tar.xz* \
	&& cd /usr/src/python \
	&& ./configure --enable-shared --enable-unicode=ucs4 \
	&& make -j$(nproc) \
	&& make install \
	&& ldconfig \
	&& find /usr/local \
		\( -type d -a -name test -o -name tests \) \
		-o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
		-exec rm -rf '{}' + \
	&& rm -rf /usr/src/python

# make some useful symlinks that are expected to exist
RUN cd /usr/local/bin \
	&& ln -s easy_install-3.4 easy_install \
	&& ln -s idle3 idle \
	&& ln -s pip3 pip \
	&& ln -s pydoc3 pydoc \
	&& ln -s python3 python \
	&& ln -s python-config3 python-config

RUN pip install -U pip

WORKDIR /usr/local/src

RUN git clone --depth 1 https://github.com/l-smash/l-smash \
    && git clone --depth 1 git://git.videolan.org/x264.git \
    && hg clone https://bitbucket.org/multicoreware/x265 \
    && git clone --depth 1 git://source.ffmpeg.org/ffmpeg \
    && git clone https://github.com/Itseez/opencv.git \
    && git clone --depth 1 git://github.com/mstorsjo/fdk-aac.git \
    && git clone --depth 1 https://chromium.googlesource.com/webm/libvpx \
    && git clone --depth 1 git://git.opus-codec.org/opus.git \
    && git clone --depth 1 https://github.com/mulx/aacgain.git \
    && curl -Os http://www.tortall.net/projects/yasm/releases/yasm-${YASM_VERSION}.tar.gz \
    && tar xzvf yasm-${YASM_VERSION}.tar.gz

# Build YASM
# =================================
WORKDIR /usr/local/src/yasm-${YASM_VERSION}
RUN ./configure \
    && make -j ${NUM_CORES} \
    && make install
# =================================


# Build L-SMASH
# =================================
WORKDIR /usr/local/src/l-smash
RUN ./configure \
    && make -j ${NUM_CORES} \
    && make install
# =================================


# Build libx264
# =================================
WORKDIR /usr/local/src/x264
RUN ./configure --enable-static \
    && make -j ${NUM_CORES} \
    && make install
# =================================


# Build libx265
# =================================
WORKDIR  /usr/local/src/x265/build/linux
RUN cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr ../../source \
    && make -j ${NUM_CORES} \
    && make install
# =================================

# Build libfdk-aac
# =================================
WORKDIR /usr/local/src/fdk-aac
RUN autoreconf -fiv \
    && ./configure --disable-shared \
    && make -j ${NUM_CORES} \
    && make install
# =================================

# Build libvpx
# =================================
WORKDIR /usr/local/src/libvpx
RUN ./configure --disable-examples \
    && make -j ${NUM_CORES} \
    && make install
# =================================

# Build libopus
# =================================
WORKDIR /usr/local/src/opus
RUN ./autogen.sh \
    && ./configure --disable-shared \
    && make -j ${NUM_CORES} \
    && make install
# =================================



# Build OpenCV 3.x
# =================================
#RUN apt-get update -qq && apt-get install -y --force-yes libopencv-dev
WORKDIR /usr/local/src
RUN mkdir -p opencv/release
WORKDIR /usr/local/src/opencv/release
RUN cmake -D CMAKE_BUILD_TYPE=RELEASE \
          -D CMAKE_INSTALL_PREFIX=/usr/local \
          -D WITH_TBB=ON \
          -D BUILD_PYTHON_SUPPORT=ON \
          -D WITH_V4L=ON \
          ..

RUN make -j ${NUM_CORES} \
    && make install \
    && sh -c 'echo "/usr/local/lib" > /etc/ld.so.conf.d/opencv.conf' \
    && ldconfig
# =================================


# Build ffmpeg.
# =================================
RUN apt-get update -qq && apt-get install -y --force-yes \
    libass-dev

WORKDIR /usr/local/src/ffmpeg
RUN ./configure --extra-libs="-ldl" \
            --enable-gpl \
            --enable-libass \
            --enable-libfdk-aac \
            --enable-libfontconfig \
            --enable-libfreetype \
            --enable-libfribidi \
            --enable-libmp3lame \
            --enable-libopus \
            --enable-libtheora \
            --enable-libvorbis \
            --enable-libvpx \
            --enable-libx264 \
            --enable-libx265 \
            --enable-nonfree \
    && make -j ${NUM_CORES} \
    && make install
# =================================


# Remove all tmpfile
# =================================
WORKDIR /usr/local/
RUN rm -rf /usr/local/src
# =================================

