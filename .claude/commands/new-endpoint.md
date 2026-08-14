---
description: Thêm một endpoint API mới theo đúng quy trình contract-first, xuyên suốt docs → backend → client
argument-hint: <mô tả endpoint, ví dụ "lấy danh sách review của một địa điểm, có phân trang">
---

Thêm endpoint mới cho FoodMap: **$ARGUMENTS**

Đọc skill `api-contract` trước. Làm **đúng thứ tự** sau, không đảo:

### 1. Làm rõ

Trước khi viết gì, xác định và nêu lại cho người dùng xác nhận:
- Method + path (danh từ số nhiều, kebab-case)
- `operationId` (camelCase, động từ + danh từ)
- Tham số đường dẫn / query, có phân trang không
- Schema request và response
- Ai được gọi (GUEST / USER / MODERATOR / ADMIN) — đối chiếu bảng phân quyền
  trong skill `foodmap-domain`
- Các trường hợp lỗi và mã lỗi tương ứng

Có chỗ nào chưa rõ thì hỏi, đừng tự đoán.

### 2. Sửa `docs/03-api/openapi.yaml`

Thêm path, schema, và mã lỗi mới. Bảo đảm: có `tags`, `summary` tiếng Việt,
`required`/`nullable` khai đúng, danh sách thì dùng schema `Page`, lỗi dùng `ApiError`.

### 3. Sinh lại client

Chạy `./scripts/gen-api-client.sh`, rồi `npx tsc --noEmit` ở cả `mobile/` và `admin/`.

### 4. Implement backend

Giao cho subagent `backend-dev`, hoặc tự làm theo skill `spring-backend`:
controller → service → repository, DTO qua MapStruct, phân quyền bằng `@PreAuthorize`.
Cần đổi schema DB thì dùng subagent `db-designer` và tạo migration Flyway mới.

### 5. Viết test

Tối thiểu: happy path, lỗi validation, và phân quyền (user không đủ quyền → 403).

### 6. Dùng ở client (nếu được yêu cầu)

Mobile theo skill `expo-mobile`, admin theo agent `admin-dev`.

### 7. Kiểm tra cuối

- `cd backend && ./gradlew build test`
- `cd mobile && npx tsc --noEmit`
- `cd admin && npx tsc --noEmit`
- Chạy subagent `api-contract-guard` để xác nhận code khớp spec

Báo lại: những file nào đã đổi ở repo nào, và cần commit ở đâu trước
(submodule trước, repo cha sau).
