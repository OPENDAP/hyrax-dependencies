# Build a machine that can compile the hyrax-dependencies, libdap4 and BES.
# This is designed to work with Travis CI and will need to have some volumes
# for input and output mounted and then a script run to run the build.
#
# The 'docker run' command would look something like:
#
# docker run --volume $HOME/install/centos6:/home/install
# --volume $TRAVIS_BUILD_DIR:/home/hyrax-dependencies 
# opendap/centos6_hyrax_builder:latest /home/hyrax-dependencies/build-for-rpm.sh
#
# Where $HOME/install is the value of prefix for the Travis CI build of
# hyrax-dependencies, $TRAVIS_BUILD_DIR hows the cloned hyeax-dependencies repo
# 
# Use an official CentOS6 runtime as a parent image
FROM centos:centos6

# Set the working directory to /home
WORKDIR /home

# Install any needed packages specified in requirements.txt
RUN yum -y install gcc-c++ cmake git flex bison autoconf automake libtool bc
RUN yum -y install openssl-devel libuuid-devel readline-devel libxml2-devel curl-devel libicu-devel
RUN yum -y install zlib-devel bzip2 bzip2-devel libjpeg-devel rpm-devel rpm-build redhat-rpm-config

# Define environment variable
ENV prefix /home/install
