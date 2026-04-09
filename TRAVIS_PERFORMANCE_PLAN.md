# Travis Performance Plan

## Goals

Improve the performance of [`.travis.yml`](/Users/jimg/src/opendap/hyrax/hyrax-dependencies/.travis.yml) and identify ways to simplify it without changing the end result.

## Plan

1. Establish a baseline and confirm where time is going.

   Measure one or two recent runs by job type and break the runtime into `apt`, Docker startup, `dnf update`, dependency build, packaging, and deploy. This matters because the biggest likely cost in the current setup is not Travis YAML parsing, but repeated dependency rebuilds and the `dnf -y update` inside [travis/build-for-rocky8.sh](/Users/jimg/src/opendap/hyrax/hyrax-dependencies/travis/build-for-rocky8.sh#L57) and [travis/build-for-rocky9.sh](/Users/jimg/src/opendap/hyrax/hyrax-dependencies/travis/build-for-rocky9.sh#L58).

2. Add Travis cache for downloaded sources and build state.

   The Makefile is already stamp-driven, which is a good fit for caching. The first cache pass should preserve:

   - `downloads/`
   - `src/`
   - repo-root `*-stamp` files
   - job-specific install trees such as `$HOME/install`, `$HOME/rocky8/install`, and `$HOME/rocky9/install`

   That gives Travis a chance to skip re-downloading, re-unpacking, re-configuring, and re-installing unchanged dependencies on later runs.

3. Split caches by platform and add explicit cache-bust controls.

   Do not share one cache across Ubuntu, Rocky 8, and Rocky 9. Their binaries and toolchains are different. Use separate cache namespaces per job, and add a simple manual cache version variable so the cache can be invalidated cleanly when [Makefile](/Users/jimg/src/opendap/hyrax/hyrax-dependencies/Makefile), dependency versions, or the Rocky build scripts change.

4. Start with safe caching, then optionally expand to installed artifacts.

   Phase 1 should cache only source downloads, extracted source trees, and stamp files. That is low-risk and should already remove a lot of rebuild work.

   Phase 2 can cache the installed prefixes too, but only after validating that reused installs remain correct when compiler flags or dependency versions change. This is where a cache version key becomes important.

5. Remove or reduce the unconditional `dnf update` in the Rocky jobs.

   Both Rocky scripts do a full `dnf -y update` on every run. That is usually expensive and tends to defeat repeatability as well as caching. The better plan is:

   - build or refresh the Docker images ahead of time with the needed packages baked in, then stop doing the full update in Travis
   - or make the update conditional so it only runs when intentionally refreshing the builder image

   This is likely one of the highest-impact improvements.

6. Decide whether Docker image pull and update behavior should be stabilized.

   If the Travis host is always pulling a moving `:latest` image, builds can slow down and become less reproducible. Pinning [`.travis.yml`](/Users/jimg/src/opendap/hyrax/hyrax-dependencies/.travis.yml#L82) and [`.travis.yml`](/Users/jimg/src/opendap/hyrax/hyrax-dependencies/.travis.yml#L109) to versioned builder tags would help both performance predictability and cache usefulness.

7. Make packaging and deploy work happen only after a successful cache-aware build check.

   Each job currently creates tarballs after `make`. Once caching is in place, keep the packaging step but make sure the build verification still proves the cache was valid, for example with `make list-built` and [travis/check-installed](/Users/jimg/src/opendap/hyrax/hyrax-dependencies/travis/check-installed#L1). This preserves the end result while reducing unnecessary compilation.

8. Add a short validation phase for cache correctness.

   Run the jobs twice in a row on the same branch and compare logs. The second run should show most dependency targets being skipped because the stamp files and install trees are already present. Then test one intentional dependency version change to confirm the cache-bust process works.

## Separate Simplification Step

9. Simplify `.travis.yml` without changing outputs.

   The three jobs in [`.travis.yml`](/Users/jimg/src/opendap/hyrax/hyrax-dependencies/.travis.yml#L53) repeat a lot of setup, packaging, and logging. A clean simplification pass would:

   - use shared YAML anchors or a small wrapper script for the repeated tarball and packaging logic
   - parameterize the Rocky jobs by image name, artifact name, and helper script instead of duplicating nearly identical blocks
   - remove dead or unused structure such as the `never` stage if it is no longer serving a purpose
   - fix minor cleanup issues such as the likely typo `mkdir -vp $"install_dir"` in [`.travis.yml`](/Users/jimg/src/opendap/hyrax/hyrax-dependencies/.travis.yml#L107), which should be `"$install_dir"`

## Recommended Order

1. Cache `downloads/`, `src/`, and stamp files.
2. Remove `dnf -y update` from per-build execution by baking it into the Rocky images.
3. Add optional caching for installed prefixes.
4. Simplify `.travis.yml` by deduplicating job logic.
