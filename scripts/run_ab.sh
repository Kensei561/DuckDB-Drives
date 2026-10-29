
#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

cd "$HOME/duckdb-24848-v1.5.5"

B_FILE="src/execution/index/art/prefix_handle.cpp"
ART_FILE="src/execution/index/art/art.cpp"
NODE_FILE="src/execution/index/art/node.cpp"
SQL="bench24848/default.sql"
RESULTS="bench24848/ab_results.tsv"
PATCH="$(mktemp /tmp/duckdb24848-prefixB.XXXXXX)"

B_APPLIED=1

cleanup() {
    # If interrupted while building A, restore Variant B in the source.
    if [[ "$B_APPLIED" -eq 0 ]]; then
        git apply "$PATCH" || true
    fi
    rm -f "$PATCH"
}
trap cleanup EXIT

# Require Variant B to be the only modified tracked source file.
if ! git diff --cached --quiet; then
    echo "ERROR: staged changes exist. Resolve them before running."
    exit 1
fi

mapfile -t changed_files < <(git diff --name-only)

if [[ "${#changed_files[@]}" -ne 1 ||
      "${changed_files[0]}" != "$B_FILE" ]]; then
    echo "ERROR: expected only Variant B's change in $B_FILE."
    git status --short
    exit 1
fi

if ! git diff --check; then
    echo "ERROR: git diff --check failed."
    exit 1
fi

if ! git diff -- "$B_FILE" |
     grep -Eq '^\+.*Prefix prefix\(art, ref\);'; then
    echo "ERROR: Variant B read-only prefix change was not found."
    exit 1
fi

if rg -n "ART_PROFILE" "$ART_FILE" "$NODE_FILE"; then
    echo "ERROR: profiling instrumentation remains in source."
    exit 1
fi

if [[ ! -f "$SQL" ]]; then
    echo "ERROR: workload not found: $SQL"
    exit 1
fi

# Save Variant B's source patch.
git diff -- "$B_FILE" > "$PATCH"

# Build Variant A: original mutable PrefixHandle access.
echo "Building Variant A..."
git restore --source=HEAD --worktree -- "$B_FILE"
B_APPLIED=0

GEN=native make

cp build/release/duckdb /tmp/duckdb24848_A

# Build Variant B: read-only Prefix access.
echo "Building Variant B..."
git apply "$PATCH"
B_APPLIED=1

GEN=native make

cp build/release/duckdb /tmp/duckdb24848_B

# Results header.
printf 'run\tvariant\telapsed_sec\tuser_sec\tsys_sec\n' > "$RESULTS"

run_one() {
    local variant="$1"
    local label="$2"
    local binary="/tmp/duckdb24848_${variant}"
    local db="bench24848/${label}.db"
    local log="bench24848/${label}.log"
    local timing="bench24848/${label}.time"
    local elapsed user sys status

    # Every run starts with a new database.
    rm -f "$db" "$db.wal"

    echo "Running $label..."

    if /usr/bin/time -f '%e,%U,%S' -o "$timing" \
        "$binary" "$db" \
        < "$SQL" > "$log" 2>&1; then
        :
    else
        status=$?
        echo "ERROR: $label failed (exit $status). See $log"
        return "$status"
    fi

    # Refuse to treat an instrumented run as a clean benchmark.
    if grep -q "ART_PROFILE" "$log"; then
        echo "ERROR: profiling output found in $log"
        return 1
    fi

    IFS=',' read -r elapsed user sys < "$timing"

    printf '%s\t%s\t%s\t%s\t%s\n' \
        "$label" "$variant" "$elapsed" "$user" "$sys" \
        >> "$RESULTS"

    printf '%s: elapsed=%ss user=%ss sys=%ss\n' \
        "$label" "$elapsed" "$user" "$sys"

    # Keep logs and timings, not the large benchmark database.
    rm -f "$db" "$db.wal"
}

# Five paired comparisons, alternating AB and BA order:
# Pair 1: AB; Pair 2: BA; Pair 3: AB; Pair 4: BA; Pair 5: AB.
order=(A B B A A B B A A B)

for i in "${!order[@]}"; do
    variant="${order[$i]}"
    label="$(printf 'ab%02d_%s' "$((i + 1))" "$variant")"

    run_one "$variant" "$label" || exit 1
