#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Records a gdt-cpus Linux detection fixture from the running machine.
# The captured tree is EXACTLY the Linux detector's read set — point the
# test-only detect_at(sysfs_root, procfs_root) seam at it (see
# src/platform/linux/cpu/fixture_tests.rs for the driver and the
# expected.txt key=value assertion format).
# Usage: ./record_fixture.sh <out-dir>     e.g. ./record_fixture.sh sysfs-i7-6700
set -euo pipefail
out="${1:?usage: record_fixture.sh <out-dir>}"
cpu_src=/sys/devices/system/cpu
cpu_dst="$out/sys/devices/system/cpu"
mkdir -p "$cpu_dst"

cp "$cpu_src/online" "$cpu_dst/online"

for cpud in "$cpu_src"/cpu[0-9]*; do
    cpu="$(basename "$cpud")"
    mkdir -p "$cpu_dst/$cpu/topology"
    for f in physical_package_id core_id core_type; do
        [ -r "$cpud/topology/$f" ] && cp "$cpud/topology/$f" "$cpu_dst/$cpu/topology/$f"
    done
    [ -r "$cpud/cpu_capacity" ] && cp "$cpud/cpu_capacity" "$cpu_dst/$cpu/cpu_capacity"
    for idxd in "$cpud"/cache/index[0-9]*; do
        [ -d "$idxd" ] || continue
        idx="$(basename "$idxd")"
        mkdir -p "$cpu_dst/$cpu/cache/$idx"
        for f in level type size coherency_line_size shared_cpu_list; do
            [ -r "$idxd/$f" ] && cp "$idxd/$f" "$cpu_dst/$cpu/cache/$idx/$f"
        done
    done
done

for noded in /sys/devices/system/node/node[0-9]*; do
    [ -d "$noded" ] || continue
    node="$(basename "$noded")"
    mkdir -p "$out/sys/devices/system/node/$node"
    cp "$noded/cpulist" "$out/sys/devices/system/node/$node/cpulist"
done

# Capture the WHOLE /proc/cpuinfo: a faithful snapshot, and it preserves the
# per-core data the first block hides (notably ARM `CPU part`, which differs per
# core -- e.g. A720 0xd81 vs A520 0xd80 -- a latent kind signal). The detector's
# fallback still only reads the first block. SCRUB the board `Serial` though:
# Raspberry Pi exposes a unique per-unit serial we must not commit.
mkdir -p "$out/proc"
sed -E 's/^(Serial[[:space:]]*:[[:space:]]*).*/\10000000000000000/' /proc/cpuinfo > "$out/proc/cpuinfo"

echo "recorded $(find "$out" -type f | wc -l) files into $out"
echo "next: author $out/expected.txt (key=value, see fixture_tests.rs)"
