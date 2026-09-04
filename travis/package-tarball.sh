#!/bin/bash

# Build the numbered and "latest" tarballs for a hyrax-dependencies build and
# copy them into $TRAVIS_BUILD_DIR/package, where the deploy step picks them up.
# On a '*-test-deploy' branch, the "latest" tarball is given a '-test-deploy'
# suffix so it doesn't overwrite the real deploy artifact of the same name.
#
# Usage: package-tarball.sh <tar_base_dir> <name>
#   tar_base_dir - directory passed to 'tar -C' (it must contain 'install')
#   name         - used to build the tarball file names, e.g. 'build', 'rocky8', 'rocky9'

tar_base_dir="$1"
name="$2"

mkdir -vp "$TRAVIS_BUILD_DIR/package"

tarball_numbered="$TRAVIS_BUILD_DIR/package/hyrax-dependencies-$name-$TRAVIS_BUILD_NUMBER.tgz"
echo "# $name - tarball_numbered '$tarball_numbered'" >&2

if [[ "$TRAVIS_BRANCH" =~ -test-deploy$ ]]; then
    tarball_latest="$TRAVIS_BUILD_DIR/package/hyrax-dependencies-$name-test-deploy.tgz"
else
    tarball_latest="$TRAVIS_BUILD_DIR/package/hyrax-dependencies-$name.tgz"
fi
echo "# $name - tarball_latest '$tarball_latest'" >&2

tar -C "$tar_base_dir" -czvf "$tarball_numbered" install
cp -v "$tarball_numbered" "$tarball_latest"
