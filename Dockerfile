##
# msmitherdc/grid-cloudhub
#
# This creates an Ubuntu derived base image that installs the latest GDAL
# Git checkout compiled with a GRiD needed drivers.  The build process
# is based on that defined in # <https://github.com/OSGeo/gdal/blob/trunk/.travis.yml>
#

# Ubuntu 14.04 Trusty Tahyr
FROM ubuntu:vivid

MAINTAINER Michael Smith <Michael.smith.erdc@gmail.com>

# Set up Instant Client
COPY instantclient_12_1 /opt/instantclient/

#Setup user
ARG UID
ARG GID
RUN addgroup --gid $GID gdalgroup
RUN adduser --no-create-home --disabled-login gdaluser  --gecos "" --uid $UID --gid $GID

ENV ORACLE_HOME=/opt/instantclient 
ENV LD_LIBRARY_PATH=${ORACLE_HOME}:/usr/lib 
ENV LIBKML_DOWNLOAD=install-libkml-r864-64bit.tar.gz
ENV FILEGDBAPI_DOWNLOAD=FileGDB_API_1_2-64.tar.gz 
ENV MRSID_DIR=MrSID_DSDK-8.5.0.3422-linux.x86-64.gcc44  
ENV MRSID_DOWNLOAD=MrSID_DSDK-8.5.0.3422-linux.x86-64.gcc44.tar.gz 

# Setup build env
RUN mkdir /build
RUN apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 16126D3A3E5C1192 \
  && add-apt-repository ppa:ubuntugis/ubuntugis-unstable -y \
  && apt-get update && apt-get install -y --fix-missing --no-install-recommends build-essential ca-certificates curl wget git libaio1 make cmake python-numpy python-dev python-software-properties software-properties-common  libc6-dev \
  && apt-get update && apt-get install -y --fix-missing --no-install-recommends openssh-client libpq-dev libpng12-dev libjpeg-dev libgif-dev liblzma-dev libgeos-dev libcurl4-gnutls-dev libproj-dev libxml2-dev libexpat-dev libxerces-c-dev libnetcdf-dev netcdf-bin libpoppler-dev libspatialite-dev swig libhdf5-serial-dev libpodofo-dev poppler-utils libfreexl-dev libwebp-dev libepsilon-dev libpcre3-dev \
  && apt-get remove --purge -y $BUILD_PACKAGES  && rm -rf /var/lib/apt/lists/*

#RUN dpkg --add-architecture i386 && apt-get update && apt-get install -y openjdk-8-jre:i386
# Getting libKML
RUN wget http://s3.amazonaws.com/etc-data.koordinates.com/gdal-travisci/${LIBKML_DOWNLOAD} -O /build/${LIBKML_DOWNLOAD} && \
 tar -C /build -xzf /build/${LIBKML_DOWNLOAD} && \
 cp -r /build/install-libkml/include/* /usr/local/include &&  \
 cp -r /build/install-libkml/lib/* /usr/local/lib \
 && rm -Rf /build/install-libkml 

RUN wget http://s3.amazonaws.com/etc-data.koordinates.com/gdal-travisci/${MRSID_DOWNLOAD} -O /build/${MRSID_DOWNLOAD} && \
  tar -C /build -xzf /build/${MRSID_DOWNLOAD} && \
  cp -r /build/${MRSID_DIR}/Raster_DSDK/include/* /usr/local/include && \
  cp -r /build/${MRSID_DIR}/Raster_DSDK/lib/* /usr/local/lib \
  && rm -Rf /build/${MRSID_DIR}

RUN wget --no-verbose http://s3.amazonaws.com/etc-data.koordinates.com/gdal-travisci/${FILEGDBAPI_DOWNLOAD} -O /build/${FILEGDBAPI_DOWNLOAD} && \
 tar -C /build -xzf /build/${FILEGDBAPI_DOWNLOAD} &&  \
 cp -r /build/FileGDB_API/include/* /usr/local/include && \
 cp -r /build/FileGDB_API/lib/* /usr/local/lib \
 && rm -Rf /build/FileGDB_API

RUN export ORACLE_HOME
RUN export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/instantclient 

RUN export ORACLE_HOME
RUN export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/instantclient 

ARG GDAL_VERSION
ADD gdal_configure.sh /build
RUN cd /build && \
    git clone https://github.com/OSGeo/gdal.git && \
    cd /build/gdal && \
    git checkout ${GDAL_VERSION} && \
    cd /build/gdal/gdal &&  \
    bash /build/gdal_configure.sh && \
    make && \
    make install && \
    ldconfig && \
    rm -Rf /build/gdal   

# Externally accessible data is by default put in /u02
WORKDIR /u02
VOLUME ["/u02"]

# Execute the gdal utilities as nobody, not root
USER gdaluser