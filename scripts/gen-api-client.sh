#!/usr/bin/env bash
# Sinh TypeScript client cho mobile và admin từ docs/SDD/api/openapi.yaml.
#
# ĐỪNG SỬA TAY file trong các thư mục generated/ — chúng bị ghi đè mỗi lần chạy script này.
# Muốn đổi kiểu dữ liệu API thì sửa openapi.yaml rồi chạy lại.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

SPEC="docs/SDD/api/openapi.yaml"

info() { printf '\n\033[1;36m==> %s\033[0m\n' "$1"; }
warn() { printf '\033[1;33m!  %s\033[0m\n' "$1"; }
ok()   { printf '\033[1;32m✓  %s\033[0m\n' "$1"; }

if [ ! -f "$SPEC" ]; then
  warn "Không tìm thấy $SPEC"
  warn "Chạy 'git submodule update --init' để lấy submodule docs."
  exit 1
fi

generate() {
  local target="$1"                       # mobile | admin
  local outdir="$target/src/api/generated"

  if [ ! -f "$target/package.json" ]; then
    warn "Bỏ qua $target — chưa có package.json"
    return
  fi

  info "Sinh client cho $target"
  mkdir -p "$outdir"

  npx --yes openapi-typescript "$SPEC" --output "$outdir/schema.ts"

  cat > "$outdir/README.md" <<'EOF'
# Thư mục sinh tự động — KHÔNG SỬA TAY

Toàn bộ nội dung ở đây được sinh từ `docs/SDD/api/openapi.yaml` bằng
`scripts/gen-api-client.sh`. Mọi thay đổi sửa tay sẽ mất khi chạy lại script.

Cần đổi kiểu dữ liệu của API? Sửa `docs/SDD/api/openapi.yaml`, rồi:

    ./scripts/gen-api-client.sh

Chi tiết quy trình: skill `api-contract` trong `.claude/skills/`.
EOF

  ok "$outdir/schema.ts"
}

generate mobile
generate admin

info "Kiểm tra kiểu"
typecheck_failed=0
for target in mobile admin; do
  if [ -f "$target/tsconfig.json" ]; then
    printf '    %s: ' "$target"
    if (cd "$target" && npx --yes tsc --noEmit >/dev/null 2>&1); then
      printf '\033[1;32mOK\033[0m\n'
    else
      printf '\033[1;33mcó lỗi\033[0m\n'
      typecheck_failed=1
    fi
  fi
done

if [ "$typecheck_failed" -eq 1 ]; then
  cat <<'EOF'

Có lỗi TypeScript. Đây thường là điều TỐT: nó chỉ đúng những chỗ code đang dùng
API cũ sau khi hợp đồng thay đổi. Xem chi tiết bằng:

  cd mobile && npx tsc --noEmit
  cd admin  && npx tsc --noEmit

Đừng sửa file trong generated/ để làm hết lỗi — hãy sửa chỗ gọi.
EOF
  exit 1
fi

ok "Xong"
