-- 第7章 MySQL 8.4 セットアップ: 100万件のテーブル
-- 実行: docker compose exec -T mysql mysql -uroot -proot app < ch07_migration_vacuum/00_setup_mysql.sql
--
-- MySQL の Online DDL（INSTANT / INPLACE / COPY）を試すための土台。
-- 再帰CTEで100万件を作るため cte_max_recursion_depth を一時的に上げる。
SET SESSION cte_max_recursion_depth = 2000000;
DROP TABLE IF EXISTS mig_events;
CREATE TABLE mig_events (
    id BIGINT PRIMARY KEY,
    user_id INT NOT NULL,
    payload TEXT NOT NULL
);
INSERT INTO mig_events (id, user_id, payload)
WITH RECURSIVE seq(n) AS (
  SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 1000000
)
SELECT n, (n % 10000) + 1, REPEAT('x', 40) FROM seq;
SELECT count(*) AS cnt FROM mig_events;  -- 1000000
