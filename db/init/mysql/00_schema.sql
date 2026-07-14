-- 逆引きSQLアンチパターン — MySQL 8.4 共通スキーマ
--
-- PostgreSQL 側と同じ土台テーブルを MySQL 8.4 で用意する。
-- EXPLAIN / EXPLAIN ANALYZE の書式差（type: ALL / Using filesort 等）を
-- 見せるため、初期状態はインデックスを張らない。
--
-- 文字セットは utf8mb4（05章「絵文字でエラーになる」で照合順序を扱う）。
--
-- 【再現性】RAND(seed) でシードを固定し、created_at は NOW() ではなく
-- 固定基点 '2026-07-01' からの相対にする。誰がいつ作っても同じデータに
-- なり、本書の EXPLAIN の値が手元で追試できる。

CREATE TABLE users (
    id          BIGINT       NOT NULL AUTO_INCREMENT PRIMARY KEY,
    email       VARCHAR(255) NOT NULL,
    status      VARCHAR(16)  NOT NULL,
    created_at  DATETIME     NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE orders (
    id          BIGINT      NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id     BIGINT      NOT NULL,
    amount      INT         NOT NULL,
    status      VARCHAR(16) NOT NULL,
    created_at  DATETIME    NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ── seed: 再帰CTEで連番を作り、users 10万 / orders 100万を投入 ──
-- MySQL には generate_series が無いため recursive CTE を使う。
-- cte_max_recursion_depth を一時的に引き上げる。
SET SESSION cte_max_recursion_depth = 2000000;

INSERT INTO users (email, status, created_at)
WITH RECURSIVE seq (n) AS (
    SELECT 1
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 100000
)
SELECT
    CONCAT('user', n, '@example.com'),
    ELT(1 + (n % 5), 'active','active','active','inactive','banned'),
    -- RAND(seed) に行番号 n を渡すと、行ごとに決定的な値になる
    TIMESTAMP '2026-07-01 00:00:00'
        - INTERVAL FLOOR(RAND(n) * 730) DAY
FROM seq;

INSERT INTO orders (user_id, amount, status, created_at)
WITH RECURSIVE seq (n) AS (
    SELECT 1
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 1000000
)
SELECT
    -- 列ごとに別のシード（n に定数を足す）で決定的かつ独立に散らす
    1 + FLOOR(RAND(n) * 99999),
    100 + FLOOR(RAND(n + 1000000) * 49900),
    ELT(1 + (n % 5), 'pending','paid','paid','shipped','cancelled'),
    TIMESTAMP '2026-07-01 00:00:00'
        - INTERVAL FLOOR(RAND(n + 2000000) * 730) DAY
FROM seq;

ANALYZE TABLE users;
ANALYZE TABLE orders;
