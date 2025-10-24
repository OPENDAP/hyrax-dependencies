
# collected option used to build GDAL. I put these here because typing them
# gets pretty tedious. jhrg 11/30/22

# we use -DCMAKE_INSTALL_PREFIX:PATH=$(prefix)/deps in the Makefile so that
# the installation prefix is set correctly. I didn't put that here because
# the value of $prefix - and env var - might not be substituted by the cmake
#
# Also in the Makefile -DCMAKE_C_FLAGS="-fPIC -O2" -DBUILD_SHARED_LIBS:bool=OFF
#
# program. jhrg 11/30/22

set (CMAKE_BUILD_TYPE Release CACHE STRING "" FORCE)

set (BUILD_PYTHON_BINDINGS OFF CACHE BOOL "" FORCE)
set (BUILD_JAVA_BINDINGS OFF CACHE BOOL "" FORCE)

# because PROJ-6 is found using $prefix, it is set in the Makefile
# PROJ_INCLUDE_DIR
# PROJ_LIBRARY_RELEASE

set (GDAL_BUILD_OPTIONAL_DRIVERS OFF CACHE BOOL "" FORCE)
set (OGR_BUILD_OPTIONAL_DRIVERS OFF CACHE BOOL "" FORCE)
set (GDAL_USE_INTERNAL_LIBS ON CACHE BOOL "" FORCE)
set (GDAL_USE_EXTERNAL_LIBS OFF CACHE BOOL "" FORCE)

set (GDAL_USE_XERCESC OFF CACHE BOOL "" FORCE)

set (GDAL_USE_HDF4 OFF CACHE BOOL "" FORCE)
set (GDAL_USE_HDF5 OFF CACHE BOOL "" FORCE)
set (GDAL_USE_NETCDF OFF CACHE BOOL "" FORCE)
set (GDAL_USE_CFITSIO OFF CACHE BOOL "" FORCE)

set (GDAL_USE_OPENJPEG ON CACHE BOOL "" FORCE)
set (GDAL_USE_SQLITE3 ON CACHE BOOL "" FORCE)

set (GDAL_ENABLE_DRIVER_GRIB ON CACHE BOOL "" FORCE)
set (GDAL_ENABLE_DRIVER_JP2OPENJPEG ON CACHE BOOL "" FORCE)
