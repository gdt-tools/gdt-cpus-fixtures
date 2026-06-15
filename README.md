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
  sysfs-5950x/
  sysfs-i7-6700/
  sysfs-pi5/
  sysfs-cix-p1/
  sysfs-biglittle-arm/
  sysfs-hybrid-x86/
  sysfs-numa2/
  sysctl-m3-max/
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

After recording, author `expected.txt` by hand. Keep it focused on stable
topology facts the implementation is meant to preserve. Do not assert values
that are intentionally host-live, such as x86 `cpuid` identity in the Linux
fixture path.

## Privacy

The Linux recorder scrubs Raspberry Pi `Serial` from `/proc/cpuinfo`. If adding
new capture sources, scrub unique device identifiers before committing. Fixture
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
