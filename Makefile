##
# Install GDAL from within a docker container
#
# This Makefile is designed to be run from within a docker container in order to
# install GDAL.  The following is an example invocation:
#
# make -C /usr/local/src/gdal-docker install clean
#
# The targets in this Makefile are derived from the GDAL .travis.yml file
# (https://github.com/OSGeo/gdal/blob/trunk/.travis.yml).
#

# If grass support is required set the variable WITH_GRASS to the GRASS install
# directory.
ifdef WITH_GRASS
USE_GRASS := "--with-grass=$(WITH_GRASS)"
endif

# Version related variables.
GDAL_VERSION := $(shell cat ./gdal-checkout.txt)
OPENJPEG_DOWNLOAD := install-openjpeg-2.0.0-ubuntu12.04-64bit.tar.gz
FILEGDBAPI_DOWNLOAD := FileGDB_API_1_2-64.tar.gz
LIBECWJ2_DOWNLOAD := install-libecwj2-ubuntu12.04-64bit.tar.gz
MRSID_DIR = MrSID_DSDK-8.5.0.3422-linux.x86-64.gcc44
MRSID_DOWNLOAD := $(MRSID_DIR).tar.gz
LIBKML_DOWNLOAD := install-libkml-r864-64bit.tar.gz

# Dependencies satisfied by packages.
DEPS_PACKAGES := python-numpy python-dev libpq-dev libpng12-dev libjpeg-dev libgif-dev liblzma-dev libgeos-dev libcurl4-gnutls-dev libproj-dev libxml2-dev libexpat-dev libxerces-c-dev libnetcdf-dev netcdf-bin libpoppler-dev libspatialite-dev gpsbabel swig libhdf5-serial-dev libpodofo-dev poppler-utils libfreexl-dev unixodbc-dev libwebp-dev libepsilon-dev libgta-dev liblcms2-2 libpcre3-dev

# GDAL dependency targets.
GDAL_CONFIG := /usr/local/bin/gdal-config
BUILD_ESSENTIAL := /usr/share/build-essential
OPENJPEG_DEV := /usr/local/include/openjpeg-2.0
FILEGDBAPI_DEV := /usr/local/include/FileGDBAPI.h
LIBECWJ2_DEV := /usr/local/include/NCSECWClient.h
MRSID_DEV := /usr/local/include/lt_base.h
LIBHDF5_DEV := /usr/include/H5Cpp.h
DEPS_DEV := /usr/include/numpy	# Represents all dependency packages.
ORACLE_HOME := /opt/instantclient/

# Build tools.
SVN := /usr/bin/svn
WGET := /usr/bin/wget
UNZIP := /usr/bin/unzip
CMAKE := /usr/bin/cmake
GIT := /usr/bin/git
SCONS := /usr/bin/scons
ANT := /usr/bin/ant
ADD_APT_REPOSITORY := /usr/bin/add-apt-repository

# Number of processors available.
NPROC := $(shell nproc)

install: $(GDAL_CONFIG)

$(GDAL_CONFIG): /tmp/gdal  $(OPENJPEG_DEV) $(FILEGDBAPI_DEV) $(LIBECWJ2_DEV) $(MRSID_DEV) $(LIBKML_DEV) $(DEPS_DEV) 
	cd /tmp/gdal/gdal \
	&& ./configure \
		--prefix=/usr/local \
		--with-jpeg12 \
		--with-python \
		--with-poppler \
		--with-podofo \
		--with-spatialite \
		--with-mysql \
		--with-liblzma \
		--with-webp \
		--with-epsilon \
		--with-gta \
		--with-oci-include=$(ORACLE_HOME)/sdk/include \
        --with-oci-lib=$(ORACLE_HOME) \
		--with-ecw=/usr/local \
		--with-mrsid=/usr/local \
		--with-mrsid-lidar=/usr/local \
		--with-fgdb=/usr/local \
		--with-libkml \
		--with-hdf5 \
		--with-openjpeg=/usr/local \
	    $(USE_GRASS) \
	&& make -j$(NPROC) \
	&& make install \
	&& ldconfig

/tmp/gdal: $(SVN) $(BUILD_ESSENTIAL)
	$(SVN) checkout --quiet "http://svn.osgeo.org/gdal/$(GDAL_VERSION)/" /tmp/gdal/ \
	&& touch -c /tmp/gdal

$(OPENJPEG_DEV): /tmp/$(OPENJPEG_DOWNLOAD)
	tar -C /tmp -xzf /tmp/$(OPENJPEG_DOWNLOAD) \
	&& cp -r /tmp/install-openjpeg/include/* /usr/local/include \
	&& cp -r /tmp/install-openjpeg/lib/* /usr/local/lib
/tmp/$(OPENJPEG_DOWNLOAD): $(WGET)
	$(WGET) --no-verbose http://s3.amazonaws.com/etc-data.koordinates.com/gdal-travisci/$(OPENJPEG_DOWNLOAD) -O /tmp/$(OPENJPEG_DOWNLOAD) \
	&& touch -c /tmp/$(OPENJPEG_DOWNLOAD)

$(FILEGDBAPI_DEV): /tmp/$(FILEGDBAPI_DOWNLOAD)
	tar -C /tmp -xzf /tmp/$(FILEGDBAPI_DOWNLOAD) \
	&& cp -r /tmp/FileGDB_API/include/* /usr/local/include \
	&& cp -r /tmp/FileGDB_API/lib/* /usr/local/lib
/tmp/$(FILEGDBAPI_DOWNLOAD): $(WGET)
	$(WGET) --no-verbose http://s3.amazonaws.com/etc-data.koordinates.com/gdal-travisci/$(FILEGDBAPI_DOWNLOAD) -O /tmp/$(FILEGDBAPI_DOWNLOAD) \
	&& touch -c /tmp/$(FILEGDBAPI_DOWNLOAD)

$(LIBECWJ2_DEV): /tmp/$(LIBECWJ2_DOWNLOAD)
	tar -C /tmp -xzf /tmp/$(LIBECWJ2_DOWNLOAD) \
	&& cp -r /tmp/install-libecwj2/include/* /usr/local/include \
	&& cp -r /tmp/install-libecwj2/lib/* /usr/local/lib
/tmp/$(LIBECWJ2_DOWNLOAD): $(WGET)
	$(WGET) --no-verbose http://s3.amazonaws.com/etc-data.koordinates.com/gdal-travisci/$(LIBECWJ2_DOWNLOAD) -O /tmp/$(LIBECWJ2_DOWNLOAD) \
	&& touch -c /tmp/$(LIBECWJ2_DOWNLOAD)

$(MRSID_DEV): /tmp/$(MRSID_DOWNLOAD)
	tar -C /tmp -xzf /tmp/$(MRSID_DOWNLOAD) \
	&& cp -r /tmp/$(MRSID_DIR)/Raster_DSDK/include/* /usr/local/include \
	&& cp -r /tmp/$(MRSID_DIR)/Raster_DSDK/lib/* /usr/local/lib \
	&& cp -r /tmp/$(MRSID_DIR)/Lidar_DSDK/include/* /usr/local/include \
	&& cp -r /tmp/$(MRSID_DIR)/Lidar_DSDK/lib/* /usr/local/lib
/tmp/$(MRSID_DOWNLOAD): $(WGET)
	$(WGET) --no-verbose http://s3.amazonaws.com/etc-data.koordinates.com/gdal-travisci/$(MRSID_DOWNLOAD) -O /tmp/$(MRSID_DOWNLOAD) \
	&& touch -c /tmp/$(MRSID_DOWNLOAD)

$(LIBKML_DEV): /tmp/$(LIBKML_DOWNLOAD)
	tar -C /tmp -xzf /tmp/$(LIBKML_DOWNLOAD) \
	&& cp -r /tmp/install-libkml/include/* /usr/local/include \
	&& cp -r /tmp/install-libkml/lib/* /usr/local/lib
/tmp/$(LIBKML_DOWNLOAD): $(WGET)
	$(WGET) --no-verbose http://s3.amazonaws.com/etc-data.koordinates.com/gdal-travisci/$(LIBKML_DOWNLOAD) -O /tmp/$(LIBKML_DOWNLOAD) \
	&& touch -c /tmp/$(LIBKML_DOWNLOAD)

$(DEPS_DEV): /etc/apt/sources.list.d/ubuntugis-ubuntugis-unstable-trusty.list /etc/apt/sources.list.d/marlam-gta-trusty.list
	apt-get install -y $(DEPS_PACKAGES) && touch -c $(DEPS_DEV)

$(SVN): /tmp/apt-updated
	apt-get install -y subversion && touch -c $(SVN)

$(WGET): /tmp/apt-updated
	apt-get install -y wget && touch -c $(WGET)

$(UNZIP): /tmp/apt-updated
	apt-get install -y unzip && touch -c $(UNZIP)

$(CMAKE): /tmp/apt-updated
	apt-get install -y cmake && touch -c $(CMAKE)

$(GIT): /tmp/apt-updated
	apt-get install -y git && touch -c $(GIT)

$(BUILD_ESSENTIAL): /tmp/apt-updated
	apt-get install -y build-essential \
	&& touch -c $(BUILD_ESSENTIAL)

/etc/apt/sources.list.d/ubuntugis-ubuntugis-unstable-trusty.list: /usr/bin/add-apt-repository
	add-apt-repository -y ppa:ubuntugis/ubuntugis-unstable && apt-get update -y

/etc/apt/sources.list.d/marlam-gta-trusty.list: /usr/bin/add-apt-repository
	add-apt-repository -y ppa:marlam/gta && apt-get update -y

$(ADD_APT_REPOSITORY): /tmp/apt-updated
	apt-get install -y software-properties-common \
	&& touch -c $(ADD_APT_REPOSITORY)

/tmp/apt-updated:
	apt-get update -y && touch /tmp/apt-updated

# Remove build time dependencies.
clean:
	apt-get purge -y \
		software-properties-common \
		subversion \
		wget \
		build-essential \
		unzip \
		cmake \
		git \
	&& apt-get autoremove -y \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/partial/* /tmp/* /var/tmp/*

.PHONY: install clean
