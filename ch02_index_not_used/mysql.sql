-- 第2章 MySQL 8.4 — インデックスが使われないアンチパターン（暗黙型変換）
-- 実行: docker compose exec -T mysql mysql -uroot -proot app < ch02_index_not_used/mysql.sql

SELECT '### 準備: login_token（文字列・index あり）のデモ用テーブル' AS step;
DROP TABLE IF EXISTS accounts;
CREATE TABLE accounts (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    login_token VARCHAR(32) NOT NULL,
    KEY idx_token (login_token)
) ENGINE=InnoDB;
INSERT INTO accounts (login_token) VALUES
    ('abc123'), ('secret999'), ('token_007'), ('7hexstr'), ('admin_key');

SELECT '### anti: 文字列カラム = 数値（暗黙変換で全行マッチ・認証回避）' AS step;
-- 4行が返る。全トークンが DOUBLE に変換され、先頭が数字でないものは 0 になる
SELECT * FROM accounts WHERE login_token = 0;
SHOW WARNINGS;

SELECT '### anti の EXPLAIN ANALYZE: index を seek できず全走査' AS step;
EXPLAIN ANALYZE SELECT * FROM accounts WHERE login_token = 0;

SELECT '### fixed: クォートで文字列比較（index が効く・正しい結果）' AS step;
EXPLAIN ANALYZE SELECT * FROM accounts WHERE login_token = '0';
SELECT * FROM accounts WHERE login_token = 'secret999';

SELECT '### 後片付け' AS step;
DROP TABLE accounts;
