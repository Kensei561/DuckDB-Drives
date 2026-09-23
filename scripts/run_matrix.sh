#!/usr/bin/env bash

set -o pipefail
set -u

DUCKDB="./build/debug/duckdb"
DATA="output.parquet"

MEMORY_LIMIT="6.4g"
THREAD_COUNTS=(2 4 8 16)
REPEATS=5

LOG_DIR="asan-runs/6.4g"
mkdir -p "$LOG_DIR"

echo "DuckDB: $DUCKDB"
echo "Data:   $DATA"
echo "Memory: $MEMORY_LIMIT"
echo "Threads: ${THREAD_COUNTS[*]}"
echo "Repeats: $REPEATS"
echo

if [ ! -x "$DUCKDB" ]; then
    echo "ERROR: DuckDB binary not found: $DUCKDB"
    exit 1
fi

if [ ! -f "$DATA" ]; then
    echo "ERROR: Input file not found: $DATA"
    exit 1
fi

for threads in "${THREAD_COUNTS[@]}"; do
    for run in $(seq 1 "$REPEATS"); do

        name="threads${threads}_run${run}"
        sql="$LOG_DIR/${name}.sql"
        log="$LOG_DIR/${name}.log"

        echo "=============================================="
        echo "Memory : $MEMORY_LIMIT"
        echo "Threads: $threads"
        echo "Run    : $run"
        echo "=============================================="

        cat > "$sql" <<EOF
SET memory_limit = '$MEMORY_LIMIT';
SET threads = $threads;

FROM '$DATA'
SELECT
    FIRST(columns(*)),
    LIST(value ORDER BY day)
GROUP BY id
ORDER BY id, day;
EOF

        ASAN_OPTIONS='symbolize=1:halt_on_error=1:abort_on_error=1' \
        "$DUCKDB" < "$sql" > /dev/null 2> "$log"

        status=$?

        echo "Exit code: $status"

        # Actual ASan memory-safety failure.
        if grep -qE \
            'ERROR: AddressSanitizer|double-free|heap-use-after-free|invalid-free|attempting free' \
            "$log"; then

            echo
            echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
            echo "ASAN FAILURE FOUND"
            echo "Memory : $MEMORY_LIMIT"
            echo "Threads: $threads"
            echo "Run    : $run"
            echo "Log    : $log"
            echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
            echo

            cat "$log"
            exit 0
        fi

        # Unexpected process failure that is not an ordinary DuckDB OOM.
        if [ "$status" -ne 0 ] && \
           ! grep -q "Out of Memory Error" "$log"; then

            echo
            echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
            echo "UNEXPECTED PROCESS FAILURE"
            echo "Memory : $MEMORY_LIMIT"
            echo "Threads: $threads"
            echo "Run    : $run"
            echo "Log    : $log"
            echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
            echo

            cat "$log"
            exit 1
        fi

        if grep -q "Out of Memory Error" "$log"; then
            echo "Result: normal DuckDB OOM"
        else
            echo "Result: query completed successfully"
        fi

        echo
    done
done

echo "=============================================="
echo "No ASan failure found."
echo "=============================================="