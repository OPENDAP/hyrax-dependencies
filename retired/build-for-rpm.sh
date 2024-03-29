#!/bin/sh
#
# Build the hyrax-dependencies binary tar ball for use with libdap and BES 
# RPM builds. Uses the opendap/centos6_hyrax_builder:latest docker container
# (or the CentOS7 version).
#
# Modified to take an optional parameter that denotes the version of the C++
# compiler to use. Since C6 lacks a C++-11 compiler, this can be used to suppress
# building some of the dependencies. jhrg 10/28/19

# -e: Exit immediately if a command, command in a pipeline, etc., fails
# -u: Treat unset variables in substitutions as errors (except for @ and *)
set -eu

# Change to building our own sqlite3 library - C7's is too old
# yum -y install sqlite-devel
# for Centos8, we may need 'sqlite-libs,' too.

# Hack - update this container and remove this or switch to the vanilla
# CentOS 7 container and use the Docker file. jhrg 3/3/21
yum -y install libpng-devel

cd /root/hyrax-dependencies

# Build cmake and sqlite3 because C7 comes with versions that are too old
make -j16 cmake
make -j16 sqlite3

make -j16 ci-part-1
make -j16 ci-part-2
make -j16 ci-part-3
make -j16 ci-part-4
