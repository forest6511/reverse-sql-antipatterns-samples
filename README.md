# 逆引きSQLアンチパターン — サンプルコード / 実機再現環境

書籍『逆引きSQLアンチパターン ― PostgreSQL / MySQL で高速・安全なクエリと設計』
（森川 陽介 著）の companion リポジトリです。

本書の全アンチパターンは「**こんなとき → 再現SQL → 実機 EXPLAIN → 修正 → 再EXPLAIN**」の
5ステップで書かれています。このリポジトリは、その **EXPLAIN(ANALYZE, BUFFERS) を
読者が自分のマシンで再現する**ための Docker 環境と SQL を提供します。

- PostgreSQL **18**
- MySQL **8.4**

## 必要なもの

- Docker / Docker Compose

## クイックスタート

```bash
# 両DBを起動し、シードデータ（users 10万・orders 100万）の投入完了まで待つ
# 初回は orders 100万件の投入に数分かかります
bash scripts/up.sh

# PostgreSQL 18 に接続
docker compose exec pg psql -U app -d app

# MySQL 8.4 に接続
docker compose exec mysql mysql -uroot -proot app
```

## ディレクトリ構成

```text
.
├── docker-compose.yml          # postgres:18 / mysql:8.4
├── db/init/postgres/           # 起動時に自動実行される共通スキーマ・シード
├── db/init/mysql/
├── scripts/
│   ├── up.sh                   # 起動＋シード完了待ち
│   ├── reset.sh                # 初期状態に戻す（down -v → up）
│   ├── pg.sh                   # psql 接続 / SQL実行のショートカット
│   └── mysql.sh                # mysql 接続 / SQL実行のショートカット
├── ch01_nplus1_join/           # 第1章 N+1・重いJOIN
├── ch02_index_not_used/        # 第2章 索引が使われない
├── ...
└── ch09_ai_generated_sql/      # 第9章 AI生成SQLのレビュー
```

各章ディレクトリには、その章のアンチパターン別に
`NN_<name>_anti.sql`（悪い書き方）と `NN_<name>_fixed.sql`（直した書き方）を置きます。
どちらも先頭で `EXPLAIN (ANALYZE, BUFFERS)` を付けて実行し、本書の数値を再現できます。

## 共通シードデータ

| テーブル | 行数 | 用途 |
|---|---|---|
| `users` | 10万 | ユーザー。`status`（active/inactive/banned） |
| `orders` | 100万 | 注文。`user_id` / `amount`（円・整数）/ `status` / `created_at` |

初期状態では **インデックスを張っていません**。
「index が無いから Seq Scan」→「index を張ると Index Scan」の Before/After を
実機で観測できるようにするためです。各章で必要なインデックスは各章の SQL で作成します。
別の再現に移る前に `bash scripts/reset.sh` で初期状態に戻してください。

## EXPLAIN の取り方

PostgreSQL 18:

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders WHERE DATE(created_at) = '2025-01-01';
```

MySQL 8.4:

```sql
EXPLAIN ANALYZE
SELECT * FROM orders WHERE DATE(created_at) = '2025-01-01';
```

> 実行時間はマシンや実行回数（キャッシュ）で変動します。本書の数値と桁が一致すれば
> 再現成功です。数値の絶対値ではなく、**Seq Scan → Index Scan の変化**と
> **桁の改善**に注目してください。

## ライセンス

サンプルコードは書籍購入者の学習用途で自由に利用できます。
