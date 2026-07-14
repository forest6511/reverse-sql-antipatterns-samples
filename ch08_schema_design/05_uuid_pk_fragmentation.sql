-- v4(ランダム)を主キーに 50万件挿入
DROP TABLE IF EXISTS pk_v4;
CREATE TABLE pk_v4 (id uuid PRIMARY KEY DEFAULT gen_random_uuid(), payload text);
\timing on
INSERT INTO pk_v4 (payload)
SELECT repeat('x', 30) FROM generate_series(1, 500000);
\timing off

-- v7(時系列)を主キーに 50万件挿入
DROP TABLE IF EXISTS pk_v7;
CREATE TABLE pk_v7 (id uuid PRIMARY KEY DEFAULT uuidv7(), payload text);
\timing on
INSERT INTO pk_v7 (payload)
SELECT repeat('x', 30) FROM generate_series(1, 500000);
\timing off

-- 主キーインデックスのサイズ比較
SELECT 'v4_random' AS type,
       pg_size_pretty(pg_relation_size('pk_v4_pkey')) AS pk_index_size
UNION ALL
SELECT 'v7_time', pg_size_pretty(pg_relation_size('pk_v7_pkey'));
