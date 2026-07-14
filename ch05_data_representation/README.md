# 第5章: データ表現のアンチパターン（金額・時刻・文字コード）

PostgreSQL 18 / MySQL 8.4 実機再現。

## 実行

```bash
# 1節 金額FLOAT誤差（PG）
scripts/pg.sh ch05_data_representation/01_money_float.sql

# 2節 timestamptz 締め日ズレ（PG）
scripts/pg.sh ch05_data_representation/02_timestamp_tz.sql

# 3節 utf8mb3 で絵文字がエラーになる（MySQL・接続を utf8mb4 に）
docker compose exec -T mysql \
  mysql -uroot -proot --default-character-set=utf8mb4 app \
  < ch05_data_representation/03_utf8mb4.sql

# 4節 寿司ビール問題（MySQL）
docker compose exec -T mysql \
  mysql -uroot -proot --default-character-set=utf8mb4 app \
  < ch05_data_representation/04_collation_sushi_beer.sql

# 5節 日付を文字列で持つと範囲検索・ソートが誤る（PG）
scripts/pg.sh ch05_data_representation/05_date_as_string.sql

# 6節 真偽値を文字列で持つと集計が誤る（PG）
scripts/pg.sh ch05_data_representation/06_boolean_as_string.sql
```

## 実機で確認した値

- 1節: `SUM(double precision)` = `10000.000000018848`（誤差） / `NUMERIC` = `10000.00`
- 1節: `0.1::float8 + 0.2::float8` = `0.30000000000000004` / numeric は `0.3`
- 2節: UTC 境界で切ると 0 行（JST早朝が前日に含まれる） / JST 境界で 1 行
- 3節: utf8mb3 列に 🍣 → `ERROR 1366 Incorrect string value: '\xF0\x9F\x8D\xA3'`
- 4節: `🍣 = 🍺 COLLATE utf8mb4_general_ci` = `1` / `utf8mb4_0900_ai_ci` = `0`
- 4節: general_ci の UNIQUE で 🍺 → `ERROR 1062 Duplicate entry`
- 5節: 日付 text の 7月範囲検索 → 2件（ゼロ埋め不揃いが漏れる） / date 型 → 4件
- 6節: is_active text の `= 'true'` → 1件（表記ゆれ） / boolean 型 → 5件
