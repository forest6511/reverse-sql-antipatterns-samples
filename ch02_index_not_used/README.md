# 第2章: インデックスを張ったのに効かない

「index を作ったのに Seq Scan になる」全アンチパターンを実機 EXPLAIN で再現します。

## 実行方法

```bash
# PostgreSQL 18
docker compose exec -T pg psql -U app -d app < ch02_index_not_used/pg.sql

# MySQL 8.4（暗黙型変換の認証回避デモ）
docker compose exec -T mysql mysql -uroot -proot app < ch02_index_not_used/mysql.sql
```

各ファイルは作成した index / テーブルを最後に DROP し、初期状態へ戻します。

## この章で見せる数値（実機・postgres:18 / mysql:8.4）

- 関数適用（`lower(email)=`）: Seq Scan 20.1ms → 式インデックス 0.066ms（約 300 倍）
- 前方一致（`LIKE 'prefix%'`）: 非Cロケールで Seq Scan 5.0ms → `text_pattern_ops` 0.068ms
- 中間一致（`LIKE '%mid%'`）: Seq Scan 6.5ms → pg_trgm GIN 0.675ms
- JSONB（`payload @> '{"user_id":42}'`）: Seq Scan 18.2ms → GIN 0.120ms（約 150 倍）
- MySQL 暗黙型変換（`login_token = 0`）: index を seek できず、5 件中 4 件が誤ってマッチ
