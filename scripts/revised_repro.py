from pathlib import Path
import re

path = Path("repro-pr26291-raw.sql")
sql = path.read_text()

pattern = re.compile(
    r"SELECT\s+(\d+)\s+AS\s+round\s*,\s*"
    r"\(\s*SELECT\s+sum\(memory_usage_bytes\)\s*/\s*1048576\s+"
    r"FROM\s+duckdb_memory\(\)\s+WHERE\s+tag\s*=\s*'ALLOCATOR'\s*"
    r"\)\s*::\s*BIGINT\s+AS\s+allocator_mib\s*,\s*"
    r"\(\s*SELECT\s+count\(\*\)\s+FROM\s+t\s*\)\s+AS\s+rows\s*;",
    re.IGNORECASE,
)

def replace_measurement(match):
    round_number = match.group(1)
    return f"""SELECT
    {round_number} AS round,
    m.allocator_rows,
    m.allocator_bytes,
    (SELECT COUNT(*) FROM t) AS rows
FROM (
    SELECT
        COUNT(*) AS allocator_rows,
        COALESCE(SUM(memory_usage_bytes), 0) AS allocator_bytes
    FROM duckdb_memory()
    WHERE tag = 'ALLOCATOR'
) AS m;"""

updated, count = pattern.subn(replace_measurement, sql)

if count != 10:
    raise SystemExit(
        f"Expected to replace 10 measurement queries, matched {count}. "
        "No changes were written."
    )

path.write_text(updated)
print(f"Replaced {count} measurement queries.")