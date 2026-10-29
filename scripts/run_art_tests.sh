#!/usr/bin/env bash
set -uo pipefail

mapfile -d '' tests < <(
    find test/sql/index/art -type f \
        \( -name '*.test' -o -name '*.test_slow' \) \
        -print0 | sort -z
)

total=${#tests[@]}
passed=0

for test in "${tests[@]}"; do
    echo
    echo "===== [$((passed + 1))/$total] $test ====="

    if build/release/test/unittest "$test"; then
        ((passed += 1))
    else
        status=$?
        echo "FAILED or INTERRUPTED: $test"
        echo "Passed: $passed/$total"
        exit "$status"
    fi
done

echo
echo "ALL ART TESTS PASSED: $passed/$total"
