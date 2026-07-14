-- 第5章 1節: 金額を浮動小数点で持つとズレる（PostgreSQL 18）
-- 実行: scripts/pg.sh ch05_data_representation/01_money_float.sql

-- アンチ: double precision で 0.1 を 10 万件足す
DROP TABLE IF EXISTS payments_f;
CREATE TABLE payments_f (
    id bigserial PRIMARY KEY,
    amount double precision
);
INSERT INTO payments_f (amount)
    SELECT 0.1 FROM generate_series(1, 100000);

SELECT SUM(amount) AS sum_float FROM payments_f;   -- 10000.000000018848

-- float の古典的誤差
SELECT 0.1::float8 + 0.2::float8 AS float_add;      -- 0.30000000000000004

-- 正: numeric(12,2)
DROP TABLE IF EXISTS payments_n;
CREATE TABLE payments_n (
    id bigserial PRIMARY KEY,
    amount numeric(12,2)
);
INSERT INTO payments_n (amount)
    SELECT 0.10 FROM generate_series(1, 100000);

SELECT SUM(amount) AS sum_numeric FROM payments_n;  -- 10000.00
SELECT 0.1::numeric + 0.2::numeric AS numeric_add;  -- 0.3
