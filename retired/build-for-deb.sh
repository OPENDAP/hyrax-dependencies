#!/bin/sh
# Build the hyrax-dependencies binary tar ball for use with libdap and BES
# debian builds.

set -eu

printenv

(cd /root/hyrax-dependencies && make -j4 for-static-rpm)

