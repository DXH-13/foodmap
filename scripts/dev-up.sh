#!/usr/bin/env bash
# Bật hạ tầng dev FoodMap và đợi tới khi mọi service khoẻ.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
COMPOSE="docker compose -f infra/docker-compose.yml"

info() { printf '\n\033[1;36m==> %s\033[0m\n' "$1"; }
warn() { printf '\033[1;33m!  %s\033[0m\n' "$1"; }
ok()   { printf '\033[1;32m✓  %s\033[0m\n' "$1"; }

if [ ! -f infra/.env ]; then
  warn "Chưa có infra/.env — tạo từ .env.example"
  cp infra/.env.example infra/.env
  warn "Nhớ điền GOOGLE_MAPS_API_KEY, ANTHROPIC_API_KEY, JWT_SECRET"
fi

info "Khởi động dịch vụ"
$COMPOSE up -d

info "Đợi healthcheck (tối đa 90 giây)"
for i in $(seq 1 45); do
  unhealthy="$($COMPOSE ps --format '{{.Service}} {{.Health}}' | grep -cv ' healthy$' || true)"
  if [ "$unhealthy" -eq 0 ]; then
    ok "Tất cả dịch vụ đã khoẻ"
    break
  fi
  printf '.'
  sleep 2
  if [ "$i" -eq 45 ]; then
    printf '\n'
    warn "Hết thời gian chờ. Trạng thái hiện tại:"
    $COMPOSE ps
    warn "Xem log: $COMPOSE logs <service> --tail 50"
    exit 1
  fi
done
printf '\n'

info "Kiểm tra PostGIS"
docker exec foodmap-db psql -U foodmap -d foodmap -tAc "SELECT PostGIS_Version();" \
  | sed 's/^/    PostGIS /'

$COMPOSE ps

cat <<'EOF'

Dịch vụ đang chạy:

  PostgreSQL + PostGIS  localhost:5433   db/user/pass: foodmap
  Redis                 localhost:6380
  MinIO API             localhost:9002
  MinIO Console         http://localhost:9003   (minioadmin / minioadmin)
  Mailpit SMTP          localhost:1025
  Mailpit UI            http://localhost:8025

Cổng lệch chuẩn là cố ý — tránh đụng Postgres/Redis/MinIO khác trên máy.
Đổi được trong infra/.env.

Tắt bằng: ./scripts/dev-down.sh
EOF
