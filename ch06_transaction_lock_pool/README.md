# 第6章: トランザクション・ロック・コネクションプール枯渇

PostgreSQL 18 で 2 セッション並行を実機再現。

## 2セッションの動かし方

在庫二重販売・残高 Lost Update・デッドロックは、2 つの psql セッションを並行させて
再現する。ターミナルを 2 つ開き、それぞれで対話 psql に入る。

```bash
# ターミナル1（セッションA）
scripts/pg.sh

# ターミナル2（セッションB）
scripts/pg.sh
```

各 `.sql` のコメントにある「セッションA / セッションB」の順で、A→B→A… と交互に
手で実行する（自動化する場合は名前付き FIFO で制御する）。

## 実機で確認した値

### 1節 在庫二重販売（01_oversell.sql）
- 非アトミック（SET stock=0）: A も B も stock=1 を読み、両方 commit → 在庫0だが2個売れる
- アトミック（SET stock=stock-1 WHERE stock>0）: A=`UPDATE 1`（売れた） / B=`UPDATE 0`（在庫切れ）

### 2節 残高 Lost Update（02_lost_update_balance.sql）
- read→計算→書き戻し: 1000 に A,B が +100 → 最終 1100（期待 1200、+100 が消える）
- アトミック（SET balance=balance+100）: 最終 1200（両方反映）

### 3節 デッドロック（03_deadlock.sql）
- A: 口座1→2 / B: 口座2→1 の順にロック → `ERROR: deadlock detected`、A がロールバック、B 完了
- 解決: 全 tx で id 昇順にロック → デッドロックなし

### 4節 idle in transaction（04_idle_in_transaction.sql）
- tx を開いたまま放置 → 別接続の pg_stat_activity で `state = 'idle in transaction'` を観測
- `SHOW max_connections;` → 100（既定）
