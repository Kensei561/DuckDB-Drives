.bail on

SELECT version() AS duckdb_version;

PRAGMA memory_limit='384MB';
PRAGMA checkpoint_threshold='10GB';

CREATE TABLE t (
    id BIGINT PRIMARY KEY,
    payload VARCHAR,
    del BOOLEAN
);

INSERT INTO t
SELECT
    i,
    repeat('x',384) || (i%997)::VARCHAR,
    (i%20=0)
FROM range(300000) tbl(i);

CHECKPOINT;

SELECT
    'after_initial_checkpoint' AS point,
    (SELECT sum(memory_usage_bytes)/1048576
     FROM duckdb_memory() WHERE tag='ALLOCATOR')::BIGINT AS allocator_mib;

-- ROUND 1
INSERT INTO t
SELECT i, repeat('x',384) || (i%997)::VARCHAR, (i%20=0)
FROM range(0,100000) tbl(i)
ON CONFLICT (id) DO UPDATE
SET payload = excluded.payload, del = excluded.del;

INSERT INTO t
SELECT i, repeat('x',384) || (i%997)::VARCHAR, (i%20=0)
FROM range(0,100000) tbl(i)
ON CONFLICT (id) DO UPDATE
SET payload = excluded.payload, del = excluded.del;

DELETE FROM t WHERE del;

SELECT 'round_1_before_checkpoint' AS point,
       (SELECT sum(memory_usage_bytes)/1048576
        FROM duckdb_memory() WHERE tag='ALLOCATOR')::BIGINT AS allocator_mib;

CHECKPOINT;

SELECT 'round_1_after_checkpoint' AS point,
       (SELECT sum(memory_usage_bytes)/1048576
        FROM duckdb_memory() WHERE tag='ALLOCATOR')::BIGINT AS allocator_mib;

-- ROUND 2
INSERT INTO t
SELECT i, repeat('x',384) || (i%997)::VARCHAR, (i%20=0)
FROM range(0,100000) tbl(i)
ON CONFLICT (id) DO UPDATE
SET payload = excluded.payload, del = excluded.del;

INSERT INTO t
SELECT i, repeat('x',384) || (i%997)::VARCHAR, (i%20=0)
FROM range(0,100000) tbl(i)
ON CONFLICT (id) DO UPDATE
SET payload = excluded.payload, del = excluded.del;

DELETE FROM t WHERE del;

SELECT 'round_2_before_checkpoint' AS point,
       (SELECT sum(memory_usage_bytes)/1048576
        FROM duckdb_memory() WHERE tag='ALLOCATOR')::BIGINT AS allocator_mib;

CHECKPOINT;

SELECT 'round_2_after_checkpoint' AS point,
       (SELECT sum(memory_usage_bytes)/1048576
        FROM duckdb_memory() WHERE tag='ALLOCATOR')::BIGINT AS allocator_mib;

-- ROUND 3
INSERT INTO t
SELECT i, repeat('x',384) || (i%997)::VARCHAR, (i%20=0)
FROM range(0,100000) tbl(i)
ON CONFLICT (id) DO UPDATE
SET payload = excluded.payload, del = excluded.del;

INSERT INTO t
SELECT i, repeat('x',384) || (i%997)::VARCHAR, (i%20=0)
FROM range(0,100000) tbl(i)
ON CONFLICT (id) DO UPDATE
SET payload = excluded.payload, del = excluded.del;

DELETE FROM t WHERE del;

SELECT 'round_3_before_checkpoint' AS point,
       (SELECT sum(memory_usage_bytes)/1048576
        FROM duckdb_memory() WHERE tag='ALLOCATOR')::BIGINT AS allocator_mib;

CHECKPOINT;

SELECT 'round_3_after_checkpoint' AS point,
       (SELECT sum(memory_usage_bytes)/1048576
        FROM duckdb_memory() WHERE tag='ALLOCATOR')::BIGINT AS allocator_mib;

-- ROUND 4
INSERT INTO t
SELECT i, repeat('x',384) || (i%997)::VARCHAR, (i%20=0)
FROM range(0,100000) tbl(i)
ON CONFLICT (id) DO UPDATE
SET payload = excluded.payload, del = excluded.del;

INSERT INTO t
SELECT i, repeat('x',384) || (i%997)::VARCHAR, (i%20=0)
FROM range(0,100000) tbl(i)
ON CONFLICT (id) DO UPDATE
SET payload = excluded.payload, del = excluded.del;

DELETE FROM t WHERE del;

SELECT 'round_4_before_checkpoint' AS point,
       (SELECT sum(memory_usage_bytes)/1048576
        FROM duckdb_memory() WHERE tag='ALLOCATOR')::BIGINT AS allocator_mib;

CHECKPOINT;

SELECT 'round_4_after_checkpoint' AS point,
       (SELECT sum(memory_usage_bytes)/1048576
        FROM duckdb_memory() WHERE tag='ALLOCATOR')::BIGINT AS allocator_mib;