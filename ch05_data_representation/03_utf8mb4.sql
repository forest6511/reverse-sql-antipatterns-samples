-- 第5章 3節: utf8mb3 で絵文字を保存するとエラーになる（MySQL 8.4）
-- 実行（接続を utf8mb4 にすること）:
--   docker compose exec -T mysql \
--     mysql -uroot -proot --default-character-set=utf8mb4 app \
--     < ch05_data_representation/03_utf8mb4.sql

-- アンチ: utf8mb3 列に絵文字（4byte）→ ERROR 1366 Incorrect string value
DROP TABLE IF EXISTS emoji_u3;
CREATE TABLE emoji_u3 (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50)
) CHARACTER SET utf8mb3;

-- 次の1行は STRICT_TRANS_TABLES（8.4既定）でエラーになる:
-- INSERT INTO emoji_u3 (name) VALUES ('sushi 🍣');
-- ERROR 1366 (HY000): Incorrect string value: '\xF0\x9F\x8D\xA3'

-- 正: utf8mb4 列なら成功
DROP TABLE IF EXISTS emoji_u4;
CREATE TABLE emoji_u4 (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50)
) CHARACTER SET utf8mb4;

INSERT INTO emoji_u4 (name) VALUES ('sushi 🍣');
SELECT id, name FROM emoji_u4;
