# hyrax-dependencies

`hyrax-dependencies` is the dependency build workspace for Hyrax/BES. It is not a monorepo for the third-party packages it builds. The repository's main job is to assemble, build, and install the native dependency stack used by Hyrax into `$prefix/deps`.

The handwritten [`Makefile`](Makefile) is the operational source of truth for:

- dependency versions
- build order
- the dependency bundle version identified by `VERSION`
- package-specific configure and CMake flags
- platform workarounds
- install layout

Most dependency sources are expected as archives under [`downloads`](downloads). One important exception is `aws_cdk`, which is cloned from GitHub during the build unless it is already present under [`src`](src).

## Updating the dependencies and making a release

When you change dependency versions, package membership, or build behavior, review the top-level `VERSION` in the [`Makefile`](Makefile) and increment it using the guidance documented there:

- increment `Major` for large architectural shifts in how dependencies are sourced or assembled
- increment `Minor` when upstream package versions change, or when a package is added or removed
- increment `Patch` when package versions stay the same but the build rules or compatibility logic change

For formal BES releases, use `make dist` to create a release tarball of this repository after `really-clean` runs. That archive includes the build metadata, the `downloads/` contents tracked in the workspace, and the files needed to rebuild the dependency bundle.

The resulting archive is named from the dependency bundle version:

```text
hyrax-dependencies-$(VERSION).tar
```

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
make for-travis
make for-docker
make clean
make really-clean
make uninstall
make list-built
make list-not-built
```

What they do:

- `all`: build the full `deps` list into `$prefix/deps`
- `for-travis`: build the full dependency set for CI-style use
- `for-docker`: build the reduced `docker_deps` set
- `clean`: run package clean targets and remove root-level build stamps
- `really-clean`: remove extracted or cloned source trees and source-level build state; for CMake builds, only the build directories are removed
- `uninstall`: remove installed files from `$prefix/deps`
- `list-built`: list root-level `*-install-stamp` files
- `list-not-built`: compare installed stamp files with `all-dependencies.txt` and list missing dependencies

The default `make` target is `all`, and `all` delegates to `for-travis`. Both `deps` and `docker_deps` include `list-built` and `list-not-built` at the end so grouped builds finish by showing what was installed and what is still missing.

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

1. extracts or clones sources into [`src`](src)
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
- the customized `hdf4` build
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
- `MACOSX_DEPLOYMENT_TARGET`
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

On Darwin, when `MACOSX_DEPLOYMENT_TARGET` is set, the `Makefile` converts it to `-DCMAKE_OSX_DEPLOYMENT_TARGET=...` for CMake-based dependencies that use the shared `CMAKE_OSX_FLAGS` setting. This lets those dependency builds match the deployment target used by BES/libdap while leaving Linux and unset macOS builds unchanged.

```sh
export MACOSX_DEPLOYMENT_TARGET=13.0
make
```

## Platform Notes

### macOS deployment target

Newer Xcode toolchains may default CMake projects to the host macOS point release. If you need dependency binaries that are compatible with an older macOS target, set `MACOSX_DEPLOYMENT_TARGET` before building. The `Makefile` currently passes that value through to the CMake configure steps that opt into `CMAKE_OSX_FLAGS`.

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
```

## Repository Layout

- [`Makefile`](Makefile): canonical build logic
- [`README`](README): older operator notes retained in the repository
- [`deep-dive.md`](deep-dive.md): repository architecture and implementation notes
- [`downloads`](downloads): expected source archives for most packages
- [`extra_downloads`](extra_downloads): supplemental archives not wired into the main build lists
- [`src`](src): extracted or cloned working trees plus source-level build state
- [`travis`](travis): CI helper scripts

## Notes On Network Access

Most packages build from local archives in `downloads/`. The `aws_cdk` target is different: it performs a shallow clone of `https://github.com/aws/aws-sdk-cpp` for tag `1.11.665` unless the source tree is already available in `src/`.
