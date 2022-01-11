#!/bin/sh
#
# Build the hyrax-dependencies binary tar ball for use with libdap and BES 
# RPM builds. Uses the opendap/centos6_hyrax_builder:latest docker container
# (or the CentOS7 version).
#
# Modified to take an optional parameter that denotes the version of the C++
# compiler to use. Since C6 lacks a C++-11 compiler, this can be used to supress
# building some of the dependencies. jhrg 10/28/19

# -e: Exit immediately if a command, command in a pipeline, etc., fails
# -u: Treat unset variables in substitutions as errors (except for @ and *)
set -eu

# printenv

# Hack - update this container and remove this or switch to the vanilla
# CentOS 7 container and use the Docker file. jhrg 3/3/21
# yum -y install libpng-devel

export CONFIGURE_FLAGS="--disable-shared"

cd /root/hyrax-dependencies

make -j7 ci-part-1
make -j7 ci-part-2
make -j7 ci-part-3

# (cd /root/hyrax-dependencies && make -j4 for-static-rpm)
