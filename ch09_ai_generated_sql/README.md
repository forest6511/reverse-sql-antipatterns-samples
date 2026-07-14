# 第9章: AIが吐いたSQL・スキーマをそのまま出荷するな

AI 生成 SQL のレビュー観点（capstone）。本章は新規の EXPLAIN ネタを増やさず、
各章のアンチパターンを「AI が生成しがちな形」として束ねる。ここで実機再現するのは
A 群（実行時にエラーになる・破壊される系）のみ。

## 実行

```bash
bash ../scripts/up.sh          # postgres:18 / mysql:8.4 を起動
bash ../scripts/pg.sh ch09_ai_generated_sql/pg.sql       # orders09 を 100万件で作成
bash ../scripts/mysql.sh ch09_ai_generated_sql/mysql.sql # 同上（MySQL）
```

## 実機で見せるもの

### PostgreSQL 18

- スキーマ幻覚: `SELECT id, total_amount FROM orders09 ...`
  → `ERROR: column "total_amount" does not exist`
  （タイポ `amout` なら `HINT: Perhaps you meant to reference the column "o.amount".`）
- WHERE 無し DELETE の対象件数（安全確認は BEGIN...ROLLBACK）:
  ```sql
  BEGIN; DELETE FROM orders09; -- DELETE 1000000
  ROLLBACK;
  ```
- レビューの安全手順（まず件数を見る）:
  ```sql
  SELECT count(*) FROM orders09
   WHERE status = 'cancelled' AND created_at < now() - interval '180 days';
  -- 169434（この件数が想定と合うか確認してから DELETE する）
  ```

### MySQL 8.4

- スキーマ幻覚: `SELECT id, total_amount FROM orders09 LIMIT 5;`
  → `ERROR 1054 (42S22): Unknown column 'total_amount' in 'field list'`
- WHERE 無し UPDATE の対象件数:
  ```sql
  START TRANSACTION;
  UPDATE orders09 SET status = 'archived'; -- ROW_COUNT() = 1000000
  ROLLBACK;
  ```

B 群（N+1・sargability・OFFSET・NULL・データ表現・トランザクション・マイグレーション・
スキーマ設計）は第1〜8章の各ディレクトリを参照。
