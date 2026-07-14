-- カンマ区切りタグ（Jaywalking）: LIKE '%red%' が Seq Scan + 誤爆
DROP TABLE IF EXISTS posts_csv;
CREATE TABLE posts_csv (id bigserial PRIMARY KEY, title text, tags text);
INSERT INTO posts_csv (title, tags) VALUES
 ('post1', 'red,green,blue'),
 ('post2', 'yellow,bored,purple'),  -- 'bored' に 'red' が含まれる（誤爆の種）
 ('post3', 'green,blue');
-- 'red' タグの投稿を LIKE で探す
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF)
SELECT id, title FROM posts_csv WHERE tags LIKE '%red%';
SELECT id, title, tags FROM posts_csv WHERE tags LIKE '%red%';
