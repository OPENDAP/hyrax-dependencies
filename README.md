# hyrax-dependencies

`hyrax-dependencies` is the dependency build workspace for Hyrax/BES. It is not a monorepo for the third-party packages it builds. The repository's main job is to assemble, build, and install the native dependency stack used by Hyrax into `$prefix/deps`.

The handwritten [`Makefile`](/Users/jimg/src/opendap/hyrax_git/hyrax-dependencies/Makefile) is the operational source of truth for:

- dependency versions
- build order
- the dependency bundle version identified by `VERSION`
- package-specific configure and CMake flags
- platform workarounds
- install layout

Most dependency sources are expected as archives under [`downloads`](/Users/jimg/src/opendap/hyrax_git/hyrax-dependencies/downloads). One important exception is `aws_cdk`, which is cloned from GitHub during the build unless it is already present under [`src`](/Users/jimg/src/opendap/hyrax_git/hyrax-dependencies/src).

## Prerequisite

Before running any build that installs dependencies, set the `prefix` environment variable. It should point at the Hyrax installation prefix you want to use.

```sh
export prefix=/path/to/hyrax/install
```

Dependencies are installed under:

```text
$prefix/deps
```

The main BES build is then typically configured with:

```sh
./configure --with-dependencies="$prefix/deps" --prefix="$prefix"
```

In practice, operators often also add `$prefix/bin` and `$prefix/deps/bin` to `PATH`.

## Typical Builds

Build the full dependency set:

```sh
make
```

Equivalent explicit form:

```sh
make all
```

Useful grouped targets:

```sh
make for-static-rpm
make for-travis
make for-docker
make clean
make really-clean
make uninstall
make list-built
```

What they do:

- `all`: build the full `deps` list into `$prefix/deps`
- `for-static-rpm`: build the full dependency set with static-library-oriented flags
- `for-travis`: build the full dependency set for CI-style use
- `for-docker`: build the reduced `docker_deps` set
- `clean`: run package clean targets and remove root-level build stamps
- `really-clean`: remove extracted or cloned source trees and source-level build state
- `uninstall`: remove installed files from `$prefix/deps`
- `list-built`: list root-level `*-install-stamp` files

At the repo level, `install` and `check` are intentional no-ops.

## Dependency Bundle Version

The top-level `Makefile` defines a `VERSION` variable for the dependency package set itself. This is the maintained version number for the curated collection of third-party sources, build rules, and compatibility choices in this repository, independent of the individual upstream package versions such as `gdal-3.2.1` or `hdf5-1.14.6`.

That same `VERSION` value is also used by `make dist` when it creates the repository archive:

```text
hyrax-dependencies-$(VERSION).tar
```

In other words, `VERSION` names both the overall dependency build bundle and the tarball produced from that bundle.

## Build Model

Builds follow a staged stamp-file workflow. For each dependency, the `Makefile` typically:

1. extracts or clones sources into [`src`](/Users/jimg/src/opendap/hyrax_git/hyrax-dependencies/src)
2. configures the package
3. compiles it
4. installs it

Root-level `*-configure-stamp`, `*-compile-stamp`, and `*-install-stamp` files are normal build state in this repository. Files under `src/` are also working build state, not curated repository source.

The main full-build order is encoded procedurally in `deps`, and the Docker-oriented build order is encoded in `docker_deps`. Be cautious about reordering either list.

## Dependency Set

The active `Makefile` currently builds these main dependencies:

- `bison`
- `jpeg`
- `openjpeg`
- `gridfields`
- `hdf4`
- `hdfeos`
- `hdf5`
- `netcdf4`
- `proj`
- `gdal`
- `stare`
- `aws_cdk`

Several of these areas are especially compatibility-sensitive:

- `gdal`
- `proj`
- `hdf4`
- `hdfeos`
- the customized `netcdf4` build

One notable install-layout exception is `proj`, which is intentionally installed under:

```text
$prefix/deps/proj
```

This avoids `proj.h` header collisions with HDF-EOS.

## Operator Overrides

The `Makefile` accepts operator-provided build flags, including:

- `CONFIGURE_FLAGS`
- `CMAKE_FLAGS`
- `CPPFLAGS`
- `LDFLAGS`
- `LIBPNG`
- `extra_targets`
- `hdf5_configure_flags`

Examples:

```sh
make CONFIGURE_FLAGS="--disable-shared"
make CMAKE_FLAGS="-DBUILD_SHARED_LIBS:bool=OFF"
```

## Platform Notes

### RHEL 8 and 9

The `rhel` target is checked before normal builds. On RHEL 8 or 9, the build expects `CPPFLAGS` to include `tirpc`. If that check fails, use the local environment setup expected by your build environment before rerunning `make`.

### GDAL and libpng

GDAL is one of the more fragile packages in this workspace. On Apple Silicon and similar environments, GDAL may need explicit help finding `libpng`. The `Makefile` exposes `LIBPNG` for that purpose.

### HDF-EOS and PROJ header collisions

If HDF-EOS fails with errors involving `MAXPROJ` or the wrong `proj.h`, check your shell environment for `CPPFLAGS` or other include-path settings that may be pulling in a system PROJ header ahead of the HDF-EOS `gctp/include` path.

## Validation

There is no meaningful repo-level test suite. Validation is build-oriented.

For targeted validation after a change, prefer:

```sh
make <package>
make list-built
```

For broader validation after changes to shared flags, grouped targets, cleanup behavior, or package ordering, use one or more of:

```sh
make
make for-docker
make for-static-rpm
```

## Repository Layout

- [`Makefile`](/Users/jimg/src/opendap/hyrax_git/hyrax-dependencies/Makefile): canonical build logic
- [`README`](/Users/jimg/src/opendap/hyrax_git/hyrax-dependencies/README): older operator notes retained in the repository
- [`deep-dive.md`](/Users/jimg/src/opendap/hyrax_git/hyrax-dependencies/deep-dive.md): repository architecture and implementation notes
- [`downloads`](/Users/jimg/src/opendap/hyrax_git/hyrax-dependencies/downloads): expected source archives for most packages
- [`extra_downloads`](/Users/jimg/src/opendap/hyrax_git/hyrax-dependencies/extra_downloads): supplemental archives not wired into the main build lists
- [`src`](/Users/jimg/src/opendap/hyrax_git/hyrax-dependencies/src): extracted or cloned working trees plus source-level build state
- [`travis`](/Users/jimg/src/opendap/hyrax_git/hyrax-dependencies/travis): CI helper scripts

## Notes On Network Access

Most packages build from local archives in `downloads/`. The `aws_cdk` target is different: it performs a shallow clone of `https://github.com/aws/aws-sdk-cpp` for tag `1.11.665` unless the source tree is already available in `src/`.
