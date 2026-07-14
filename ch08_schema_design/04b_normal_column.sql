DROP TABLE IF EXISTS products_normal;
CREATE TABLE products_normal (
    id bigserial PRIMARY KEY,
    price int NOT NULL,
    status text NOT NULL,
    attrs jsonb  -- 可変・疎な属性だけ JSONB に
);
-- price に文字列を入れようとすると型で弾かれる
INSERT INTO products_normal (price, status) VALUES ('abc', 'active');
