# hyrax-dependencies Deep Dive

## Scope

This document covers the repository root, the handwritten [`Makefile`](/Users/jimg/src/opendap/hyrax_git/hyrax-dependencies/Makefile), top-level support files, the `downloads` and `extra_downloads` archive inventories, the `travis` automation entry points, and the top-level contents of [`src`](/Users/jimg/src/opendap/hyrax_git/hyrax-dependencies/src).

Per request, this deep dive skips `copy/`, `docker/`, and `retired/`, and it does not descend into child directories under `src/`.

## What This Repository Is

This repository is a build-and-packaging workspace for Hyrax's third-party native dependencies. It is not a conventional source monorepo where each dependency is maintained in-tree. Instead:

- The canonical orchestration logic lives in one handwritten [`Makefile`](/Users/jimg/src/opendap/hyrax_git/hyrax-dependencies/Makefile).
- Most dependency source code is expected as distribution archives under [`downloads`](/Users/jimg/src/opendap/hyrax_git/hyrax-dependencies/downloads).
- Builds unpack or clone into [`src`](/Users/jimg/src/opendap/hyrax_git/hyrax-dependencies/src).
- Successful build phases leave stamp files both in the repo root and in `src/`.
- Installation happens under `$prefix/deps`, where `prefix` is an environment variable set by the operator or CI job.

The repo is therefore best understood as a reproducible dependency assembly system for the BES/Hyrax build, with some CI packaging layered on top.

## Build Model

The `Makefile` uses a repeated three-stage pattern for most packages:

1. Extract or clone sources into `src/`.
2. Configure the package.
3. Compile and install it.

Each stage emits a `*-stamp` file, for example:

- `jpeg-configure-stamp`
- `jpeg-compile-stamp`
- `jpeg-install-stamp`

That pattern gives the build coarse-grained incremental behavior without relying on timestamps inside unpacked source trees. The file comments explicitly call out why stamp files are preferred over using the source directory timestamp directly.

Most packages install into:

- `$prefix/deps`

One notable exception is PROJ, which installs into:

- `$prefix/deps/proj`

That split exists to avoid header-name collisions with HDF-EOS, which also ships a `proj.h`.

The `Makefile` supports both Autotools-style dependencies and CMake-based dependencies:

- Autotools-oriented: `jpeg`, `bison`, `gdal` (current path), `gridfields`, `hdf4`, `hdfeos`, `hdf5`, `netcdf4`
- CMake-oriented: `openjpeg`, `proj`, `stare`, `aws_cdk`

The build is operator-tunable through environment variables and command-line variables, especially:

- `prefix`
- `CONFIGURE_FLAGS`
- `CMAKE_FLAGS`
- `CPPFLAGS`
- `LDFLAGS`
- `LIBPNG`
- `extra_targets`
- `hdf5_configure_flags`

## Top-Level Layout

### Core build inputs and metadata

- [`Makefile`](/Users/jimg/src/opendap/hyrax_git/hyrax-dependencies/Makefile): the primary implementation of the repo.
- [`README`](/Users/jimg/src/opendap/hyrax_git/hyrax-dependencies/README): operator-facing build instructions.
- [`NEWS`](/Users/jimg/src/opendap/hyrax_git/hyrax-dependencies/NEWS): release-oriented summary of changes.
- [`ChangeLog`](/Users/jimg/src/opendap/hyrax_git/hyrax-dependencies/ChangeLog): maintenance history and build-portability notes.
- [`GDAL-notes.txt`](/Users/jimg/src/opendap/hyrax_git/hyrax-dependencies/GDAL-notes.txt): scratch notes from GDAL configuration experiments.
- [`gdal-config.cmake`](/Users/jimg/src/opendap/hyrax_git/hyrax-dependencies/gdal-config.cmake): retained CMake configuration for an alternate GDAL build path that is currently commented out in the `Makefile`.
- [`.travis.yml`](/Users/jimg/src/opendap/hyrax_git/hyrax-dependencies/.travis.yml): CI/build artifact recipe for Ubuntu and Rocky Linux variants.

### Build state directories

- [`downloads`](/Users/jimg/src/opendap/hyrax_git/hyrax-dependencies/downloads): source archives used by the active build rules, plus some older or currently unused archives.
- [`extra_downloads`](/Users/jimg/src/opendap/hyrax_git/hyrax-dependencies/extra_downloads): supplemental archives not wired into the active `deps` list.
- [`src`](/Users/jimg/src/opendap/hyrax_git/hyrax-dependencies/src): extracted or cloned working trees plus source-level stamp files.
- [`travis`](/Users/jimg/src/opendap/hyrax_git/hyrax-dependencies/travis): helper scripts used by CI jobs.

### Build state files in the repository root

The repo root currently contains many `*-configure-stamp`, `*-compile-stamp`, and `*-install-stamp` files. These are not source artifacts; they are the mechanism used by the `Makefile` to record build progress across invocations.

## The Handwritten Makefile

### Central role

The `Makefile` is intentionally the single source of truth. It defines:

- the versions of dependencies to build
- the dependency bundle version identified by `VERSION`
- where archives are expected to exist
- how each dependency is configured
- how grouped builds are assembled for different environments
- how build state is cleaned and packaged

The design is imperative rather than declarative: package ordering for full builds is encoded in shell loops over named lists instead of in a rich web of target prerequisites.

### Repository bundle version

At the top of the file, the `Makefile` defines:

```make
VERSION = 1.64
```

This `VERSION` is not an upstream library version. It is the version number for the curated Hyrax dependency bundle described by this repository: the set of dependency selections, package versions, build flags, ordering, and compatibility workarounds captured in the `Makefile`.

The same value is consumed by the `dist` target when it creates the repository archive:

```text
hyrax-dependencies-$(VERSION).tar
```

So the `VERSION` variable serves two related purposes:

- it labels the overall dependency package set maintained here
- it names the tarball produced by `make dist`

### Version and package selection

The active package/version definitions in the `Makefile` are:

| Logical target | Active version/source identifier | Source acquisition |
| --- | --- | --- |
| `aws_cdk` | `aws_sdk_cpp` tag `1.11.665` | Git clone from GitHub |
| `bison` | `bison-3.3` | `downloads/bison-3.3.tar.xz` |
| `jpeg` | `jpeg-6b` | `downloads/jpegsrc.v6b.tar.gz` |
| `openjpeg` | `openjpeg-2.5.3` | `downloads/openjpeg-2.5.3.tar.gz` |
| `proj` | `proj-9.5.1` | `downloads/proj-9.5.1.tar.gz` |
| `gdal` | `gdal-3.2.1` | `downloads/gdal-3.2.1.tar.gz` |
| `gridfields` | `gridfields-1.0.5` | `downloads/gridfields-1.0.5.tar.gz` |
| `hdf4` | `hdf4-hdf4.3.0.e` | `downloads/hdf4-hdf4.3.0.e.tar.gz` |
| `hdfeos` | `hdfeos` | `downloads/HDF-EOS2.19v1.00.tar.Z` |
| `hdf5` | `hdf5-1.14.6` | `downloads/hdf5-1.14.6.tar.gz` |
| `netcdf4` | `netcdf-493-e` | `downloads/netcdf-493-e.tar.gz` |
| `stare` | `STARE-1.1.0` | `downloads/STARE-1.1.0.tar.bz2` |

There are also commented or unused alternates kept in the file for operator history and rollback context, for example:

- `openjpeg-2.4.0`
- `proj-6.3.2`
- `gdal-3.9.3`
- older `hdf4` archive naming

That pattern suggests the `Makefile` doubles as both active build script and institutional memory of version compatibility decisions.

### Group targets that build sets of dependencies

These grouped targets are the most important entry points in the repository:

| Target | What it builds | Notes |
| --- | --- | --- |
| `all` | everything in `deps` | Default full build path after `prefix-set` validation |
| `for-static-rpm` | everything in `deps` | Forces static-library-oriented flags for RPM-oriented builds |
| `for-travis` | everything in `deps` | CI-oriented full dependency build |
| `for-docker` | everything in `docker_deps` | Reduced dependency set intended for Docker images |
| `clean` | `*-clean` for all `deps` entries | Removes stamp files and runs package cleans where supported |
| `really-clean` | `*-really-clean` for all `deps` entries | Removes build trees and source extractions/clones |
| `uninstall` | installed artifacts under `$prefix/deps` | Deletes the dependency install tree |
| `dist` | repo tarball | Packages the repository itself after `really-clean` |
| `list-built` | no builds; reports installed stamps | Prints `*-install-stamp` files present in the repo root |

The grouped package lists are:

### `deps`

The main `deps` list is:

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
- `$(extra_targets)`
- `list-built`

This is the authoritative full build order for a normal dependency install.

### `docker_deps`

The Docker-specific list is smaller:

- `gridfields`
- `stare`
- `hdf4`
- `hdfeos`
- `netcdf4`
- `aws_cdk`
- `$(extra_targets)`
- `list-built`

Notably absent from `docker_deps` are:

- `bison`
- `jpeg`
- `openjpeg`
- `hdf5`
- `proj`
- `gdal`

The comments explain the rationale at a high level: Docker builds are expected to rely on distribution packages where practical, while still preserving a custom `netcdf4` because Hyrax needs a modified flavor that exposes Direct I/O write functionality.

### Support and validation targets

Several non-package targets matter operationally:

- `prefix-set`: fails early unless the environment variable `prefix` is set.
- `rhel`: enforces extra conditions on RHEL 8/9, including checking that `CPPFLAGS` mentions `tirpc`.
- `install`: intentionally a no-op at the repo level.
- `check`: intentionally a no-op at the repo level.

The `rhel` check is especially important because it means this repo bakes in assumptions about system-level prerequisites instead of trying to provision them itself.

## Dependency Behavior by Package

This section focuses on how each active dependency is treated, not on upstream internals.

### `bison` 3.3

- Built from `downloads/bison-3.3.tar.xz`
- Standard Autotools flow
- Compile step adds `CFLAGS=-Wno-incompatible-function-pointer-types`
- The `Makefile` comment says it is needed by `libdap`

### `jpeg` 6b

- Built from `downloads/jpegsrc.v6b.tar.gz`
- Standard configure/make flow
- Uses explicit install-time directory creation and manual copying of `libjpeg.a` and headers
- Configure flags include `-fPIC` and warning suppression for implicit-int issues on newer Apple toolchains

### `openjpeg` 2.5.3

- Built with CMake in an out-of-tree `build/` directory
- Installed into `$prefix/deps`
- Included primarily to support GDAL's JP2/OpenJPEG capabilities

### `proj` 9.5.1

- Built with CMake
- Installed into `$prefix/deps/proj`, not the main dependency prefix
- The special prefix isolates PROJ headers and libraries from HDF-EOS naming conflicts
- The package comments show active compatibility management around the jump to newer PROJ branches and C++ standard requirements

### `gdal` 3.2.1

- Built from `downloads/gdal-3.2.1.tar.gz`
- Current active path uses Autotools `./configure`, not the alternate CMake recipe
- The configure logic is the most elaborate in the file
- It customizes `CPPFLAGS`, `LDFLAGS`, and `PKG_CONFIG_PATH`
- It contains OS-specific branching for Darwin vs non-Darwin
- It prints extensive diagnostic state before running configure
- It aggressively disables optional features and enables only selected drivers, especially GRIB
- It is explicitly wired to use the separately installed PROJ tree

This target is clearly one of the highest-maintenance parts of the repository. The preserved alternate CMake implementation and extra notes in `GDAL-notes.txt` reinforce that GDAL compatibility has required repeated experimentation.

### `gridfields` 1.0.5

- Built from `downloads/gridfields-1.0.5.tar.gz`
- Standard configure/make flow
- Configured with `--disable-netcdf`

### `hdf4` 4.3.0.e

- Built from `downloads/hdf4-hdf4.3.0.e.tar.gz`
- Configured against the locally built JPEG dependency
- Disables Fortran and netCDF support
- Enables XDR support
- After install, it explicitly removes `ncdump` and `ncgen` from the install tree to avoid shadowing the versions expected from the netCDF build

That post-install cleanup is a good example of this repository managing not just builds, but downstream tool collisions.

### `hdfeos` 2.19v1.00

- Built from `downloads/HDF-EOS2.19v1.00.tar.Z`
- Uses a fragile, custom configure environment
- Prepends the HDF-EOS `gctp/include` path to `CPPFLAGS` so its own `proj.h` wins over unrelated installed PROJ headers
- Adds warning suppressions during compile for older C code on modern compilers

The comments around this target are unusually detailed and defensive, which is a strong signal that HDF-EOS portability is a recurring source of breakage.

### `hdf5` 1.14.6

- Built from `downloads/hdf5-1.14.6.tar.gz`
- Standard configure/make/install flow
- Accepts extra tuning via `$(hdf5_configure_flags)`

### `netcdf4` 4.9.3-e

- Built from `downloads/netcdf-493-e.tar.gz`
- Configured against the locally built HDF5 include and library directories
- Present comments in the `Makefile` and `NEWS` indicate this is a customized netCDF4 variant used because Hyrax needs public support for Direct I/O write operations

This is not just a versioned dependency pin; it is a policy choice to build and carry a special netCDF flavor.

### `stare` 1.1.0

- Built from `downloads/STARE-1.1.0.tar.bz2`
- Uses an out-of-tree CMake build directory
- Included in `deps`, `docker_deps`, and CI builds
- The historical comments in CI config describe STARE as research-related and selectively included depending on platform capability

### `aws_cdk` / AWS SDK for C++

- Source tree name: `aws_sdk_cpp-1.11.665`
- Acquired by shallow Git clone from GitHub rather than from `downloads/`
- Built with CMake
- Restricted to `BUILD_ONLY="s3"`

Per request, the main point to retain is the active version/tag: `1.11.665`.

## Active and Inactive Archive Inventory

The `downloads/` directory contains both archives used by the active `Makefile` and older or currently unused ones.

### Actively referenced by the current `Makefile`

- `HDF-EOS2.19v1.00.tar.Z`
- `STARE-1.1.0.tar.bz2`
- `bison-3.3.tar.xz`
- `gdal-3.2.1.tar.gz`
- `gridfields-1.0.5.tar.gz`
- `hdf4-hdf4.3.0.e.tar.gz`
- `hdf5-1.14.6.tar.gz`
- `jpegsrc.v6b.tar.gz`
- `netcdf-493-e.tar.gz`
- `openjpeg-2.5.3.tar.gz`
- `proj-9.5.1.tar.gz`

### Present but not selected by the current active rules

- `cfitsio-3.49.tar.gz`
- `cmake-3.11.3.tar.gz`
- `gdal-3.9.3.tar.gz`
- `hdf-4.2.16.tar.gz`
- `icu4c-3_6-src.tgz`
- `openjpeg-2.4.0.tar.gz`
- `proj-6.3.2.tar.gz`

These unused archives are still meaningful. They document prior experiments, fallback versions, and older platform accommodations.

### `extra_downloads/`

- `cdf34_1-dist-cdf.tar.gz`

This directory exists, but its contents are not part of the active `deps` pipeline.

## `src/` Top-Level Inventory

Without descending into child directories, `src/` currently contains:

- `.gitignore`
- `STARE-1.1.0`
- `STARE-1.1.0-stamp`
- `aws_sdk_cpp-1.11.665`
- `aws_sdk_cpp-1.11.665-stamp`
- `bison-3.3`
- `bison-3.3-stamp`
- `gdal-3.2.1`
- `gdal-3.2.1-stamp`
- `gridfields-1.0.5`
- `gridfields-1.0.5-stamp`
- `hdf4-hdf4.3.0.e`
- `hdf4-hdf4.3.0.e-stamp`
- `hdf5-1.14.6`
- `hdf5-1.14.6-stamp`
- `hdfeos`
- `hdfeos-stamp`
- `jpeg-6b`
- `jpeg-6b-stamp`
- `netcdf-493-e`
- `netcdf-493-e-stamp`
- `openjpeg-2.5.3`
- `openjpeg-2.5.3-stamp`
- `proj-9.5.1`
- `proj-9.5.1-stamp`

The pattern is straightforward:

- a source tree or clone for each active dependency
- a matching stamp file showing the extraction/clone phase completed

`src/` is therefore a working area, not curated source content.

## CI and Packaging

The CI story is centered on [`.travis.yml`](/Users/jimg/src/opendap/hyrax_git/hyrax-dependencies/.travis.yml), which still captures the intended packaging matrix even if Travis is no longer the only execution environment.

It defines build jobs for:

- Ubuntu Focal
- Rocky 8 static
- Rocky 9 static
- Rocky 8 dynamic
- Rocky 9 dynamic

Important characteristics:

- CI uses `make for-travis` for the Ubuntu path.
- Rocky jobs delegate into containerized helper scripts under `travis/`.
- Artifact packaging produces tarballs of the installed dependency tree.
- Expected dependency counts differ between full/static and Docker-like/dynamic cases.
- Deployment publishes build artifacts to S3.

The scripts in [`travis`](/Users/jimg/src/opendap/hyrax_git/hyrax-dependencies/travis) are therefore part of the repo's operational surface even though the main build logic remains centralized in `Makefile`.

## Release and Maintenance Signals

The combination of `NEWS`, `ChangeLog`, inline `Makefile` comments, and retained commented-out build alternatives tells a coherent story:

- This repo evolves primarily in response to toolchain drift, OS upgrades, and dependency compatibility problems.
- Apple Silicon / modern macOS support has required repeated targeted fixes.
- RHEL/Rocky support is explicit and guarded.
- GDAL, PROJ, HDF4, HDF-EOS, and netCDF are the most sensitive parts of the dependency set.
- The repository intentionally preserves old build knowledge in comments instead of deleting it.

That makes the file set somewhat noisier, but it also preserves critical operational memory that would be easy to lose in a cleaner but less annotated build script.

## Notable Design Choices and Risks

### 1. Ordering is encoded procedurally

The full dependency build order is imposed by shell loops over `deps` and `docker_deps`, not by explicit Make prerequisite chains between packages. That keeps the file simpler, but it means:

- package interdependencies are implicit
- targeted rebuilds require operator knowledge
- reordering the package lists can silently break configure steps

### 2. This is not a purely offline build

Most dependencies come from local archives, but `aws_cdk` is cloned from GitHub at build time. That makes the build partially network-dependent unless the source tree is already present.

### 3. The repo mixes active logic with historical commentary

This is helpful for maintainers, but it also increases the chance of documentation drift. One concrete example:

- the `README` refers to `hyrax-site.mk`
- the top of the `Makefile` comments mention `site.mk`
- the visible active `Makefile` content does not currently include either file

That suggests either a missing include, a stale comment, or stale README guidance.

### 4. Platform-specific fragility is concentrated in a few targets

The most elaborate handling is around:

- GDAL
- HDF-EOS
- PROJ
- macOS/Apple Silicon
- RHEL 8/9 system header/library expectations

Anyone changing those areas should expect regression risk.

### 5. Root-level build artifacts are normal here

The many stamp files in the repository root can look like clutter, but they are part of the build model. Any future cleanup or repo hygiene effort needs to account for that and avoid breaking incremental builds.

## Bottom Line

`hyrax-dependencies` is a dependency assembly repo whose main product is a reliable `$prefix/deps` tree for Hyrax/BES builds. Its engineering center of gravity is the handwritten `Makefile`, which captures package versions, platform workarounds, grouped build modes, and years of compatibility knowledge.

The most important things to understand when maintaining it are:

- the grouped targets `all`, `for-static-rpm`, `for-travis`, and `for-docker`
- the active dependency/version set they expand into
- the use of local source archives under `downloads/`
- the stamp-file-driven build flow
- the fragile integration points around GDAL, PROJ, HDF4, HDF-EOS, and the custom netCDF build
