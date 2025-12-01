FROM ubuntu:20.04

WORKDIR /root

RUN apt-get -y update
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata
RUN apt-get -y install libcurl4-openssl-dev make cmake ninja-build golang-go g++ gcc libcppunit-dev libbz2-dev libssl-dev uuid-dev libtool
RUN apt-get -y install flex bison autoconf automake libreadline-dev libicu-dev libxml2-dev libjpeg-dev bzip2
RUN apt-get -y install git curl xz-utils debhelper devscripts bc libopenjp2-7-dev libproj-dev

ENV HOME /root
ENV prefix $HOME/install
ENV PATH $prefix/bin:$prefix/deps/bin:$PATH
