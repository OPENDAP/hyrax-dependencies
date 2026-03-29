# Build a container that can compile the hyrax-dependencies, libdap4 and BES 
# github repos. This is designed to work with Travis CI and will need to have some 
# volumes mounted for input and output and then a script run to perform the build.
#
# Build the docker container using
# docker build -t <catchy name> .
#
# The 'docker run' command would look something like:
#  docker run --volume $HOME/install/centos6:/home/install
#  --volume $TRAVIS_BUILD_DIR:/home/hyrax-dependencies 
#  opendap/centos6_hyrax_builder /home/hyrax-dependencies/build-for-rpm.sh
#
# Where $HOME/install is the value of prefix for the Travis CI build of
# hyrax-dependencies, etc., and  $TRAVIS_BUILD_DIR has the cloned hyrax-dependencies repo
#
# Then push the docker container up to the docker hub
#  docker login [use opendap's creds]
#  ocker tag centos6_hyrax_builder opendap/centos6_hyrax_builder:x.y
#  docker push opendap/centos6_hyrax_builder:x.y
#
# Use an official CentOS6 or 7 runtime as a parent image (centos:centos6
# or centos:centos7)
#
# We no longer support CentOS 6.

FROM centos:centos7

# Set the working directory to /root
WORKDIR /root

# Install any needed packages specified in requirements.txt
RUN yum -y install gcc-c++ make cmake git flex bison autoconf automake libtool bc libsqlite3x-devel
RUN yum -y install openssl-devel libuuid-devel readline-devel libxml2-devel curl-devel libicu-devel
RUN yum -y install zlib-devel bzip2 bzip2-devel libjpeg-devel rpm-devel rpm-build redhat-rpm-config
RUN yum -y install openjpeg2-devel-2.3.1

# Define environment variables. These are needed by the Makefile(s) and autotools code.
ENV HOME /root
ENV prefix $HOME/install
ENV PATH $prefix/bin:$prefix/deps/bin:$PATH
