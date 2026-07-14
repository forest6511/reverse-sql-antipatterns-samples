-- 第4章 MySQL 8.4 — NULL三値論理と暗黙変換
-- 実行: docker compose exec -T mysql mysql -uroot -proot app < ch04_null_implicit_cast/mysql.sql
--
-- MySQL でも NULL 三値論理は同じ。加えて MySQL 固有の「暗黙型変換で比較が誤る」を見せる。

SELECT '### 準備: 検証テーブル' AS msg;
DROP TABLE IF EXISTS coupons;
CREATE TABLE coupons (
    id       BIGINT AUTO_INCREMENT PRIMARY KEY,
    code     VARCHAR(20),
    campaign VARCHAR(20)   -- NULL あり
);
INSERT INTO coupons (code, campaign) VALUES
    ('A1','summer'),('A2','summer'),('A3','winter'),('A4',NULL),('A5',NULL);

SELECT '=== DEMO 1-anti: NOT IN に NULL が混ざると1件も返らない（MySQL も同じ）===' AS msg;
SELECT id, code FROM coupons WHERE campaign NOT IN ('summer','winter',NULL);

SELECT '=== DEMO 1-fixed: NOT EXISTS ===' AS msg;
SELECT id, code FROM coupons c
WHERE NOT EXISTS (SELECT 1 FROM coupons e WHERE e.campaign = c.campaign AND e.campaign IN ('summer','winter'));

SELECT '=== DEMO 2: <> は NULL 行を落とす / NULL 安全等価 <=> ===' AS msg;
SELECT id, code, campaign FROM coupons WHERE campaign <> 'summer';
SELECT '--- <=> (NULL安全) で NULL 同士を比較 ---' AS msg;
SELECT id, code FROM coupons WHERE campaign <=> NULL;

SELECT '### 準備2: 暗黙変換デモ用テーブル（トークンを文字列で保持）' AS msg;
DROP TABLE IF EXISTS sessions;
CREATE TABLE sessions (
    id    BIGINT AUTO_INCREMENT PRIMARY KEY,
    token VARCHAR(64)
);
INSERT INTO sessions (token) VALUES
    ('abc123'),('9xyz'),('42secret'),('0000'),('token99');

SELECT '=== DEMO 3-anti: token = 0（文字列カラム = 数値）で誤マッチ ===' AS msg;
-- 文字列は先頭から数値化され、先頭が数字でないものは 0 になる → token=0 が誤爆
SELECT id, token FROM sessions WHERE token = 0;
SHOW WARNINGS;

SELECT '=== DEMO 3-fixed: 定数をクォートすれば正しく比較 ===' AS msg;
SELECT id, token FROM sessions WHERE token = '0';

SELECT '### 後片付け' AS msg;
DROP TABLE sessions;
DROP TABLE coupons;
