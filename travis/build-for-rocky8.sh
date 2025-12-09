#!/bin/sh
#
# Build the hyrax-dependencies binary tar ball for use with libdap and BES 
# docker builds. Uses the opendap/centos6_hyrax_builder:latest docker container
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
    echo  "$@" | awk '{ print "# rocky8 - "$0;}'  >&2
}

# Need to have 64 bit rpc code!
export CPPFLAGS="${CPPFLAGS:-""} -I/usr/include/tirpc"
export LDFLAGS="${LDFLAGS:-""} -ltirpc"

# Why no libcurl already? No one knows...
export CPPFLAGS="${CPPFLAGS:-""} -I/usr/include/curl"
export LDFLAGS="${LDFLAGS:-""} -lcurl"

# Why no sqlite already? Installed from yum! No one knows...
#export CPPFLAGS="${CPPFLAGS:-""} -I/usr/include"
#export LDFLAGS="${LDFLAGS:-""} -lsqlite"

loggy "$HR"
loggy "BEGIN $0"
loggy "Inside the docker container."
loggy "  BUILD_NUMBER: $BUILD_NUMBER"
loggy "        prefix: $prefix"
loggy "          HOME: $HOME"
loggy "          PATH: $PATH"
loggy "       LDFLAGS: $LDFLAGS"
loggy "      CPPFLAGS: $CPPFLAGS"
loggy "- - - - - - - - - - - - - - - - - - - - -"
loggy "redhat-release: '$(cat /etc/redhat-release)'"
loggy "      uname -a: '$(uname -a)'"
loggy " ldd --version: '$(ldd --version | head -1)'"
loggy "- - - - - - - - - - - - - - - - - - - - -"
loggy "pkg-config --list-all:"
loggy "$(pkg-config --list-all)"
loggy "- - - - - - - - - - - - - - - - - - - - -"
loggy "ENVIRONMENT:"
loggy "$(env)"
loggy "- - - - - - - - - - - - - - - - - - - - -"
loggy ""
loggy "Running dnf update"
dnf -y update

# Assume that the docker container has been started with the cloned repo
# mounted so it appears within 'root.'
cd /root/hyrax-dependencies

loggy "- - - - - - - - - - - - - - - - - - - - -"
loggy "Running: make for-travis"
make -j16 for-travis

make list-built

loggy "END - $0"
loggy "$HR"
