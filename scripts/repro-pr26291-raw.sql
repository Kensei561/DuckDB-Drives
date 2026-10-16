.bail on

SELECT version() AS duckdb_version;
PRAGMA memory_limit='384MB';
PRAGMA checkpoint_threshold='1MB';   -- so the automatic checkpoint fires at this small write volume

CREATE TABLE t (id BIGINT PRIMARY KEY, payload VARCHAR, del BOOLEAN);
INSERT INTO t SELECT i, repeat('x',384) || (i%997)::VARCHAR, (i%20=0) FROM range(300000) tbl(i);

-- Round 1
INSERT INTO t SELECT i, repeat('x',384) || (i%997)::VARCHAR, (i%20=0) FROM range(0,100000) tbl(i)
  ON CONFLICT (id) DO UPDATE SET payload = excluded.payload, del = excluded.del;
INSERT INTO t SELECT i, repeat('x',384) || (i%997)::VARCHAR, (i%20=0) FROM range(0,100000) tbl(i)
  ON CONFLICT (id) DO UPDATE SET payload = excluded.payload, del = excluded.del;
DELETE FROM t WHERE del;
SELECT
    1 AS round,
    m.allocator_rows,
    m.allocator_bytes,
    (SELECT COUNT(*) FROM t) AS rows
FROM (
    SELECT
        COUNT(*) AS allocator_rows,
        COALESCE(SUM(memory_usage_bytes), 0) AS allocator_bytes
    FROM duckdb_memory()
    WHERE tag = 'ALLOCATOR'
) AS m;

-- Round 2
INSERT INTO t SELECT i, repeat('x',384) || (i%997)::VARCHAR, (i%20=0) FROM range(0,100000) tbl(i)
  ON CONFLICT (id) DO UPDATE SET payload = excluded.payload, del = excluded.del;
INSERT INTO t SELECT i, repeat('x',384) || (i%997)::VARCHAR, (i%20=0) FROM range(0,100000) tbl(i)
  ON CONFLICT (id) DO UPDATE SET payload = excluded.payload, del = excluded.del;
DELETE FROM t WHERE del;
SELECT
    2 AS round,
    m.allocator_rows,
    m.allocator_bytes,
    (SELECT COUNT(*) FROM t) AS rows
FROM (
    SELECT
        COUNT(*) AS allocator_rows,
        COALESCE(SUM(memory_usage_bytes), 0) AS allocator_bytes
    FROM duckdb_memory()
    WHERE tag = 'ALLOCATOR'
) AS m;

-- Round 3
INSERT INTO t SELECT i, repeat('x',384) || (i%997)::VARCHAR, (i%20=0) FROM range(0,100000) tbl(i)
  ON CONFLICT (id) DO UPDATE SET payload = excluded.payload, del = excluded.del;
INSERT INTO t SELECT i, repeat('x',384) || (i%997)::VARCHAR, (i%20=0) FROM range(0,100000) tbl(i)
  ON CONFLICT (id) DO UPDATE SET payload = excluded.payload, del = excluded.del;
DELETE FROM t WHERE del;
SELECT
    3 AS round,
    m.allocator_rows,
    m.allocator_bytes,
    (SELECT COUNT(*) FROM t) AS rows
FROM (
    SELECT
        COUNT(*) AS allocator_rows,
        COALESCE(SUM(memory_usage_bytes), 0) AS allocator_bytes
    FROM duckdb_memory()
    WHERE tag = 'ALLOCATOR'
) AS m;

-- Round 4
INSERT INTO t SELECT i, repeat('x',384) || (i%997)::VARCHAR, (i%20=0) FROM range(0,100000) tbl(i)
  ON CONFLICT (id) DO UPDATE SET payload = excluded.payload, del = excluded.del;
INSERT INTO t SELECT i, repeat('x',384) || (i%997)::VARCHAR, (i%20=0) FROM range(0,100000) tbl(i)
  ON CONFLICT (id) DO UPDATE SET payload = excluded.payload, del = excluded.del;
DELETE FROM t WHERE del;
SELECT
    4 AS round,
    m.allocator_rows,
    m.allocator_bytes,
    (SELECT COUNT(*) FROM t) AS rows
FROM (
    SELECT
        COUNT(*) AS allocator_rows,
        COALESCE(SUM(memory_usage_bytes), 0) AS allocator_bytes
    FROM duckdb_memory()
    WHERE tag = 'ALLOCATOR'
) AS m;

-- Round 5
INSERT INTO t SELECT i, repeat('x',384) || (i%997)::VARCHAR, (i%20=0) FROM range(0,100000) tbl(i)
  ON CONFLICT (id) DO UPDATE SET payload = excluded.payload, del = excluded.del;
INSERT INTO t SELECT i, repeat('x',384) || (i%997)::VARCHAR, (i%20=0) FROM range(0,100000) tbl(i)
  ON CONFLICT (id) DO UPDATE SET payload = excluded.payload, del = excluded.del;
DELETE FROM t WHERE del;
SELECT
    5 AS round,
    m.allocator_rows,
    m.allocator_bytes,
    (SELECT COUNT(*) FROM t) AS rows
FROM (
    SELECT
        COUNT(*) AS allocator_rows,
        COALESCE(SUM(memory_usage_bytes), 0) AS allocator_bytes
    FROM duckdb_memory()
    WHERE tag = 'ALLOCATOR'
) AS m;

-- Round 6
INSERT INTO t SELECT i, repeat('x',384) || (i%997)::VARCHAR, (i%20=0) FROM range(0,100000) tbl(i)
  ON CONFLICT (id) DO UPDATE SET payload = excluded.payload, del = excluded.del;
INSERT INTO t SELECT i, repeat('x',384) || (i%997)::VARCHAR, (i%20=0) FROM range(0,100000) tbl(i)
  ON CONFLICT (id) DO UPDATE SET payload = excluded.payload, del = excluded.del;
DELETE FROM t WHERE del;
SELECT
    6 AS round,
    m.allocator_rows,
    m.allocator_bytes,
    (SELECT COUNT(*) FROM t) AS rows
FROM (
    SELECT
        COUNT(*) AS allocator_rows,
        COALESCE(SUM(memory_usage_bytes), 0) AS allocator_bytes
    FROM duckdb_memory()
    WHERE tag = 'ALLOCATOR'
) AS m;

-- Round 7
INSERT INTO t SELECT i, repeat('x',384) || (i%997)::VARCHAR, (i%20=0) FROM range(0,100000) tbl(i)
  ON CONFLICT (id) DO UPDATE SET payload = excluded.payload, del = excluded.del;
INSERT INTO t SELECT i, repeat('x',384) || (i%997)::VARCHAR, (i%20=0) FROM range(0,100000) tbl(i)
  ON CONFLICT (id) DO UPDATE SET payload = excluded.payload, del = excluded.del;
DELETE FROM t WHERE del;
SELECT
    7 AS round,
    m.allocator_rows,
    m.allocator_bytes,
    (SELECT COUNT(*) FROM t) AS rows
FROM (
    SELECT
        COUNT(*) AS allocator_rows,
        COALESCE(SUM(memory_usage_bytes), 0) AS allocator_bytes
    FROM duckdb_memory()
    WHERE tag = 'ALLOCATOR'
) AS m;

-- Round 8
INSERT INTO t SELECT i, repeat('x',384) || (i%997)::VARCHAR, (i%20=0) FROM range(0,100000) tbl(i)
  ON CONFLICT (id) DO UPDATE SET payload = excluded.payload, del = excluded.del;
INSERT INTO t SELECT i, repeat('x',384) || (i%997)::VARCHAR, (i%20=0) FROM range(0,100000) tbl(i)
  ON CONFLICT (id) DO UPDATE SET payload = excluded.payload, del = excluded.del;
DELETE FROM t WHERE del;
SELECT
    8 AS round,
    m.allocator_rows,
    m.allocator_bytes,
    (SELECT COUNT(*) FROM t) AS rows
FROM (
    SELECT
        COUNT(*) AS allocator_rows,
        COALESCE(SUM(memory_usage_bytes), 0) AS allocator_bytes
    FROM duckdb_memory()
    WHERE tag = 'ALLOCATOR'
) AS m;

-- Round 9
INSERT INTO t SELECT i, repeat('x',384) || (i%997)::VARCHAR, (i%20=0) FROM range(0,100000) tbl(i)
  ON CONFLICT (id) DO UPDATE SET payload = excluded.payload, del = excluded.del;
INSERT INTO t SELECT i, repeat('x',384) || (i%997)::VARCHAR, (i%20=0) FROM range(0,100000) tbl(i)
  ON CONFLICT (id) DO UPDATE SET payload = excluded.payload, del = excluded.del;
DELETE FROM t WHERE del;
SELECT
    9 AS round,
    m.allocator_rows,
    m.allocator_bytes,
    (SELECT COUNT(*) FROM t) AS rows
FROM (
    SELECT
        COUNT(*) AS allocator_rows,
        COALESCE(SUM(memory_usage_bytes), 0) AS allocator_bytes
    FROM duckdb_memory()
    WHERE tag = 'ALLOCATOR'
) AS m;

-- Round 10
INSERT INTO t SELECT i, repeat('x',384) || (i%997)::VARCHAR, (i%20=0) FROM range(0,100000) tbl(i)
  ON CONFLICT (id) DO UPDATE SET payload = excluded.payload, del = excluded.del;
INSERT INTO t SELECT i, repeat('x',384) || (i%997)::VARCHAR, (i%20=0) FROM range(0,100000) tbl(i)
  ON CONFLICT (id) DO UPDATE SET payload = excluded.payload, del = excluded.del;
DELETE FROM t WHERE del;
SELECT
    10 AS round,
    m.allocator_rows,
    m.allocator_bytes,
    (SELECT COUNT(*) FROM t) AS rows
FROM (
    SELECT
        COUNT(*) AS allocator_rows,
        COALESCE(SUM(memory_usage_bytes), 0) AS allocator_bytes
    FROM duckdb_memory()
    WHERE tag = 'ALLOCATOR'
) AS m;

SELECT 'completed all rounds without failing' AS status;
