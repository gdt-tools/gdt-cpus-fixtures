#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Records a gdt-cpus Linux detection fixture from the running machine.
# The captured tree is the sysfs input set for Linux topology, cache, NUMA and
# core-classification detection. Point the test-only
# detect_at(sysfs_root, procfs_root) seam at it (see
# src/platform/linux/cpu/fixture_tests.rs for the driver and the
# expected.txt key=value assertion format).
# Usage: ./record_fixture.sh <out-dir>     e.g. ./record_fixture.sh sysfs-i7-6700
#
# Two rules govern what belongs in the allowlists below. A fixture is a
# permanent record of one machine, so everything captured must be STABLE across
# recaptures: live counters and current-state files are excluded by name, not by
# accident. And a fixture is recorded once, usually from hardware we do not own,
# so the set is the inputs the detection problem has, not the subset that any
# one version of the detector happens to read.
set -euo pipefail
out="${1:?usage: record_fixture.sh <out-dir>}"
cpu_src=/sys/devices/system/cpu
cpu_dst="$out/sys/devices/system/cpu"
mkdir -p "$cpu_dst"

cp "$cpu_src/online" "$cpu_dst/online"

for cpud in "$cpu_src"/cpu[0-9]*; do
    cpu="$(basename "$cpud")"
    mkdir -p "$cpu_dst/$cpu/topology"
    # thread_siblings_list / core_cpus_list are the authoritative SMT grouping.
    # Deriving siblings from (physical_package_id, core_id) instead breaks on
    # any SoC that restarts core_id per cluster inside one package: distinct
    # cores collide on the same key and get labelled as SMT threads.
    for f in physical_package_id core_id core_type thread_siblings_list core_cpus_list; do
        [ -r "$cpud/topology/$f" ] && cp "$cpud/topology/$f" "$cpu_dst/$cpu/topology/$f"
    done
    [ -r "$cpud/cpu_capacity" ] && cp "$cpud/cpu_capacity" "$cpu_dst/$cpu/cpu_capacity"

    # ACPI CPPC performance scale. cpu_capacity is absent or uniform on most
    # x86, so on those machines the CPPC scale is the only per-core tier signal
    # available. The bounds travel with highest_perf because a bare maximum
    # cannot be interpreted without the scale it sits on. Excluded on purpose:
    # feedback_ctrs and wraparound_time, which are live counters.
    if [ -d "$cpud/acpi_cppc" ]; then
        mkdir -p "$cpu_dst/$cpu/acpi_cppc"
        for f in highest_perf nominal_perf lowest_perf lowest_nonlinear_perf \
                 reference_perf guaranteed_perf nominal_freq lowest_freq; do
            [ -r "$cpud/acpi_cppc/$f" ] && cp "$cpud/acpi_cppc/$f" "$cpu_dst/$cpu/acpi_cppc/$f"
        done
    fi

    # cpufreq limits, read through cpuN/cpufreq, which is a symlink into
    # cpufreq/policyM that cp dereferences. Going through the per-cpu symlink
    # keeps the tree per cpu instead of introducing a second policy-shaped
    # hierarchy, and per-cpu is the shape detection consumes. scaling_driver
    # rides along because it says which of these files to trust. Excluded on
    # purpose: governor, scaling_cur_freq, cpuinfo_avg_freq, setspeed and the
    # energy-preference knobs, all of which are live or user-settable state.
    if [ -d "$cpud/cpufreq" ]; then
        mkdir -p "$cpu_dst/$cpu/cpufreq"
        for f in cpuinfo_max_freq cpuinfo_min_freq scaling_driver \
                 amd_pstate_prefcore_ranking amd_pstate_highest_perf amd_pstate_hw_prefcore; do
            [ -r "$cpud/cpufreq/$f" ] && cp "$cpud/cpufreq/$f" "$cpu_dst/$cpu/cpufreq/$f"
        done
    fi
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
