# AGENTS.md

## Scope

These instructions apply to the entire `hyrax-dependencies` repository.

## Project Context

- `hyrax-dependencies` is a dependency assembly workspace for Hyrax/BES, not a conventional source repository for the third-party packages it builds.
- The repository's main product is an installed dependency tree under `$prefix/deps`.
- The handwritten [`Makefile`](/Users/jimg/src/opendap/hyrax_git/hyrax-dependencies/Makefile) is the operational source of truth for package versions, build order, platform workarounds, and install layout.
- Most dependency sources are expected as archives under `downloads/`; one notable exception is `aws_cdk`, which is cloned from GitHub during the build.
- Prioritize reproducibility, compatibility, and small operationally safe diffs over cleanup-oriented refactors.

## Build Model

- Builds follow a staged stamp-file workflow: extract/clone, configure, compile, install.
- Root-level `*-configure-stamp`, `*-compile-stamp`, and `*-install-stamp` files are normal build state in this repo.
- `src/` is a working area containing extracted or cloned upstream source trees plus source-level stamp files; do not treat it as curated repo content.
- Do not replace the stamp-file model with timestamp-driven directory logic unless explicitly requested; the `Makefile` comments explain why that is fragile here.
- Package ordering is procedural through the `deps` and `docker_deps` lists, so be careful when reordering targets or changing grouped build behavior.

## Primary Workflow

Before running any build target that installs dependencies, ensure the environment variable `prefix` is set.

Typical full build:

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

Notes:

- `make` / `make all` builds the full `deps` list and installs into `$prefix/deps`.
- `for-static-rpm` forces static-library-oriented flags via `CONFIGURE_FLAGS` and `CMAKE_FLAGS`.
- `for-docker` builds a reduced dependency set intended to lean on system packages where possible.
- `install` and `check` are intentionally no-ops at the repo level.
- `dist` packages the repository itself after `really-clean`.

## Build Inputs And Overrides

- Prefer changing dependency versions, source archive names, configure flags, and grouped target membership in [`Makefile`](/Users/jimg/src/opendap/hyrax_git/hyrax-dependencies/Makefile); that file is the canonical place for active build policy.
- Supported operator knobs include `CONFIGURE_FLAGS`, `CMAKE_FLAGS`, `CPPFLAGS`, `LDFLAGS`, `LIBPNG`, `extra_targets`, and `hdf5_configure_flags`.
- The [`README`](/Users/jimg/src/opendap/hyrax_git/hyrax-dependencies/README) mentions a local override file named `hyrax-site.mk`, while `Makefile` comments mention `site.mk`. The visible active `Makefile` content does not currently show an include for either one, so verify the actual mechanism before relying on it.

## Platform And Package-Specific Constraints

- RHEL 8/9 builds are guarded by the `rhel` target and expect `CPPFLAGS` to include `tirpc`; if that check fails, follow the local environment setup used by the repo maintainers.
- GDAL, PROJ, HDF4, HDF-EOS, and the customized netCDF build are the highest-risk areas; treat changes there as compatibility-sensitive.
- PROJ intentionally installs under `$prefix/deps/proj` to avoid `proj.h` collisions with HDF-EOS.
- HDF-EOS requires its own `gctp/include` path to win over other `proj.h` headers on the system; be careful with `CPPFLAGS` changes.
- GDAL may need explicit libpng help on Apple Silicon and similar environments; preserve or document any `LIBPNG` handling changes.
- `aws_cdk` is built from a shallow Git clone of `aws-sdk-cpp` and is therefore network-dependent unless already present in `src/`.
- Several install targets force `-j1`; do not parallelize install steps casually.

## Testing And Validation

- There is no meaningful repo-level `make check`; validation is build-oriented.
- For `Makefile` changes, prefer targeted validation first:

```sh
make <package>
make list-built
```

- Run a broader grouped build when the change affects shared flags, package ordering, cleanup behavior, or platform-specific logic:

```sh
make
make for-docker
make for-static-rpm
```

- If a full rebuild is too expensive, say exactly which package targets or grouped targets were exercised and which were not.

## Change Discipline

- Match the existing handwritten `Makefile` style and comment style in touched areas.
- Preserve operational comments unless they are clearly wrong; many comments encode historical compatibility knowledge that is still useful.
- Keep changes tightly scoped. Avoid broad reformatting of `Makefile`, docs, or root-level build state.
- Do not commit or hand-edit generated build artifacts in `src/` unless the task explicitly requires it.
- Do not remove root-level stamp files as part of a documentation or code cleanup change unless the user specifically asks for build-state cleanup.

## Documentation Priorities

- When documentation changes are needed, keep [`README`](/Users/jimg/src/opendap/hyrax_git/hyrax-dependencies/README), [`deep-dive.md`](/Users/jimg/src/opendap/hyrax_git/hyrax-dependencies/deep-dive.md), and [`Makefile`](/Users/jimg/src/opendap/hyrax_git/hyrax-dependencies/Makefile) aligned.
- In particular, keep the purpose of the repo, the role of `prefix`, the main grouped targets, and any platform-specific workarounds consistent across those files.

## Review Priorities

When asked to review:

1. Build/install regressions in grouped targets such as `all`, `for-docker`, `for-static-rpm`, and `for-travis`
2. Breakage caused by changed package ordering or changed install prefixes
3. Platform regressions on RHEL/Rocky and macOS, especially Apple Silicon
4. Header/library collision risks involving PROJ, HDF-EOS, GDAL, and libpng discovery
5. Documentation drift between `README`, `Makefile`, and repository behavior

## Communication

- State which targets you ran, which environment variables or flags you set, and whether network access was needed.
- If you rely on an inference from comments or historical alternatives in `Makefile`, say so explicitly.
- If full validation was not run, say exactly what was validated and what remains unverified.
