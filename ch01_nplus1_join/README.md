# 第1章: N+1 と重い JOIN、過剰取得

「開発環境では速いのに本番で遅くなる」アンチパターンを実機 EXPLAIN で再現します。

前提: リポジトリ直下で `bash scripts/up.sh` を実行し、`users` 10万件 /
`orders` 100万件が投入済みであること。初期状態では `orders` に主キー以外の
インデックスはありません（Before/After を見せるため、あえて素のテーブルにしています）。

## 実行方法

```bash
# PostgreSQL 18
docker compose exec pg psql -U app -d app -f /dev/stdin < ch01_nplus1_join/pg.sql

# MySQL 8.4
docker compose exec -T mysql mysql -uroot -proot app < ch01_nplus1_join/mysql.sql
```

各ファイルは「Before（index なし）→ index 作成 → After」の順に EXPLAIN を出し、
最後に作成した index を DROP して初期状態へ戻します（他章のために素のテーブルを保つ）。

## この章で見せる数値（実機・postgres:18 / mysql:8.4）

- N+1 の内側1本（`WHERE user_id = ?`）
  - PostgreSQL: Parallel Seq Scan 16.8ms → Bitmap Index Scan 0.162ms
  - MySQL: Table scan 153ms → Index lookup 0.0475ms
- 20人ぶんの注文: N+1（21往復）→ JOIN 1本 0.876ms（PostgreSQL）
- DISTINCT 乱用 227ms → EXISTS 126ms（PostgreSQL）
