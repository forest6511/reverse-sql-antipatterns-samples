#!/usr/bin/env bash
# DBを初期状態（シード投入直後）に戻す。
# 各章でインデックスを張ったりデータを書き換えた後、次の再現に移る前に実行する。
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> コンテナとボリュームを破棄して作り直す"
docker compose down -v
exec "$(dirname "$0")/up.sh"
