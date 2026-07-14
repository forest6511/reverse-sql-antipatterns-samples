-- 第5章 6節: 真偽値を文字列で持つと表記ゆれで集計が誤る（PostgreSQL 18）
-- 実行: scripts/pg.sh ch05_data_representation/06_boolean_as_string.sql

-- アンチ: text 列に表記ゆれの真偽値
DROP TABLE IF EXISTS accounts_str;
CREATE TABLE accounts_str (
    id bigserial PRIMARY KEY,
    is_active text
);
INSERT INTO accounts_str (is_active) VALUES
    ('true'), ('TRUE'), ('1'), ('t'), ('yes'),
    ('false'), ('0');

-- = 'true' は完全一致 → 5件のはずが 1件
SELECT COUNT(*) AS active_count
FROM accounts_str WHERE is_active = 'true';

-- 正: boolean 型 → 表記ゆれを吸収し 5件、不正値は INSERT時に弾く
DROP TABLE IF EXISTS accounts_b;
CREATE TABLE accounts_b (
    id bigserial PRIMARY KEY,
    is_active boolean
);
INSERT INTO accounts_b (is_active) VALUES
    ('true'), ('TRUE'), ('1'), ('t'), ('yes'),
    ('false'), ('0');

SELECT COUNT(*) AS active_count
FROM accounts_b WHERE is_active = true;
