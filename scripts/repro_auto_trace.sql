.bail on

SELECT version() AS duckdb_version;

PRAGMA memory_limit='384MB';
PRAGMA checkpoint_threshold='1MB';

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

SELECT
    'after_initial_insert' AS point,
    (SELECT sum(memory_usage_bytes)/1048576
     FROM duckdb_memory() WHERE tag='ALLOCATOR')::BIGINT AS allocator_mib;

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

SELECT
    'round_1_after_insert_1' AS point,
    (SELECT sum(memory_usage_bytes)/1048576
     FROM duckdb_memory() WHERE tag='ALLOCATOR')::BIGINT AS allocator_mib;

INSERT INTO t
SELECT i, repeat('x',384) || (i%997)::VARCHAR, (i%20=0)
FROM range(0,100000) tbl(i)
ON CONFLICT (id) DO UPDATE
SET payload = excluded.payload, del = excluded.del;

SELECT
    'round_1_after_insert_2' AS point,
    (SELECT sum(memory_usage_bytes)/1048576
     FROM duckdb_memory() WHERE tag='ALLOCATOR')::BIGINT AS allocator_mib;

DELETE FROM t WHERE del;

SELECT
    'round_1_after_delete' AS point,
    (SELECT sum(memory_usage_bytes)/1048576
     FROM duckdb_memory() WHERE tag='ALLOCATOR')::BIGINT AS allocator_mib;

CHECKPOINT;

SELECT
    'round_1_after_explicit_checkpoint' AS point,
    (SELECT sum(memory_usage_bytes)/1048576
     FROM duckdb_memory() WHERE tag='ALLOCATOR')::BIGINT AS allocator_mib;


-- ROUND 2

INSERT INTO t
SELECT i, repeat('x',384) || (i%997)::VARCHAR, (i%20=0)
FROM range(0,100000) tbl(i)
ON CONFLICT (id) DO UPDATE
SET payload = excluded.payload, del = excluded.del;

SELECT
    'round_2_after_insert_1' AS point,
    (SELECT sum(memory_usage_bytes)/1048576
     FROM duckdb_memory() WHERE tag='ALLOCATOR')::BIGINT AS allocator_mib;

INSERT INTO t
SELECT i, repeat('x',384) || (i%997)::VARCHAR, (i%20=0)
FROM range(0,100000) tbl(i)
ON CONFLICT (id) DO UPDATE
SET payload = excluded.payload, del = excluded.del;

SELECT
    'round_2_after_insert_2' AS point,
    (SELECT sum(memory_usage_bytes)/1048576
     FROM duckdb_memory() WHERE tag='ALLOCATOR')::BIGINT AS allocator_mib;

DELETE FROM t WHERE del;

SELECT
    'round_2_after_delete' AS point,
    (SELECT sum(memory_usage_bytes)/1048576
     FROM duckdb_memory() WHERE tag='ALLOCATOR')::BIGINT AS allocator_mib;

CHECKPOINT;

SELECT
    'round_2_after_explicit_checkpoint' AS point,
    (SELECT sum(memory_usage_bytes)/1048576
     FROM duckdb_memory() WHERE tag='ALLOCATOR')::BIGINT AS allocator_mib;
