
# Collected options used to build GDAL. I put these here because typing them
# gets pretty tedious. jhrg 11/30/22
#
# Pass this file to cmake using the -C option. jhrg 5/16/24

if(DEFINED gdal_prefix)
  message("dependencies prefix set to: ${gdal_prefix}")
else()
  message(FATAL_ERROR, "The gdal_prefix variable is not set.")
endif()

set (CMAKE_BUILD_TYPE Release CACHE STRING "" FORCE)
set (CMAKE_INSTALL_PREFIX ${gdal_prefix} CACHE STRING "" FORCE)

set (BUILD_PYTHON_BINDINGS OFF CACHE BOOL "" FORCE)
set (BUILD_JAVA_BINDINGS OFF CACHE BOOL "" FORCE)

set (BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)

set (GDAL_BUILD_OPTIONAL_DRIVERS OFF CACHE BOOL "" FORCE)
set (OGR_BUILD_OPTIONAL_DRIVERS OFF CACHE BOOL "" FORCE)

set (OPENJPEG_INCLUDE_DIR ${gdal_prefix}/include/openjpeg-2.4 CACHE STRING "" FORCE)
set (OPENJPEG_LIBRARY ${gdal_prefix}/lib/libopenjp2.a CACHE STRING "" FORCE)
set (GDAL_USE_OPENJPEG ON CACHE BOOL "" FORCE)

set (SQLite3_INCLUDE_DIR ${gdal_prefix}/include CACHE STRING "" FORCE)
set (SQLite3_LIBRARY ${gdal_prefix}/lib/libsqlite3.a CACHE STRING "" FORCE)

# sqlite3 builds using --enable-threadsafe; maybe the test is broken in 
# GDAL's cmake system? If this is not set, the cmake configuration step 
# fails. jhrg 5/20/24
set (ACCEPT_MISSING_SQLITE3_MUTEX_ALLOC ON CACHE BOOL "" FORCE)

set (PROJ_INCLUDE_DIR ${gdal_prefix}/proj-6/include CACHE STRING "" FORCE)
set (PROJ_LIBRARY_RELEASE ${gdal_prefix}/proj-6/lib/libproj.a CACHE STRING "" FORCE)

set (GDAL_USE_INTERNAL_LIBS ON CACHE BOOL "" FORCE)
set (GDAL_USE_EXTERNAL_LIBS OFF CACHE BOOL "" FORCE)

set (GDAL_USE_XERCESC OFF CACHE BOOL "" FORCE)

set (GDAL_USE_HDF4 OFF CACHE BOOL "" FORCE)
set (GDAL_USE_HDF5 OFF CACHE BOOL "" FORCE)
set (GDAL_USE_NETCDF OFF CACHE BOOL "" FORCE)
set (GDAL_USE_CFITSIO OFF CACHE BOOL "" FORCE)

set (GDAL_USE_TIFF_INTERNAL ON CACHE BOOL "" FORCE)
set (GDAL_USE_SQLITE3 ON CACHE BOOL "" FORCE)

set (GDAL_ENABLE_DRIVER_GRIB ON CACHE BOOL "" FORCE)
set (GDAL_ENABLE_DRIVER_OPENJPEG ON CACHE BOOL "" FORCE)
set (GDAL_ENABLE_DRIVER_JP2OPENJPEG ON CACHE BOOL "" FORCE)
