<!-- SPDX-License-Identifier: MIT -->

# gdt-cpus Test Data

Shared topology fixture corpus for the Zig and Rust gdt-cpus implementations.

The fixtures are recorded host snapshots used to verify CPU topology detection
without needing every machine in CI. They intentionally assert topology,
cache, NUMA, L3-domain, and core-kind facts, not live CPU identity. On x86,
vendor/model/features can still come from the host `cpuid` path while the
filesystem tree is replayed.

## Layout

```text
fixtures/
  sysfs-5950x/           8-core Zen 3, two L3 domains
  sysfs-biglittle-arm/   ARM big.LITTLE, capacity-threshold kinds
  sysfs-cix-p1/          Cix CP8180, three capacity tiers, empty Efficiency tier
  sysfs-hybrid-x86/      Intel hybrid, core_type chain
  sysfs-i7-6700/         4-core Skylake, monolithic L3
  sysfs-i7-6700-lxc/     the same chip under a cpuset-limited LXC: sparse online
                         set, cache lists still naming offline siblings
  sysfs-numa2/           two disjoint NUMA nodes
  sysfs-numa-sparse/     non-contiguous NUMA node ids
  sysfs-pi5/             Raspberry Pi 5, homogeneous, degenerate NUMA
  sysfs-quest3/          Meta Quest 3: clusters published as packages, no cache
                         sizes or line sizes at all, one MIDR across two tiers
  sysfs-wsl2/            WSL2 on a 5950X, virtualized L3
  sysctl-m3-max/         Apple M3 Max, perflevel-derived L2 domains
tools/
  record_fixture.sh
  record_sysctl_fixture.sh
README.md
SCHEMA.md
LICENSE.md
LICENSE.CC0-1.0
LICENSE.MIT
```

Linux fixtures use the `sysfs-*` prefix and contain:

```text
sys/
proc/
expected.txt
```

macOS fixtures use the `sysctl-*` prefix and contain:

```text
sysctl.txt
expected.txt
```

## Running Tests

Consumers locate this corpus through the same environment variable:

```sh
GDT_CPUS_FIXTURES=/path/to/gdt-cpus-testdata/fixtures
```

From the Zig implementation:

```sh
cd libs/cpus
GDT_CPUS_FIXTURES=/path/to/testdata/gdt-cpus/fixtures zig build test
```

From the Rust implementation:

```sh
GDT_CPUS_FIXTURES=/path/to/testdata/gdt-cpus/fixtures cargo test --all-targets
```

If `GDT_CPUS_FIXTURES` is not set, fixture conformance tests are allowed to
skip. Unit tests that do not need this corpus should still run.

## Recording Fixtures

Linux:

```sh
tools/record_fixture.sh fixtures/sysfs-new-machine
```

macOS:

```sh
tools/record_sysctl_fixture.sh fixtures/sysctl-new-machine
```

Android, over adb. Tested only on a Quest 3 (Horizon OS). Two things about that
device make the recipe below work unchanged, and both are its policy rather than
anything guaranteed by Android: its `sh` accepts the script, and the shell user
can write to and read back `/data/local/tmp`. Treat any other device as
unverified, adjust the staging path to whatever its shell can actually use, and
read the pulled tree before trusting it.

```sh
adb push tools/record_fixture.sh /data/local/tmp/
adb shell sh /data/local/tmp/record_fixture.sh /data/local/tmp/newfix
adb pull /data/local/tmp/newfix fixtures/sysfs-new-machine
```

After recording, author `expected.txt` by hand. Keep it focused on stable
topology facts the implementation is meant to preserve. Do not assert values
that are intentionally host-live, such as x86 `cpuid` identity in the Linux
fixture path.

## Privacy

The Linux recorder scrubs Raspberry Pi `Serial` from `/proc/cpuinfo`. It also
copies an allowlist of named files rather than whole directories, so sibling
entries such as `uevent` and `shared_cpu_map` are never picked up. Not every
platform has anything to scrub: Android emits no `Serial`, `Hardware` or `Model`
line at all. If adding new capture sources, scrub unique device identifiers
before committing, and read the recorded tree before trusting that. Fixture
names should describe machine classes or topology shapes, not hostnames,
personal names, asset tags, or other operator-specific labels.

This corpus is intended to contain CPU topology data only. Do not add DMI,
SMBIOS, network interface, disk, account, home-directory, hostname,
machine-id, or full-system inventory captures.

## License

This repository uses split licensing:

- `fixtures/**` is released under CC0 1.0 Universal (`CC0-1.0`).
- `tools/**` is licensed under the MIT License (`MIT`).
- `README.md` and `SCHEMA.md` are licensed under the MIT License (`MIT`).

See `LICENSE.md`, `LICENSE.CC0-1.0`, and `LICENSE.MIT`.

## Schema

See `SCHEMA.md`.
