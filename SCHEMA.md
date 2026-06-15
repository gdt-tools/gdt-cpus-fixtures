<!-- SPDX-License-Identifier: MIT -->

# gdt-cpus Fixture Schema

This schema is the cross-language contract consumed by the Zig and Rust
gdt-cpus test suites.

## Fixture Kinds

Linux sysfs fixtures:

```text
fixtures/<name>/
  sys/devices/system/cpu/...
  sys/devices/system/node/...
  proc/cpuinfo
  expected.txt
```

macOS sysctl fixtures:

```text
fixtures/<name>/
  sysctl.txt
  expected.txt
```

Names are descriptive and currently use:

```text
sysfs-*
sysctl-*
```

## Linux Sysfs Capture

The Linux fixture tree is a minimal replay of the detector read set. Required
or optional files are copied only when they exist on the source host.

Top-level CPU online mask:

```text
sys/devices/system/cpu/online
```

Per logical processor:

```text
sys/devices/system/cpu/cpu<N>/topology/physical_package_id
sys/devices/system/cpu/cpu<N>/topology/core_id
sys/devices/system/cpu/cpu<N>/topology/core_type
sys/devices/system/cpu/cpu<N>/cpu_capacity
```

Per cache index:

```text
sys/devices/system/cpu/cpu<N>/cache/index<M>/level
sys/devices/system/cpu/cpu<N>/cache/index<M>/type
sys/devices/system/cpu/cpu<N>/cache/index<M>/size
sys/devices/system/cpu/cpu<N>/cache/index<M>/coherency_line_size
sys/devices/system/cpu/cpu<N>/cache/index<M>/shared_cpu_list
```

NUMA nodes:

```text
sys/devices/system/node/node<N>/cpulist
```

Processor fallback data:

```text
proc/cpuinfo
```

`proc/cpuinfo` is captured whole so per-core fields such as ARM `CPU part`
survive. Unique device identifiers must be scrubbed.

## macOS Sysctl Capture

`sysctl.txt` is line-oriented:

```text
i4 <key> <value>
i8 <key> <value>
s <key> <value...>
```

Tags:

```text
i4  4-byte integer value
i8  8-byte integer value
s   printable string value
```

The integer width is part of the fixture. Darwin reports mixed-width keys, and
assuming one integer width can corrupt cache/topology reads.

## expected.txt

`expected.txt` is line-oriented:

```text
# comments are allowed
key=value
```

Blank lines and lines beginning with `#` are ignored.

### Global Keys

```text
lp_count=<u64>
core_count=<u64>
socket_count=<u64>
numa_node_count=<u64>
l3_domain_count=<u64>
```

### Core Kind Counts

```text
kind.performance=<u64>
kind.efficiency=<u64>
kind.lp_efficiency=<u64>
```

### L3 Domains

```text
l3.<N>.size_bytes=<u64>
l3.<N>.core_count=<u64>
l3.<N>.lps=<range-list>
```

`range-list` uses Linux cpulist syntax:

```text
0
0,2,4
0-7
0-7,16-23
```

### Per-Kind Caches

Supported cache prefixes:

```text
l1d
l1i
l2
```

Supported kind names:

```text
performance
efficiency
lp_efficiency
```

Keys:

```text
<cache>.<kind>.size_bytes=<u64>
<cache>.<kind>.line_bytes=<u64>
<cache>.<kind>.shared_by=<u64>
```

Only assert cache facts that the target backend is expected to report.

### Logical Processor Keys

```text
lp.<OS_ID>.core=<u64>
lp.<OS_ID>.socket=<u64>
lp.<OS_ID>.smt_index=<u64>
lp.<OS_ID>.numa_node=<u64>
lp.<OS_ID>.perf_hint=<u64>
lp.<OS_ID>.cpu_part=<u64>
lp.<OS_ID>.kind=<kind>
lp.<OS_ID>.l3_domain=<u64|none>
```

`kind` is one of:

```text
performance
efficiency
lp_efficiency
unknown
```

`l3_domain=none` means the backend should report no exposed L3 domain for that
logical processor.

## Assertion Scope

Fixtures should assert stable topology behavior, not every observed host
property. Prefer enough keys to catch the intended class of regressions:

- LP/core/socket/NUMA counts
- core-kind classification
- L3-domain partitioning
- representative SMT sibling mappings
- representative per-kind cache sizes
- representative per-LP NUMA/L3/kind/perf-hint facts

Avoid asserting transient or live-host values unless the detector under test is
explicitly meant to replay them from the fixture.
