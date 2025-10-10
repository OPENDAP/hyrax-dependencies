# Handwritten Makefile for the hyrax dependencies. Each dependency must be
# configured, compiled and installed. Some support testing. Some do
# not support parallel builds, with 'install' being particularly
# problematic. 
#
# This Makefile assumes that the environment variable 'prefix' has
# been set and that the directory $prefix/deps is the destination for
# these packages.
#
# Note that you can pass in extra flags for the configure scripts 
# using CONFIGURE_FLAGS=... and CMAKE_FLAGS opts on the command line.
#
# Removed the dependencies on the targets for individual libraries.
# This was complicating the build on Travis where some parts are present
# (e.g., cmake).

VERSION = 1.62

# If a site.mk file exists in the parent dir, include it. Use this
# to add site-specific info like values for SQLITE3_LIBS and SQLITE3_CFLAGS,
# which are needed to build the proj library in some obscure cases.

# jhrg 12/5/20
# Use this include file to define things to build that are
# site-specific. Use the Makefile variable 'site-deps.' If
# the file does not exist, no error is generated.
site-deps = 
-include ../hyrax-site.mk

# The names of the source code distribution files and and the dirs
# they unpack to.

aws_cdk=aws_sdk_cpp
aws_cdk_tag=1.11.665
# There is no dist - we pull this from github using a tag

bison=bison-3.3
bison_dist=$(bison).tar.xz

jpeg=jpeg-6b
jpeg_dist=jpegsrc.v6b.tar.gz

openjpeg=openjpeg-2.4.0
openjpeg_dist=$(openjpeg).tar.gz

sqlite3=sqlite-autoconf-3340000
sqlite3_dist=$(sqlite3).tar.gz

proj=proj-6.3.2
proj_dist=$(proj).tar.gz

gdal=gdal-3.2.1
gdal_dist=$(gdal).tar.gz

gridfields=gridfields-1.0.5
gridfields_dist=$(gridfields).tar.gz

# hdf4=hdf-4.2.16 retired - 5/8/24 ndap
hdf4=hdf4-hdf4.3.0.e
hdf4_dist=$(hdf4).tar.gz

hdfeos=hdfeos
hdfeos_dist=HDF-EOS2.19v1.00.tar.Z
# This version of HDF-EOS for HDF4 is broken. jhrg 5/7/23
# hdfeos_dist=HDF-EOS2.20v1.00.tar.Z

hdf5=hdf5-1.10.10
hdf5_dist=$(hdf5).tar.bz2

netcdf4=netcdf-490-e
netcdf4_dist=$(netcdf4).tar.gz

stare=STARE-1.1.0
stare_dist=$(stare).tar.bz2

# Packages that are built. jhrg 10/10/25

# I think only OSX needs the icu dependency. jhrg 10/29/20
# I Removed the icu dependency because it is not needed for OSX anymore. jhrg 10/11/24
.PHONY: $(deps)
deps = $(site-deps) bison jpeg openjpeg gridfields hdf4 \
hdfeos hdf5 netcdf4 sqlite3 proj gdal stare aws_cdk list-built

# Removed lots of stuff because for Docker builds, we can use any decent
# yum/rpm repo (e.g. EPEL). jhrg 8/18/21
#
# But... We use a special version of netCDF4 that includes calls to use/enable
# Direct I/O _writes_. While the public HDF5 library makes these available, the
# netCDF4 library does not. So, we added public calls for Direct I/O writes.
# jhrg 1/5/24
.PHONY: $(docker_deps)
docker_deps = $(site-deps) gridfields stare hdf4 hdfeos netcdf4 aws_cdk list-built

# NB The environment variable $prefix is assumed to be set.
src = src
defaults = --disable-dependency-tracking --enable-silent-rules
deps_clean = $(deps:%=%-clean)
deps_really_clean = $(deps:%=%-really-clean)

# This targets are used to build and manage the dependencies builds. jhrg 10/10/25
all: prefix-set
	for d in $(deps); do $(MAKE) $(MFLAGS) $$d; done

# Build everything  as static. When the BES is built and
# linked against these, the resulting modules will not need their
# dependencies installed since they will be statically linked to them.
# jhrg 4/7/15
.PHONY: for-static-rpm
for-static-rpm: prefix-set
	for d in $(deps); \
	    do CONFIGURE_FLAGS="--disable-shared" CMAKE_FLAGS="-DBUILD_SHARED_LIBS:bool=OFF" $(MAKE) $(MFLAGS) $$d; done

.PHONY: for-travis
for-travis: prefix-set
	for d in $(deps); do $(MAKE) $(MFLAGS) $$d; done

.PHONY: for-docker
for-docker: prefix-set
	for d in $(docker_deps); do $(MAKE) $(MFLAGS) $$d; done

clean: $(deps_clean)

.PHONY: really-clean
really-clean: $(deps_really_clean)

.PHONY: uninstall
uninstall: prefix-set
	-rm -rf $(prefix)/deps/*

.PHONY: dist
dist: really-clean
	(cd ../ && tar --create --file hyrax-dependencies-$(VERSION).tar \
	 --exclude='.*' --exclude='*~'  --exclude=extra_downloads \
	 --exclude=scripts --exclude=OSX_Resources hyrax-dependencies)

.PHONY: install
install:
	@echo "Nothing to do for install in hyrax-dependencies"

.PHONY: check
check:
	@echo "Nothing to do for check in hyrax-dependencies"

# These targets are 'support' targets for the main targets above. jhrg 10/10/25
.PHONY: prefix-set
prefix-set: rhel8
	@if test -z "$$prefix"; then \
	echo "The env variable 'prefix' must be set. See README"; exit 1; fi

.PHONY: rhel8
rhel8:
	@if test -f /etc/redhat-release; then \
	    if grep -q '8\.' /etc/redhat-release && echo $$CPPFLAGS | grep -q tirpc; then \
	        echo "RHEL 8 or variant found, and CPPFLAGS is set"; \
	    else \
	        echo "RHEL 8 and CPPFLAGS not set; source spath.sh"; \
	        exit 1; \
            fi; \
	fi

.PHONY: list-built
list-built:
	@echo
	@echo "*** Packages built and installed ***"
	@ls -1 *-install-stamp
	@echo "*** ---------------------------- ***"

# These two rules are here to suppress errors about these automatically-generated
# rules not existing. jhrg 1/27/21
.PHONY: list-built-clean
list-built-clean:

.PHONY: list-built-really-clean
list-built-really-clean:


# AWS C++ SDK
aws_cdk_src=$(src)/$(aws_cdk)-$(aws_cdk_tag)
aws_cdk_prefix=$(prefix)/deps

$(aws_cdk_src)-stamp:
	# tar -xzf downloads/$(aws_cdk_dist) -C $(src)
	git clone --depth 1 --branch $(aws_cdk_tag) --recurse-submodules https://github.com/aws/aws-sdk-cpp $(aws_cdk_src)
	echo timestamp > $(aws_cdk_src)-stamp

aws_cdk-configure-stamp:  $(aws_cdk_src)-stamp
	mkdir -p $(aws_cdk_src)/build
	(cd $(aws_cdk_src)/build \
	 && cmake .. -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=$(prefix)/deps -DBUILD_ONLY="s3" \
	 	-DAUTORUN_UNIT_TESTS=OFF $(CMAKE_FLAGS))
	echo timestamp > aws_cdk-configure-stamp

# We might want to use for development cmake --build . --config=Debug
aws_cdk-compile-stamp: aws_cdk-configure-stamp
	(cd $(aws_cdk_src)/build && cmake --build . --config=Debug --parallel)
	echo timestamp > aws_cdk-compile-stamp

# As above, cmake --install . --config=Debug
aws_cdk-install-stamp: aws_cdk-compile-stamp
	(cd $(aws_cdk_src)/build && cmake --install . --config=Debug)
	echo timestamp > aws_cdk-install-stamp

aws_cdk-clean:
	-rm aws_cdk-*-stamp
	-(cd  $(aws_cdk_src)/build && cmake --build . --target clean)

aws_cdk-really-clean: aws_cdk-clean
	-rm $(src)/$(aws_cdk)-*-stamp
	-rm -rf $(aws_cdk_src)

.PHONY: aws_cdk
aws_cdk: aws_cdk-install-stamp

# JPEG
jpeg_src=$(src)/$(jpeg)
jpeg_prefix=$(prefix)/deps

# Why use a 'stamp' file here instead of the directory itself? The
# directory's modification time is updated by the compile target, which
# means that the configure and compilation will be repeated until the
# compilation makes no change in the directory. The -stamp file will
# not be modified by the compile target
$(jpeg_src)-stamp:
	tar -xzf downloads/$(jpeg_dist) -C $(src)
	echo timestamp > $(jpeg_src)-stamp

jpeg-configure-stamp:  $(jpeg_src)-stamp
	(cd $(jpeg_src) && ./configure $(CONFIGURE_FLAGS) $(defaults) --prefix=$(jpeg_prefix) CFLAGS="-O2 -fPIC -Wno-implicit-int")
	echo timestamp > jpeg-configure-stamp

jpeg-compile-stamp: jpeg-configure-stamp
	(cd $(jpeg_src) && $(MAKE) $(MFLAGS))
	echo timestamp > jpeg-compile-stamp

jpeg-install-stamp: jpeg-compile-stamp
	mkdir -p $(jpeg_prefix)/bin
	mkdir -p $(jpeg_prefix)/man/man1
	mkdir -p $(jpeg_prefix)/lib
	mkdir -p $(jpeg_prefix)/include
	(cd $(jpeg_src) && $(MAKE) $(MFLAGS) -j1 install \
	&& cp libjpeg.a $(jpeg_prefix)/lib \
	&&  cp *.h $(jpeg_prefix)/include)
	echo timestamp > jpeg-install-stamp

jpeg-clean:
	-rm jpeg-*-stamp
	-(cd  $(jpeg_src) && $(MAKE) $(MFLAGS) clean)


jpeg-really-clean: jpeg-clean
	-rm $(src)/jpeg-*-stamp
	-rm -rf $(jpeg_src)

.PHONY: jpeg
jpeg: jpeg-install-stamp

# Bison 3 (Needed by libdap)
bison_src=$(src)/$(bison)
bison_prefix=$(prefix)/deps

$(bison_src)-stamp:
	tar -xf downloads/$(bison_dist) -C $(src)
	echo timestamp > $(bison_src)-stamp

bison-configure-stamp:  $(bison_src)-stamp
	(cd $(bison_src) && ./configure $(defaults) --prefix=$(bison_prefix))
	echo timestamp > bison-configure-stamp

bison-compile-stamp: bison-configure-stamp
	(cd $(bison_src) && $(MAKE) $(MFLAGS) CFLAGS=-Wno-incompatible-function-pointer-types)
	echo timestamp > bison-compile-stamp

bison-install-stamp: bison-compile-stamp
	(cd $(bison_src) && $(MAKE) $(MFLAGS) install)
	echo timestamp > bison-install-stamp

bison-clean:
	-rm bison-*-stamp
	-(cd  $(bison_src) && $(MAKE) $(MFLAGS) clean)

bison-really-clean: bison-clean
	-rm $(src)/bison-*-stamp	
	-rm -rf $(bison_src)

.PHONY: bison
bison: bison-install-stamp

# OpenJPEG
openjpeg_src=$(src)/$(openjpeg)
openjpeg_prefix=$(prefix)/deps

$(openjpeg_src)-stamp:
	tar -xzf downloads/$(openjpeg_dist) -C $(src)
	echo timestamp > $(openjpeg_src)-stamp

openjpeg-configure-stamp:  $(openjpeg_src)-stamp
	(cd $(openjpeg_src) \
	 && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=$(prefix)/deps \
	 -DCMAKE_C_FLAGS="-fPIC -O2" -DBUILD_SHARED_LIBS:bool=OFF \
	 -DCMAKE_POLICY_VERSION_MINIMUM=3.5)
	echo timestamp > openjpeg-configure-stamp

openjpeg-compile-stamp: openjpeg-configure-stamp
	(cd $(openjpeg_src) && $(MAKE) $(MFLAGS))
	echo timestamp > openjpeg-compile-stamp

openjpeg-install-stamp: openjpeg-compile-stamp
	(cd $(openjpeg_src) && $(MAKE) $(MFLAGS) -j1 install)
	echo timestamp > openjpeg-install-stamp

openjpeg-clean:
	-rm openjpeg-*-stamp
	-(cd  $(openjpeg_src) && $(MAKE) $(MFLAGS) clean)

openjpeg-really-clean: openjpeg-clean
	-rm $(src)/openjpeg-*-stamp	
	-rm -rf $(openjpeg_src)

.PHONY: openjpeg
openjpeg: openjpeg-install-stamp

sqlite3_src=$(src)/$(sqlite3)
sqlite3_prefix=$(prefix)/deps

$(sqlite3_src)-stamp:
	tar -xzf downloads/$(sqlite3_dist) -C $(src)
	echo timestamp > $(sqlite3_src)-stamp

sqlite3-configure-stamp:  $(sqlite3_src)-stamp
	(cd $(sqlite3_src) && ./configure $(CONFIGURE_FLAGS) $(defaults) \
	--prefix=$(sqlite3_prefix) --with-pic=yes )
	echo timestamp > sqlite3-configure-stamp

sqlite3-compile-stamp: sqlite3-configure-stamp
	(cd $(sqlite3_src) && $(MAKE) $(MFLAGS))
	echo timestamp > sqlite3-compile-stamp

sqlite3-install-stamp: sqlite3-compile-stamp
	(cd $(sqlite3_src) && $(MAKE) $(MFLAGS) -j1 install)
	echo timestamp > sqlite3-install-stamp

sqlite3-clean:
	-rm sqlite3-*-stamp
	-(cd  $(sqlite3_src) && $(MAKE) $(MFLAGS) uninstall clean)

sqlite3-really-clean: sqlite3-clean
	-rm $(src)/sqlite-*-stamp
	-rm -rf $(sqlite3_src)

.PHONY: sqlite3
sqlite3: sqlite3-install-stamp

# proj6 Make a special directory for this since HDFEOS also installs
# a 'proj.h' header and the hdf4 handler needs to find it. In the
# future, invert this, making HDFEOS use the special install. The
# hdf4 handler will have to be modifed to use a special set of de-
# pendencies. jhrg 10/29/20
proj_src=$(src)/$(proj)
proj_prefix=$(prefix)/deps/proj-6

$(proj_src)-stamp:
	tar -xzf downloads/$(proj_dist) -C $(src)
	echo timestamp > $(proj_src)-stamp

proj-configure-stamp: $(proj_src)-stamp
	(cd $(proj_src) && PATH=$(sqlite3_prefix)/bin:$(PATH) \
	SQLITE3_CFLAGS="-I$(sqlite3_prefix)/include -fPIC" \
	SQLITE3_LIBS="-L$(sqlite3_prefix)/lib -lsqlite3" \
	./configure $(CONFIGURE_FLAGS) $(defaults) --prefix=$(proj_prefix) \
	--disable-shared)
	echo timestamp > proj-configure-stamp

proj-compile-stamp: proj-configure-stamp
	(cd $(proj_src) && PATH=$(sqlite3_prefix)/bin:$(PATH) $(MAKE) $(MFLAGS))
	echo timestamp > proj-compile-stamp

proj-install-stamp: proj-compile-stamp
	(cd $(proj_src) && $(MAKE) $(MFLAGS) -j1 install)
	echo timestamp > proj-install-stamp

proj-clean:
	-rm proj-*-stamp
	-(cd  $(proj_src) && $(MAKE) $(MFLAGS) uninstall clean)

proj-really-clean: proj-clean
	-rm $(src)/proj-*-stamp	
	-rm -rf $(proj_src)

.PHONY: proj
proj: proj-install-stamp

gdal_src=$(src)/$(gdal)
gdal_prefix=$(prefix)/deps

$(gdal_src)-stamp:
	tar -xzf downloads/$(gdal_dist) -C $(src)
	echo timestamp > $(gdal_src)-stamp

gdal-configure-stamp: $(gdal_src)-stamp
	(cd $(gdal_src) && \
	CPPFLAGS=-I$(proj_prefix)/include \
	LDFLAGS="$(LDFLAGS) -lpthread -lm" \
	PKG_CONFIG_PATH=$(prefix)/deps/lib/pkgconfig \
	./configure $(CONFIGURE_FLAGS) --prefix=$(gdal_prefix) --with-pic \
	--with-openjpeg --without-jasper --disable-all-optional-drivers \
	--enable-driver-grib $(LIBPNG) --with-proj=$(proj_prefix) \
	--with-proj-extra-lib-for-test="-L$(prefix)/deps/lib -lsqlite3 -lstdc++" \
	--without-python --without-netcdf --without-hdf5 --without-hdf4 \
	--without-sqlite3 --without-pg --without-cfitsio)
	echo timestamp > gdal-configure-stamp

gdal-compile-stamp: gdal-configure-stamp
	(cd $(gdal_src) && $(MAKE) $(MFLAGS))
	echo timestamp > gdal-compile-stamp

# Force -j1 for install
gdal-install-stamp: gdal-compile-stamp
	(cd $(gdal_src) && $(MAKE) $(MFLAGS) -j1 install)
	echo timestamp > gdal-install-stamp

gdal-clean:
	-rm gdal-*-stamp
	-(cd  $(gdal_src) && $(MAKE) $(MFLAGS) clean)

gdal-really-clean: gdal-clean
	-rm $(gdal_src)-stamp
	-rm -rf $(gdal_src)

.PHONY: gdal
gdal: gdal-install-stamp

# Gridfields 
gridfields_src=$(src)/$(gridfields)
gridfields_prefix=$(prefix)/deps

$(gridfields_src)-stamp:
	tar -xzf downloads/$(gridfields_dist) -C $(src)
	echo timestamp > $(gridfields_src)-stamp

gridfields-configure-stamp:  $(gridfields_src)-stamp
	(cd $(gridfields_src) && ./configure $(CONFIGURE_FLAGS) $(defaults) --disable-netcdf \
	--prefix=$(gridfields_prefix) CXXFLAGS="-fPIC -O2")
	echo timestamp > gridfields-configure-stamp

gridfields-compile-stamp: gridfields-configure-stamp
	(cd $(gridfields_src) && $(MAKE) $(MFLAGS))
	echo timestamp > gridfields-compile-stamp

# Force -j1 for install
gridfields-install-stamp: gridfields-compile-stamp
	(cd $(gridfields_src) && $(MAKE) $(MFLAGS) -j1 install)
	echo timestamp > gridfields-install-stamp

gridfields-clean:
	-rm gridfields-*-stamp
	-(cd  $(gridfields_src) && $(MAKE) $(MFLAGS) clean)

gridfields-really-clean: gridfields-clean
	-rm $(gridfields_src)-stamp
	-rm -rf $(gridfields_src)

.PHONY: gridfields
gridfields: gridfields-install-stamp

# HDF4 
hdf4_src=$(src)/$(hdf4)
hdf4_prefix=$(prefix)/deps

$(hdf4_src)-stamp:
	tar -xzf downloads/$(hdf4_dist) -C $(src)
	echo timestamp > $(hdf4_src)-stamp

hdf4-configure-stamp:  $(hdf4_src)-stamp
	(cd $(hdf4_src) && ./configure $(CONFIGURE_FLAGS) $(defaults) CFLAGS=-w \
	--disable-fortran --enable-production --disable-netcdf \
	--with-pic --with-jpeg=$(jpeg_prefix) --enable-hdf4-xdr \
	--prefix=$(hdf4_prefix))
	echo timestamp > hdf4-configure-stamp

hdf4-compile-stamp: hdf4-configure-stamp
	(cd $(hdf4_src) && $(MAKE) $(MFLAGS))
	echo timestamp > hdf4-compile-stamp

# Force -j1 for install
# The copies of ncdump and ncgen installed by hdf4 are evil ;-)
# remove them to avoid in advertanly using them in tests (e.g.,
# fonc's tests). jhrg 4/10/15
hdf4-install-stamp: hdf4-compile-stamp
	(cd $(hdf4_src) && $(MAKE) $(MFLAGS) -j1 install)
	-rm $(hdf4_prefix)/bin/ncdump
	-rm $(hdf4_prefix)/bin/ncgen
	echo timestamp > hdf4-install-stamp

hdf4-clean:
	-rm hdf4-*-stamp
	-(cd  $(hdf4_src) && $(MAKE) $(MFLAGS) clean)

hdf4-really-clean: hdf4-clean
	-rm $(hdf4_src)-stamp
	-rm -rf $(hdf4_src)

.PHONY: hdf4
hdf4: 
	$(MAKE) $(MFLAGS) hdf4-install-stamp

# HDF EOS2 
hdfeos_src=$(src)/$(hdfeos)
hdfeos_prefix=$(prefix)/deps

$(hdfeos_src)-stamp:
	tar -xzf downloads/$(hdfeos_dist) -C $(src)
	echo timestamp > $(hdfeos_src)-stamp

hdfeos-configure-stamp:  $(hdfeos_src)-stamp
	(if test -f $(hdf4_prefix)/bin/h4cc; \
	then \
		cd $(hdfeos_src) \
		&& echo "Using h4cc from $(hdf4_prefix)/bin" \
		&& CC=$(hdf4_prefix)/bin/h4cc \
		   ./configure $(CONFIGURE_FLAGS) $(defaults) \
			--disable-fortran --enable-production	\
			--with-pic --enable-install-include \
			--with-hdf4=$(hdf4_prefix) --prefix=$(hdfeos_prefix); \
	else \
		cd $(hdfeos_src) \
		&& echo "Using stock gcc/++" \
		&& CPPFLAGS=-I$(prefix)/deps/include \
		   LDFLAGS=-L$(prefix)/deps/lib \
		   ./configure $(CONFIGURE_FLAGS) $(defaults) \
			--disable-fortran --enable-production	\
			--with-pic --enable-install-include \
			--prefix=$(hdfeos_prefix); \
	fi)
	echo timestamp > hdfeos-configure-stamp

hdfeos-compile-stamp: hdfeos-configure-stamp
	(cd $(hdfeos_src) && $(MAKE) $(MFLAGS) \
		CFLAGS="-Wno-implicit-int  -Wno-implicit-function-declaration")
	echo timestamp > hdfeos-compile-stamp

# Force -j1 for install
hdfeos-install-stamp: hdfeos-compile-stamp
	(cd $(hdfeos_src) && $(MAKE) $(MFLAGS) -j1 install)
	echo timestamp > hdfeos-install-stamp

hdfeos-clean:
	-rm hdfeos-*-stamp
	-(cd  $(hdfeos_src) && $(MAKE) $(MFLAGS) clean)

hdfeos-really-clean: hdfeos-clean
	-rm $(hdfeos_src)-stamp
	-rm -rf $(hdfeos_src)

.PHONY: hdfeos
hdfeos:
	$(MAKE) $(MFLAGS) hdfeos-install-stamp

# HDF5 
hdf5_src=$(src)/$(hdf5)
hdf5_prefix=$(prefix)/deps

$(hdf5_src)-stamp:
	tar -xjf downloads/$(hdf5_dist) -C $(src)
	echo timestamp > $(hdf5_src)-stamp

hdf5-configure-stamp:  $(hdf5_src)-stamp
	(cd $(hdf5_src) && ./configure $(CONFIGURE_FLAGS) \
	 $(hdf5_configure_flags) $(defaults) --prefix=$(hdf5_prefix) \
	 CFLAGS="-fPIC -O2 -w")
	echo timestamp > hdf5-configure-stamp

hdf5-compile-stamp: hdf5-configure-stamp
	(cd $(hdf5_src) && $(MAKE) $(MFLAGS))
	echo timestamp > hdf5-compile-stamp

# Force -j1 for install
hdf5-install-stamp: hdf5-compile-stamp
	(cd $(hdf5_src) && $(MAKE) $(MFLAGS) -j1 install)
	echo timestamp > hdf5-install-stamp

hdf5-clean:
	-rm hdf5-*-stamp
	-(cd  $(hdf5_src) && $(MAKE) $(MFLAGS) clean)

hdf5-really-clean: hdf5-clean
	-rm $(hdf5_src)-stamp
	-rm -rf $(hdf5_src)

.PHONY: hdf5
hdf5: hdf5-install-stamp

# netcdf4 
netcdf4_src=$(src)/$(netcdf4)
netcdf4_prefix=$(prefix)/deps

$(netcdf4_src)-stamp:
	tar -xzf downloads/$(netcdf4_dist) -C $(src)
	echo timestamp > $(netcdf4_src)-stamp

netcdf4-configure-stamp:  $(netcdf4_src)-stamp
	(cd $(netcdf4_src) && ./configure $(CONFIGURE_FLAGS) $(defaults) \
	--prefix=$(netcdf4_prefix) CPPFLAGS=-I$(hdf5_prefix)/include	\
	CFLAGS="-fPIC -O2" LDFLAGS=-L$(hdf5_prefix)/lib)
	echo timestamp > netcdf4-configure-stamp

netcdf4-compile-stamp: netcdf4-configure-stamp
	(cd $(netcdf4_src) && $(MAKE) $(MFLAGS))
	echo timestamp > netcdf4-compile-stamp

# Force -j1 for install
netcdf4-install-stamp: netcdf4-compile-stamp
	(cd $(netcdf4_src) && $(MAKE) $(MFLAGS) -j1 install)
	echo timestamp > netcdf4-install-stamp

netcdf4-clean:
	-rm netcdf4-*-stamp
	-(cd  $(netcdf4_src) && $(MAKE) $(MFLAGS) clean)

netcdf4-really-clean: netcdf4-clean
	-rm $(netcdf4_src)-stamp
	-rm -rf $(netcdf4_src)

.PHONY: netcdf4
netcdf4: netcdf4-install-stamp

stare_src=src/$(stare)
stare_prefix=$(prefix)/deps

#STARE
$(src)/$(stare)-stamp:
	tar -xjf downloads/$(stare_dist) -C $(src)
	echo timestamp > $(src)/$(stare)-stamp

stare-configure-stamp: $(src)/$(stare)-stamp
	mkdir -p $(stare_src)/build
	(cd $(stare_src)/build && cmake .. \
		-DCMAKE_INSTALL_PREFIX:PATH=$(stare_prefix) \
		-DCMAKE_POLICY_VERSION_MINIMUM=3.5) 
	echo timestamp > stare-configure-stamp

stare-compile-stamp: stare-configure-stamp
	(cd $(stare_src)/build && $(MAKE) $(MFLAGS))
	echo timestamp > stare-compile-stamp

stare-install-stamp: stare-compile-stamp
	(cd $(stare_src)/build && $(MAKE) $(MFLAGS) install)
	echo timestamp > stare-install-stamp

stare-clean:
	-rm stare-*-stamp
	-(cd  $(stare_src)/build && $(MAKE) $(MFLAGS) clean)
	-rm -rf $(stare_src)/build

stare-really-clean: stare-clean
	-rm $(src)/$(stare)-stamp
	-rm -rf $(src)/$(stare)

.PHONY: stare
stare: stare-install-stamp
