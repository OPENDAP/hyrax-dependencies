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
# using CONFIGURE_FLAGS=...opts on the command line.
#
# Removed the dependencies on the targets for individual libraries.
# This was complicating the build on Travis where some parts are present
# (e.g., cmake).

VERSION = 1.27

# If a site.mk file exists in the parent dir, include it. Use this
# to add site-specific info like values for SQLITE3_LIBS and SQLITE3_CFLAGS,
# which are needed to build the proj library in some obscure cases.

# jhrg 12/5/20
-include ../hyrax-deps-site.mk

# These options speed up the builds jhrg 12/08/20
# but defining this here breaks the static builds. jhrg 12/09/20
#CONFIGURE_FLAGS = --disable-dependency-tracking --enable-silent-rules

# Changed the sense of the BUILD_STARE env var so that if it's undefined,
# the library is built. Setting it to 'no' suppresses the library build.
# We don't build the library for CentOS6 (no C++11 on C6) or debian.
# jhrg 5/15/20
#
# No longer needed - we require c++-11 for all the builds now that
# CentOS 6 support has ended. jhrg 10/30/20
ifeq ("$(BUILD_STARE)", "no")
STARE =
else
STARE = stare
endif

# I think only OSX needs the icu dependency. jhrg 10/29/20
.PHONY: $(deps)
deps = bison jpeg openjpeg gridfields hdf4 hdfeos hdf5 netcdf4 fits	\
sqlite3 proj gdal4 icu stare list-built

# The 'all-static-deps' are the deps we need when all of the handlers are
# to be statically linked to the dependencies contained in this project - 
# and when we are not going to use _any_ RPMs. This makes for a bigger bes
# rpm distribution, but also one that is easier to install because it does
# not require any non-stock yum repo.
#
# Removed cmake which breaks CentOS 6 builds and can be gotten from
# RPMs for both C6 and C7. jhrg 10/10/18
.PHONY: $(all_static_deps)
all_static_deps = bison jpeg openjpeg gridfields hdf4 hdfeos hdf5	\
netcdf4 fits sqlite3 proj gdal4 stare list-built

# Build the dependencies for the Travis CI system. Travis uses Ubuntu 12
# as of 9/4/15 and while that distribution has many of the deps, it also
# lacks some key ones. It's easier to reuse this dependencies project than
# roll a new one. jhrg 9/4/15
.PHONY: $(travis_deps)
travis_deps = bison jpeg openjpeg gridfields hdf4 hdfeos hdf5 netcdf4	\
fits sqlite3 proj gdal4 stare list-built

# actions_build is used for testing. So named because of the new GitHub
# Actions workflow. jhrg 12/08/20
.PHONY: $(actions_build)
actions_build = bison sqlite3 proj gdal4 list-built

deps_clean = $(deps:%=%-clean)
deps_really_clean = $(deps:%=%-really-clean)

all: prefix-set
	for d in $(deps); do $(MAKE) $(MFLAGS) $$d; done

.PHONY: prefix-set
prefix-set:
	@if test -z "$$prefix"; then \
	echo "The env variable 'prefix' must be set. See README"; exit 1; fi

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


# Build everything but ICU, as static. Whwen the BES is built and
# linked against these, the resulting modules will not need their
# dependencies installed since they will be statically linked to them.
#
# Another difference between this and 'all' is that icu is not built.
# I want to avoid statically linking with that. Also, this does
# not yet work - netcdf4 and hdf5 need to have their builds 
# tweaked still. jhrg 4/7/15
# Done. This now works. Don't forget CONFIGURE_FLAGS. jhrg 5/6/15
# CONFIGURE_FLAGS now set by this target - no need to remember to do
# it. jhrg 11/29/17.
for-static-rpm: prefix-set
	for d in $(all_static_deps); \
		do CONFIGURE_FLAGS="--disable-shared" $(MAKE) $(MFLAGS) $$d; done

# Made this build statically since these are now used for the deb packages.
for-travis: prefix-set
	for d in $(travis_deps); do $(MAKE) $(MFLAGS) $$d; done

for-actions: prefix-set
	for d in $(actions_build); do $(MAKE) $(MFLAGS) $$d; done

clean: $(deps_clean)

really-clean: $(deps_really_clean)

uninstall: prefix-set
	-rm -rf $(prefix)/deps/*

dist: really-clean
	(cd ../ && tar --create --file hyrax-dependencies-$(VERSION).tar \
	 --exclude='.*' --exclude='*~'  --exclude=extra_downloads \
	 --exclude=scripts --exclude=OSX_Resources hyrax-dependencies)

install:
	@echo "Nothing to do for install in hyrax-dependencies"

check:
	@echo "Nothing to do for check in hyrax-dependencies"

# The names of the source code distribution files and and the dirs
# they unpack to.

cmake=cmake-3.11.3
cmake_dist=$(cmake).tar.gz

bison=bison-3.3
bison_dist=$(bison).tar.xz

jpeg=jpeg-6b
jpeg_dist=jpegsrc.v6b.tar.gz

# openjpeg=openjpeg-2.3.1
openjpeg=openjpeg-2.4.0
openjpeg_dist=$(openjpeg).tar.gz

sqlite3=sqlite-autoconf-3340000
sqlite3_dist=$(sqlite3).tar.gz

# This is a new and (4/2019) experimental API. Don't build it by
# default. It will break the HDFEOS code in the hdf4 handler. jhrg
# 4/24/2019
#
# Needed by GDAL3, build and install in a special directory under
# $prefix and use it only with gdal3. jhrg 10/30/20
proj=proj-6.3.2
proj_dist=$(proj).tar.gz

gdal2=gdal-2.1.1
gdal2_dist=$(gdal2).tar.xz

gdal3=gdal-3.1.3
gdal3_dist=$(gdal3).tar.gz

gdal4=gdal-3.1.4
gdal4_dist=$(gdal4).tar.gz

gridfields=gridfields-1.0.5
gridfields_dist=$(gridfields).tar.gz

hdf4=hdf-4.2.14
hdf4_dist=$(hdf4).tar.gz

hdfeos=hdfeos
hdfeos_dist=HDF-EOS2.19v1.00.tar.Z
# hdfeos_dist=HDF-EOS2.20v1.00.tar.Z

hdf5=hdf5-1.10.5
hdf5_dist=$(hdf5).tar.bz2

netcdf4=netcdf-c-4.7.3
netcdf4_dist=$(netcdf4).tar.gz

fits=cfitsio
fits_dist=$(fits)3270.tar.gz
#fits=cfitsio-3.49
#fits_dist=$(fits).tar.gz

icu=icu-3.6
icu_dist=icu4c-3_6-src.tgz

# stare=STARE-0.16.2-beta
stare=STARE-0.16.3
stare_dist=$(stare).tar.bz2

# NB The environment variable $prefix is assumed to be set.
src = src

defaults = --disable-dependency-tracking --enable-silent-rules

# Specific source packages below here

# JPEG
jpeg_src=$(src)/$(jpeg)
jpeg_prefix=$(prefix)/deps

# Why use a 'stamp' file here instead of the directory itself? The
# directory's modification time is updated by the comple target, which
# means that the configure and compilation will be repeated until the
# compilation makes no change in the directory. The -stamp file will
# not be modified by the compile target
$(jpeg_src)-stamp:
	tar -xzf downloads/$(jpeg_dist) -C $(src)
	echo timestamp > $(jpeg_src)-stamp

jpeg-configure-stamp:  $(jpeg_src)-stamp
	(cd $(jpeg_src) && ./configure $(CONFIGURE_FLAGS) $(defaults) --prefix=$(jpeg_prefix) CFLAGS="-O2 -fPIC")
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

# CMake

cmake_src=$(src)/$(cmake)
cmake_prefix=$(prefix)/deps

$(cmake_src)-stamp:
	tar -xzf downloads/$(cmake_dist) -C $(src)
	echo timestamp > $(cmake_src)-stamp

cmake-configure-stamp:  $(cmake_src)-stamp
	(cd $(cmake_src) && ./configure $(defaults) --prefix=$(cmake_prefix))
	echo timestamp > cmake-configure-stamp

cmake-compile-stamp: cmake-configure-stamp
	(cd $(cmake_src) && $(MAKE) $(MFLAGS))
	echo timestamp > cmake-compile-stamp

cmake-install-stamp: cmake-compile-stamp
	(cd $(cmake_src) && $(MAKE) $(MFLAGS) -j1 install)
	echo timestamp > cmake-install-stamp

cmake-clean:
	-rm cmake-*-stamp
	-(cd  $(cmake_src) && $(MAKE) $(MFLAGS) clean)

cmake-really-clean: cmake-clean
	-rm $(src)/cmake-*-stamp	
	-rm -rf $(cmake_src)

.PHONY: cmake
cmake: cmake-install-stamp

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
	(cd $(bison_src) && $(MAKE) $(MFLAGS))
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
	 -DCMAKE_C_FLAGS="-fPIC -O2" -DBUILD_SHARED_LIBS:bool=on)
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
	(cd $(sqlite3_src) && ./configure $(CONFIGURE_FLAGS) $(defaults) --prefix=$(sqlite3_prefix) )
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
	(cd $(proj_src) && SQLITE3_CFLAGS="-I$(sqlite3_prefix)/include -fPIC" \
	SQLITE3_LIBS="-L$(sqlite3_prefix)/lib -lsqlite3" \
	./configure $(CONFIGURE_FLAGS) $(defaults) --prefix=$(proj_prefix) \
	--disable-shared)
	echo timestamp > proj-configure-stamp

proj-compile-stamp: proj-configure-stamp
	(cd $(proj_src) && $(MAKE) $(MFLAGS))
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

# GDAL2
gdal2_src=$(src)/$(gdal2)
gdal2_prefix=$(prefix)/deps

$(gdal2_src)-stamp:
	tar -xJf downloads/$(gdal2_dist) -C $(src)
	echo timestamp > $(gdal2_src)-stamp

gdal2-configure-stamp:  $(gdal2_src)-stamp
	(cd $(gdal2_src) && \
	./configure $(CONFIGURE_FLAGS) --with-pic --without-python --without-sqlite3 \
	--without-pg --without-netcdf --prefix=$(gdal2_prefix) --with-openjpeg=$(openjpeg_prefix))
	echo timestamp > gdal2-configure-stamp

# 	CPPFLAGS="-I$(openjpeg_prefix)/include/openjpeg-2.3 $(CPPFLAGS)" 
#	LDFLAGS="-L$(proj_prefix)/lib/openjpeg-2.3 $(LDFLAGS)" 
#  	--with-openjpeg=$(openjpeg_prefix))

gdal2-compile-stamp: gdal2-configure-stamp
	(cd $(gdal2_src) && $(MAKE) $(MFLAGS))
	echo timestamp > gdal2-compile-stamp

# Force -j1 for install
gdal2-install-stamp: gdal2-compile-stamp
	(cd $(gdal2_src) && $(MAKE) $(MFLAGS) -j1 install)
	echo timestamp > gdal2-install-stamp

gdal2-clean:
	-rm gdal2-*-stamp
	-(cd  $(gdal2_src) && $(MAKE) $(MFLAGS) clean)

gdal2-really-clean: gdal2-clean
	-rm $(gdal2_src)-stamp
	-rm -rf $(gdal2_src)

.PHONY: gdal2
gdal2: gdal2-install-stamp

# GDAL4
gdal4_src=$(src)/$(gdal4)
gdal4_prefix=$(prefix)/deps

$(gdal4_src)-stamp:
	tar -xzf downloads/$(gdal4_dist) -C $(src)
	echo timestamp > $(gdal4_src)-stamp

# I disabled sqlite3 because it was failing on CentOS7. jhrg 12/08/20
gdal4-configure-stamp:  $(gdal4_src)-stamp
	(cd $(gdal4_src) && \
	PKG_CONFIG=$(openjpeg_prefix)/lib/pkgconfig \
	CPPFLAGS=-I$(proj_prefix)/include \
	OPENJPEG_CFLAGS="-I$(openjpeg_prefix)/include/openjpeg-2.4" \
	OPENJPEG_LIBS="-L$(openjpeg_prefix)/lib -lopenjp2" \
	./configure $(CONFIGURE_FLAGS) --prefix=$(gdal4_prefix) \
	--with-openjpeg --with-proj=$(proj_prefix) \
	--with-proj-extra-lib-for-test="-L$(prefix)/deps/lib -lsqlite3 -lstdc++" \
	--disable-all-optional-drivers --with-pic --without-python \
	--without-netcdf --without-hdf5 --without-hdf4 \
	--without-sqlite3 --without-pg --enable-driver-grib
	--with-cfitsio=no)
	echo timestamp > gdal4-configure-stamp

gdal4-compile-stamp: gdal4-configure-stamp
	(cd $(gdal4_src) && $(MAKE) $(MFLAGS))
	echo timestamp > gdal4-compile-stamp

# Force -j1 for install
gdal4-install-stamp: gdal4-compile-stamp
	(cd $(gdal4_src) && $(MAKE) $(MFLAGS) -j1 install)
	echo timestamp > gdal4-install-stamp

gdal4-clean:
	-rm gdal4-*-stamp
	-(cd  $(gdal4_src) && $(MAKE) $(MFLAGS) clean)

gdal4-really-clean: gdal4-clean
	-rm $(gdal4_src)-stamp
	-rm -rf $(gdal4_src)

.PHONY: gdal4
gdal4: gdal4-install-stamp

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
	--disable-fortran --enable-production --disable-netcdf		\
	--with-pic --with-jpeg=$(jpeg_prefix) --prefix=$(hdf4_prefix))
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
	(cd $(hdfeos_src) && ./configure CC=$(hdf4_prefix)/bin/h4cc	\
	$(CONFIGURE_FLAGS) $(defaults) --disable-fortran --enable-production	\
	--with-pic --enable-install-include --with-hdf4=$(hdf4_prefix)	\
	--prefix=$(hdfeos_prefix))
	echo timestamp > hdfeos-configure-stamp

hdfeos-compile-stamp: hdfeos-configure-stamp
	(cd $(hdfeos_src) && $(MAKE) $(MFLAGS))
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

# cfitsio 
fits_src=$(src)/$(fits)
fits_prefix=$(prefix)/deps

$(fits_src)-stamp:
	tar -xzf downloads/$(fits_dist) -C $(src)
	echo timestamp > $(fits_src)-stamp

fits-configure-stamp:  $(fits_src)-stamp
	(cd $(fits_src) && ./configure $(CONFIGURE_FLAGS) $(defaults) --prefix=$(fits_prefix))
	echo timestamp > fits-configure-stamp

fits-compile-stamp: fits-configure-stamp
	(cd $(fits_src) && $(MAKE) $(MFLAGS))
	echo timestamp > fits-compile-stamp

# Force -j1 for install
fits-install-stamp: fits-compile-stamp
	(cd $(fits_src) && $(MAKE) $(MFLAGS) -j1 install)
	echo timestamp > fits-install-stamp

fits-clean:
	-rm fits-*-stamp
	-(cd  $(fits_src) && $(MAKE) $(MFLAGS) clean)

fits-really-clean: fits-clean
	-rm $(fits_src)-stamp
	-rm -rf $(fits_src)

.PHONY: fits
fits: fits-install-stamp

# ICU 
icu_src=$(src)/$(icu)/source
icu_prefix=$(prefix)/deps

$(src)/$(icu)-stamp:
	tar -xzf downloads/$(icu_dist) -C $(src)
	echo timestamp > $(src)/$(icu)-stamp

icu-configure-stamp:  $(src)/$(icu)-stamp
	(cd $(icu_src) && \
	if uname -a | grep Darwin; then OS="osx"; \
	elif uname -a | grep Linux; then OS="linux"; \
	else OS="unknown"; fi && \
	if test "$OS" = "osx"; then ./runConfigureICU MacOSX --prefix=$(icu_prefix) --disable-layout --disable-samples; \
	elif test "$OS" = "linux"; then ./runConfigureICU Linux $(CONFIGURE_FLAGS) --prefix=$(icu_prefix) --disable-layout --disable-samples; \
	else ./configure $(CONFIGURE_FLAGS) $(defaults) --prefix=$(icu_prefix) --disable-layout --disable-samples; fi)
	echo timestamp > icu-configure-stamp

icu-compile-stamp: icu-configure-stamp
	(cd $(icu_src) && $(MAKE) $(MFLAGS) -j1)
	echo timestamp > icu-compile-stamp

# Force -j1 for install
icu-install-stamp: icu-compile-stamp
	(cd $(icu_src) && $(MAKE) $(MFLAGS) -j1 install)
	echo timestamp > icu-install-stamp

icu-clean:
	-rm icu-*-stamp
	-(cd  $(icu_src) && $(MAKE) $(MFLAGS) clean)

icu-really-clean: icu-clean
	-rm $(src)/$(icu)-stamp
	-rm -rf $(src)/$(icu)

.PHONY: icu
icu: icu-install-stamp

stare_src=src/$(stare)
stare_prefix=$(prefix)/deps

#STARE
$(src)/$(stare)-stamp:
	tar -xjf downloads/$(stare_dist) -C $(src)
	echo timestamp > $(src)/$(stare)-stamp

stare-configure-stamp: $(src)/$(stare)-stamp
	mkdir -p $(stare_src)/build
	(cd $(stare_src)/build && cmake .. \
		-DCMAKE_INSTALL_PREFIX:PATH=$(stare_prefix))
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
