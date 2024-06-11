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

# -e: Exit immediately if a command, command in a pipeline, etc., fails
# -u: Treat unset variables in substitutions as errors (except for @ and *)
set -eu

dnf -y update

# Build only the static libraries so that when these are used during the BES
# RPM build we have packages that others can install. jhrg 2/8/22
export CONFIGURE_FLAGS="--disable-shared"
export CPPFLAGS=-I/usr/include/tirpc
export LDFLAGS=-ltirpc

# Assume that the docker container has been started with the cloned repo
# mounted so it appears within 'root.'
cd /root/hyrax-dependencies

make -j16 sqlite3

make -j16 ci-part-1
make -j16 ci-part-2
make -j16 ci-part-3
make -j16 ci-part-4
make list-built
