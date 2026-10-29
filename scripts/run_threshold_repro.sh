
#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

ROOT="$HOME/duckdb-24848-v1.5.5"
cd "$ROOT"

BIN="$ROOT/build/release/duckdb"
BASE_SQL="$ROOT/bench24848/current_main/default.sql"

if [[ ! -x "$BIN" || ! -f "$BASE_SQL" ]]; then
    echo "ERROR: DuckDB executable or workload is missing."
    exit 1
fi

# Do not benchmark an unreviewed, modified source tree.
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "ERROR: tracked source changes exist."
    echo "Review them and use the intended clean baseline."
    exit 1
fi

# Guard against known diagnostic instrumentation in source.
if rg -n \
  'ART_ALLOCATOR_PERSIST_BEGIN|FIXED_SIZE_ALLOCATOR_PROFILE|FSB_PERSIST_EVENT|FSB_PERSIST_PROFILE|ART_PERSIST_MAP|ART_DIRTY_TRANSITION|ART_FASTPATH' \
  src/execution/index src/include/duckdb/execution/index; then
    echo "ERROR: profiling instrumentation detected in source."
    exit 1
fi

# Rebuild using the clean source.
GEN=native make

OUT="$ROOT/bench24848/current_main/threshold_repro_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUT"

git rev-parse HEAD > "$OUT/commit.txt"
git status --short > "$OUT/git_status.txt"

# Preserve the exact SQL used for the 4 GB configuration.
SQL_4GB="$OUT/default_4gb.sql"
{
    printf "SET checkpoint_threshold = '4GB';\n"
    cat "$BASE_SQL"
} > "$SQL_4GB"

RESULTS="$OUT/results.tsv"
printf 'pair\tconfig\telapsed_sec\tuser_sec\tsys_sec\n' > "$RESULTS"

# Alternate execution order to reduce systematic ordering bias.
# Pair order: default/4GB, 4GB/default, default/4GB,
#             4GB/default, default/4GB.
schedule=(default 4gb 4gb default default 4gb 4gb default default 4gb)

for i in "${!schedule[@]}"; do
    cfg="${schedule[$i]}"
    pair=$(( i / 2 + 1 ))

    LABEL="$(printf 'pair%02d_%s' "$pair" "$cfg")"
    DB="$OUT/$LABEL.db"
    LOG="$OUT/$LABEL.log"
    TIMING="$OUT/$LABEL.time"

    SQL="$BASE_SQL"
    if [[ "$cfg" == "4gb" ]]; then
        SQL="$SQL_4GB"
    fi

    rm -f "$DB" "$DB.wal"

    echo "Running $LABEL..."

    if /usr/bin/time -f '%e %U %S' -o "$TIMING" \
        "$BIN" -bail "$DB" < "$SQL" > "$LOG" 2>&1; then
        :
    else
        status=$?
        echo "FAILED: $LABEL (exit $status)"
        echo "Inspect $LOG"
        exit "$status"
    fi

    # Reject known diagnostic output in benchmark logs.
    if grep -Eq \
      'ART_ALLOCATOR_PERSIST_BEGIN|FIXED_SIZE_ALLOCATOR_PROFILE|FSB_PERSIST_EVENT|FSB_PERSIST_PROFILE|ART_PERSIST_MAP|ART_DIRTY_TRANSITION|ART_FASTPATH|ART_PROFILE' \
      "$LOG"; then
        echo "ERROR: diagnostic output found in $LOG"
        exit 1
    fi

    read -r wall user sys < "$TIMING"
    printf '%s\t%s\t%s\t%s\t%s\n' \
        "$pair" "$cfg" "$wall" "$user" "$sys" >> "$RESULTS"

    printf '%s: wall=%ss user=%ss sys=%ss\n' \
        "$LABEL" "$wall" "$user" "$sys"

    # Preserve logs and timing files, not the large database.
    rm -f "$DB" "$DB.wal"
done

echo
echo "Results: $RESULTS"
echo "Evidence directory: $OUT"
