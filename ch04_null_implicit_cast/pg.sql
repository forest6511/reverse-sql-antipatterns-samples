-- 第4章 PostgreSQL 18 — NULL三値論理と暗黙変換
-- 実行: docker compose exec -T pg psql -U app -d app < ch04_null_implicit_cast/pg.sql
--
-- この章は「速さ」でなく「エラーを出さないまま誤った結果を返す」ことを見せる。
-- 小さな検証テーブルを作り、件数がどう狂うかを実データで示す。最後に DROP。

\echo '### 準備: 検証テーブル（coupons: NULL を含む）'
DROP TABLE IF EXISTS coupons;
CREATE TABLE coupons (
    id        bigserial PRIMARY KEY,
    code      text,
    campaign  text        -- NULL あり（未割当キャンペーン）
);
INSERT INTO coupons (code, campaign) VALUES
    ('A1', 'summer'),
    ('A2', 'summer'),
    ('A3', 'winter'),
    ('A4',  NULL),        -- キャンペーン未設定
    ('A5',  NULL);
\echo '全 5 行。campaign が NULL の行が 2 行ある。'

\echo ''
\echo '=== DEMO 1-anti: NOT IN にサブクエリ結果の NULL が混ざると1件も返らない ==='
\echo 'summer/winter 以外のクーポンを探したい（期待: A4,A5 の2行 … にはならない）'
SELECT id, code, campaign
FROM coupons
WHERE campaign NOT IN ('summer', 'winter', NULL);
\echo '↑ 0 行。NOT IN に NULL が混じると全体が UNKNOWN になり、何も返らない。'

\echo ''
\echo '=== DEMO 1-real: 実務ではサブクエリの NULL で起きる ==='
\echo 'excluded に NULL が1件でもあると NOT IN が1件も返らない再現'
DROP TABLE IF EXISTS excluded;
CREATE TABLE excluded (campaign text);
INSERT INTO excluded VALUES ('summer'), (NULL);   -- NULL が紛れ込む
SELECT id, code FROM coupons
WHERE campaign NOT IN (SELECT campaign FROM excluded);
\echo '↑ 0 行。excluded に NULL があるだけで結果が1件も返らない。'

\echo ''
\echo '=== DEMO 1-fixed: NOT EXISTS なら NULL に強い ==='
SELECT id, code FROM coupons c
WHERE NOT EXISTS (
    SELECT 1 FROM excluded e WHERE e.campaign = c.campaign
);
\echo '↑ campaign が NULL の A4,A5 は「除外リストに無い」ので残る（NOT EXISTS の意味論）。'

\echo ''
\echo '=== DEMO 2-anti: <> ''summer'' は NULL 行をエラーを出さず除外する ==='
SELECT id, code, campaign FROM coupons WHERE campaign <> 'summer';
\echo '↑ winter だけ返り、campaign が NULL の A4,A5 が消える（NULL <> summer は UNKNOWN）。'

\echo ''
\echo '=== DEMO 2-fixed: IS DISTINCT FROM なら NULL も対象に含む ==='
SELECT id, code, campaign FROM coupons WHERE campaign IS DISTINCT FROM 'summer';
\echo '↑ winter と NULL の3行。NULL を「summer とは異なる」と正しく扱う。'

\echo ''
\echo '=== DEMO 3: 集計関数は NULL をエラーを出さず除外する ==='
DROP TABLE IF EXISTS surveys;
CREATE TABLE surveys (id bigserial PRIMARY KEY, respondent text, score integer);
INSERT INTO surveys (respondent, score) VALUES
    ('u1', 5), ('u2', 3), ('u3', NULL), ('u4', 4), ('u5', NULL);
\echo '全5行、score が NULL の行が2行（未回答）。'
\echo '--- COUNT(*)=5 だが COUNT(score)=3（NULL を数えない）---'
SELECT count(*) AS all_rows, count(score) AS score_rows FROM surveys;
\echo '--- AVG(score) は NULL を分母から外す＝回答者中の平均 4.0 ---'
SELECT avg(score) AS avg_score, sum(score) AS sum_score FROM surveys;
\echo '--- 全5人での平均が欲しいなら coalesce で 0 埋め → 2.4 ---'
SELECT avg(coalesce(score, 0)) AS avg_all5 FROM surveys;
DROP TABLE surveys;

\echo ''
\echo '=== DEMO 4: LEFT JOIN + WHERE で外部結合が内部結合と同じ挙動になる ==='
DROP TABLE IF EXISTS reviews;
DROP TABLE IF EXISTS shops;
CREATE TABLE shops (id bigserial PRIMARY KEY, name text);
CREATE TABLE reviews (id bigserial PRIMARY KEY, shop_id bigint, rating integer);
INSERT INTO shops (name) VALUES ('A'), ('B'), ('C');
INSERT INTO reviews (shop_id, rating) VALUES (1, 5), (1, 3), (3, 4);
\echo '--- 期待: LEFT JOIN で全3店（B はレビュー無しで 0 件）---'
SELECT s.name, count(r.id) AS review_count
FROM shops s LEFT JOIN reviews r ON r.shop_id = s.id
GROUP BY s.name ORDER BY s.name;
\echo '--- アンチ: WHERE r.rating >= 3 で B が欠落し2店になる ---'
SELECT s.name, count(r.id) AS review_count
FROM shops s LEFT JOIN reviews r ON r.shop_id = s.id
WHERE r.rating >= 3
GROUP BY s.name ORDER BY s.name;
\echo '--- 修正: 条件を ON 側に置くと B が残る ---'
SELECT s.name, count(r.id) AS review_count
FROM shops s LEFT JOIN reviews r ON r.shop_id = s.id AND r.rating >= 3
GROUP BY s.name ORDER BY s.name;
DROP TABLE reviews;
DROP TABLE shops;

\echo ''
\echo '### 後片付け'
DROP TABLE excluded;
DROP TABLE coupons;
