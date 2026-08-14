#!/usr/bin/env bash
# Khởi tạo workspace FoodMap: submodule, file .env, dependency.
# Chạy được nhiều lần, an toàn.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

info() { printf '\n\033[1;36m==> %s\033[0m\n' "$1"; }
warn() { printf '\033[1;33m!  %s\033[0m\n' "$1"; }
ok()   { printf '\033[1;32m✓  %s\033[0m\n' "$1"; }

# --- Kiểm tra công cụ cần thiết ---------------------------------------------
info "Kiểm tra công cụ"
missing=0
for tool in git docker node npm java; do
  if command -v "$tool" >/dev/null 2>&1; then
    ok "$tool"
  else
    warn "Thiếu: $tool"
    missing=1
  fi
done
if [ "$missing" -eq 1 ]; then
  warn "Cài đủ công cụ trên rồi chạy lại. Cần: Git, Docker Desktop, Node 20+, JDK 21."
  exit 1
fi

node_major="$(node -p 'process.versions.node.split(".")[0]')"
[ "$node_major" -ge 20 ] || warn "Node $(node -v) cũ hơn khuyến nghị (20+)."

# --- Submodule ---------------------------------------------------------------
info "Đồng bộ submodule"
git submodule update --init --recursive
git submodule status

# --- File .env ---------------------------------------------------------------
info "Chuẩn bị file môi trường"
if [ -f infra/.env ]; then
  ok "infra/.env đã có, giữ nguyên"
else
  cp infra/.env.example infra/.env
  ok "Đã tạo infra/.env từ .env.example"
  warn "Cần điền giá trị thật: GOOGLE_MAPS_API_KEY, ANTHROPIC_API_KEY, JWT_SECRET"
fi

# --- Dependency --------------------------------------------------------------
for client in mobile admin; do
  if [ ! -f "$client/package.json" ]; then
    warn "Bỏ qua $client — chưa có package.json"
    continue
  fi

  info "Cài dependency cho $client"
  # Có lockfile thì dùng `npm ci`, KHÔNG dùng `npm install`.
  # Lý do không phải lý thuyết: `npm install` trên cây sạch đã từng cài thiếu —
  # gói có mặt nhưng thiếu toàn bộ file .d.ts, khiến `tsc --noEmit` báo
  # "Cannot find module" cho những gói rõ ràng đang nằm trong node_modules.
  if [ -f "$client/package-lock.json" ]; then
    (cd "$client" && npm ci --no-audit --no-fund)
  else
    (cd "$client" && npm install --no-audit --no-fund)
  fi
  ok "$client sẵn sàng"
done

if [ -f backend/gradlew ]; then
  info "Tải dependency cho backend"
  (cd backend && chmod +x gradlew && ./gradlew --quiet dependencies >/dev/null)
  ok "Backend sẵn sàng"
else
  warn "Bỏ qua backend — chưa có gradlew"
fi

info "Xong"
cat <<'EOF'

Bước tiếp theo:

  ./scripts/dev-up.sh                 bật Postgres, Redis, MinIO, Mailpit
  cd backend && ./gradlew bootRun     API tại http://localhost:8080
  cd mobile  && npx expo start        app mobile
  cd admin   && npm run dev           trang quản trị tại http://localhost:3000

Nhớ điền các key thật vào infra/.env trước khi chạy backend.
EOF
