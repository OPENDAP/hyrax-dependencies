#!/bin/sh
#
# Build the hyrax-dependencies binary tar ball for use with libdap and BES 
# RPM builds for RHEL9. Uses the docker container:
#     opendap/rocky9_hyrax_builder:latest
#
# To build it, first we set up the directory into which we will put the results:
#
#    install_dir=$HOME/rocky9/install
#    mkdir -p "$install_dir"
#
# And then we use this script to build it by running the script in the docker container:
#
#     docker run
#        --env prefix=/root/install
#        --volume $install_dir:/root/install
#        --volume $TRAVIS_BUILD_DIR:/root/hyrax-dependencies
#        opendap/rocky9_hyrax_builder:latest
#        /root/hyrax-dependencies/build-for-rocky9.sh
#
# We collect the results like this:
#    tar -C $HOME/rocky9/ -czvf $TRAVIS_BUILD_DIR/package/hyrax-dependencies-rocky9-static.tar.gz install
#

# -e: Exit immediately if a command, command in a pipeline, etc., fails
# -u: Treat unset variables in substitutions as errors (except for @ and *)
set -eu

# Formatted output shenanigans...
HR="#########################################################################"
###########################################################################
# loggy()
function loggy(){
    echo  "$@" | awk '{ print "# "$0;}'  >&2
}

loggy "$HR"
loggy "BEGIN $0"
loggy " Running in docker image."
loggy "        prefix: $prefix"
loggy "redhat-release: \"$(cat /etc/redhat-release)\""

loggy "Running dnf update"
dnf -y update

# Build only the static libraries so that when these are used during the BES
# RPM build we have packages that others can install. jhrg 2/8/22
#

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
rm -vrf $prefix/deps/proj-6/bin
