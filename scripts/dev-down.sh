#!/usr/bin/env bash
# Tắt hạ tầng dev FoodMap. Dữ liệu trong volume được GIỮ LẠI.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

docker compose -f infra/docker-compose.yml down

cat <<'EOF'

Đã tắt. Dữ liệu trong volume vẫn còn.

Muốn xoá sạch dữ liệu (KHÔNG HOÀN TÁC ĐƯỢC):
  docker compose -f infra/docker-compose.yml down -v
EOF
