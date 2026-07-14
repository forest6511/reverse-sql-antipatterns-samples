-- 第6章 1節: 在庫二重販売（Lost Update）／PostgreSQL 18
-- 2つの psql セッション（A / B）を並行させる。

-- 準備（どちらかのセッションで1回）
DROP TABLE IF EXISTS products;
CREATE TABLE products (id bigint PRIMARY KEY, name text, stock int);
INSERT INTO products VALUES (1, 'limited-item', 1);

-- ===== アンチ: チェックと更新を分ける（二重販売する）=====
-- セッションA                        セッションB
-- BEGIN;
-- SELECT stock FROM products WHERE id=1;   -- A: 1
--                                    BEGIN;
--                                    SELECT stock FROM products WHERE id=1; -- B: 1
-- UPDATE products SET stock=0 WHERE id=1;  -- A sells
-- COMMIT;
--                                    UPDATE products SET stock=0 WHERE id=1; -- B sells
--                                    COMMIT;
-- => 在庫0だが2個売れた

-- ===== 正: アトミックUPDATE（在庫を割らない）=====
-- UPDATE products SET stock=1 WHERE id=1;  -- reset
-- セッションA                        セッションB
-- BEGIN;
-- UPDATE products SET stock=stock-1 WHERE id=1 AND stock>0;  -- A: UPDATE 1
--                                    BEGIN;
--                                    UPDATE products SET stock=stock-1 WHERE id=1 AND stock>0;
--                                        -- B: Aのロック待ち
-- COMMIT;
--                                    COMMIT;  -- B: UPDATE 0（在庫切れ）
