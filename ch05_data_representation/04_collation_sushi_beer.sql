-- 第5章 4節: utf8mb4_general_ci の寿司ビール問題（MySQL 8.4）
-- 実行:
--   docker compose exec -T mysql \
--     mysql -uroot -proot --default-character-set=utf8mb4 app \
--     < ch05_data_representation/04_collation_sushi_beer.sql

-- アンチ: general_ci では 🍣 = 🍺 が TRUE(1)
SELECT '🍣' = '🍺' COLLATE utf8mb4_general_ci AS general_ci;   -- 1

-- general_ci の UNIQUE 制約で別絵文字が衝突する
DROP TABLE IF EXISTS reactions;
CREATE TABLE reactions (
    emoji VARCHAR(8) NOT NULL,
    UNIQUE KEY uq_emoji (emoji)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

INSERT INTO reactions (emoji) VALUES ('🍣');
-- 次は ERROR 1062 Duplicate entry になる:
-- INSERT INTO reactions (emoji) VALUES ('🍺');

-- 正: 補助文字を区別する照合順序では FALSE(0)
SELECT '🍣' = '🍺' COLLATE utf8mb4_0900_ai_ci AS ai_ci;   -- 0
SELECT '🍣' = '🍺' COLLATE utf8mb4_bin        AS bin_col; -- 0
