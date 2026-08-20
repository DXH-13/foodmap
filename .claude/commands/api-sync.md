---
description: Sinh lại TypeScript client từ openapi.yaml cho mobile và admin, rồi kiểm tra kiểu
allowed-tools: Bash(./scripts/gen-api-client.sh:*), Bash(npx tsc:*), Bash(git diff:*), Bash(git status:*)
---

Đồng bộ TypeScript client với hợp đồng API:

1. Đọc skill `api-contract` nếu chưa nắm quy trình.
2. Chạy `./scripts/gen-api-client.sh` (Windows: `.\scripts\gen-api-client.ps1`).
   Sinh lại `mobile/src/api/generated/` và `admin/src/api/generated/`
   từ `docs/SDD/api/openapi.yaml`.
3. Chạy kiểm tra kiểu ở cả hai phần:
   - `cd mobile && npx tsc --noEmit`
   - `cd admin && npx tsc --noEmit`
4. Có lỗi TypeScript thì **đó là tính năng, không phải sự cố** — nó chỉ đúng chỗ code
   đang dùng API cũ. Liệt kê từng lỗi kèm file và dòng, giải thích API đã đổi thế nào,
   rồi hỏi người dùng có muốn bạn sửa luôn không.
5. Chạy `git status` và báo những file nào đã được sinh lại.

Đừng bao giờ sửa tay file trong thư mục `generated/` để làm hết lỗi.
