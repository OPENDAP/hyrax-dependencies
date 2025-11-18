#!/bin/sh
#
# Build the hyrax-dependencies binary tar ball for use with libdap and BES 
# RPM builds. Uses the opendap/centos6_hyrax_builder:latest docker container
# (or the CentOS7 or CentOS-Stream8 version).
#
# Modified to take an optional parameter that denotes the version of the C++
# compiler to use. Since C6 lacks a C++-11 compiler, this can be used to suppress
# building some of the dependencies. jhrg 10/28/19
# Removed that for C7 anc CS8. jhrg 2/8/22
#
# Now used for the rocky8 build. No change from the centos-stream8. jhrg 5/7/24

# -e: Exit immediately if a command, command in a pipeline, etc., fails
# -u: Treat unset variables in substitutions as errors (except for @ and *)

set -eu

HR="#########################################################################"
###########################################################################
# loggy()
function loggy(){
    echo  "$@" | awk '{ print "# "$0;}'  >&2
}

loggy "$HR"
loggy "BEGIN $0 - In docker image"
loggy "        prefix: $prefix"
loggy "redhat-release: $(cat /etc/redhat-release)"


loggy "Running dnf update"
dnf -y update

# Build only the static libraries so that when these are used during the BES
# RPM build we have packages that others can install. jhrg 2/8/22
#
# This is not needed when the 'for-static-rpm' target is used below. That is
# a more robust way to build the static packages since some of them might not
# use configure, but cmake, e.g. jhrg 10/10/25
#
# export CONFIGURE_FLAGS="--disable-shared"

export CPPFLAGS="-I/usr/include/tirpc"
loggy "CPPFLAGS: $CPPFLAGS"

export LDFLAGS="-ltirpc"
loggy " LDFLAGS: $LDFLAGS"

# Assume that the docker container has been started with the cloned repo
# mounted so it appears within 'root.'
cd /root/hyrax-dependencies

loggy "Running make"
make -j16 for-static-rpm
make list-built

# Now clean out the binary images, which are huge for a static build.
# NB prefix = /root/install, set by the Docker run command
loggy "Cleanup..."
rm -vf $prefix/deps/bin/{gdal_*,gdal[a-z]*,ogr*,gnm*,nearblack,testepsg}
rm -vrf $prefix/deps/proj-6/bin;
