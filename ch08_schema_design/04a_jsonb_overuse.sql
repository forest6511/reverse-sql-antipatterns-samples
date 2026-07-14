-- JSONB使いすぎ: 検索属性を JSONB に押し込むと型・制約が効かない
DROP TABLE IF EXISTS products_jsonb;
CREATE TABLE products_jsonb (id bigserial PRIMARY KEY, attrs jsonb);
INSERT INTO products_jsonb (attrs) VALUES
 ('{"price": 1000, "status": "active"}'),
 ('{"price": "2000", "status": "active"}'),  -- price が文字列（型が混在）
 ('{"status": "active"}');                    -- price 欠落（NOT NULL不能）

-- 価格1500超を探したいが、文字列と数値が混在して比較が誤る
SELECT id, attrs->>'price' AS price_text FROM products_jsonb;
-- 数値として比較しようとすると型キャストが必要で、文字列 "2000" も紛れる
SELECT id, (attrs->>'price')::numeric AS price
FROM products_jsonb WHERE attrs ? 'price';
