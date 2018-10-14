#!/bin/sh
#
# Build the hyrax-dependencies binary tar ball for use with libdap and BES 
# RPM builds. Uses the opendap/centos6_hyrax_builder:latest docker container
# (or the CentOS7 version).

# run the script like:
# docker run --volume $prefix/deps/centos6:/home/install 
# --volume `pwd`:/home/hyrax-dependencies 
# centos6_hyrax_builder /home/hyrax-dependencies/build-for-rpm.sh

set -eux

df -h
printenv

(cd /home/hyrax-dependencies && make -j4 for-static-rpm)
 