#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Records a gdt-cpus macOS detection fixture (sysctl dump) from the running Mac.
# Integer keys are captured WITH their kernel width — Darwin sysctl is
# mixed-width (hw.perflevelN.* are 4-byte CTLTYPE_INT, legacy hw.* keys are
# often 8-byte QUADs) and a width assumption once silently zeroed every cache
# read, so the dump preserves what the kernel actually reports.
#
# Line format (language-neutral; the Zig test suite parses the same dumps):
#   i4 <key> <value>     4-byte integer
#   i8 <key> <value>     8-byte integer
#   s  <key> <value...>  string
#
# The fixture drives detect_at(&FixtureSysctl) — see
# src/platform/macos/cpu.rs fixture_tests, which run on EVERY platform.
# Usage: ./record_sysctl_fixture.sh <out-dir>   e.g. ./record_sysctl_fixture.sh sysctl-m3-max
set -euo pipefail
out="${1:?usage: record_sysctl_fixture.sh <out-dir>}"
mkdir -p "$out"
dump="$out/sysctl.txt"
: > "$dump"

for key in $(sysctl -aN 2>/dev/null | grep -E '^(hw|machdep\.cpu)'); do
    width=$(sysctl -b "$key" 2>/dev/null | wc -c | tr -d ' ') || continue
    value=$(sysctl -n "$key" 2>/dev/null | head -1) || continue
    case "$width" in
        4 | 8)
            if [[ "$value" =~ ^-?[0-9]+$ ]]; then
                echo "i$width $key $value" >>"$dump"
                continue
            fi
            ;;
    esac
    # Strings (and harmless printable leftovers like array keys the detector
    # never reads); binary/struct values are skipped.
    if [[ -n "$value" && "$width" -gt 0 ]]; then
        case "$value" in
        *[![:print:]]*) ;;
        *) echo "s $key $value" >>"$dump" ;;
        esac
    fi
done

echo "recorded $(wc -l <"$dump" | tr -d ' ') keys into $dump"
echo "next: author $out/expected.txt (key=value, format: src/platform/fixture_expected.rs)"
