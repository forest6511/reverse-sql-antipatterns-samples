-- 中間テーブル（正規化）: 'red' タグを正確に取る
DROP TABLE IF EXISTS post_tags, tags_m, posts_m;
CREATE TABLE posts_m (id bigserial PRIMARY KEY, title text);
CREATE TABLE tags_m (id bigserial PRIMARY KEY, name text UNIQUE);
CREATE TABLE post_tags (
    post_id bigint REFERENCES posts_m(id),
    tag_id bigint REFERENCES tags_m(id),
    PRIMARY KEY (post_id, tag_id)
);
INSERT INTO posts_m (title) VALUES ('post1'),('post2'),('post3');
INSERT INTO tags_m (name) VALUES ('red'),('green'),('blue'),('yellow'),('bored'),('purple');
INSERT INTO post_tags VALUES
 (1,1),(1,2),(1,3),   -- post1: red,green,blue
 (2,4),(2,5),(2,6),   -- post2: yellow,bored,purple
 (3,2),(3,3);         -- post3: green,blue
-- 'red' タグの投稿を正確に取る（誤爆なし）
SELECT p.id, p.title
FROM posts_m p
JOIN post_tags pt ON pt.post_id = p.id
JOIN tags_m t ON t.id = pt.tag_id
WHERE t.name = 'red';
