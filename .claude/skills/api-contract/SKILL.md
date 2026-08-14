---
name: api-contract
description: Quy trình contract-first cho FoodMap - dùng bất cứ khi nào thêm, sửa hoặc xoá một endpoint API, đổi DTO/schema request-response, hoặc khi TypeScript client ở mobile/admin không khớp với backend. Đọc TRƯỚC khi viết controller Spring hoặc gọi API ở client.
---

# Contract-first: quy trình sửa API

`docs/03-api/openapi.yaml` là **nguồn sự thật duy nhất**. Java (backend) và TypeScript
(mobile, admin) không share type trực tiếp được, nên OpenAPI là cầu nối. Lệch file này
là lệch cả ba bên.

## Thứ tự bắt buộc

```
1. Sửa docs/03-api/openapi.yaml
2. ./scripts/gen-api-client.sh          → sinh lại TS client
3. Implement backend theo spec
4. Dùng client đã sinh ở mobile / admin
5. Viết test ở backend
6. Commit: openapi.yaml + client sinh ra + code — trong cùng một PR
```

Làm ngược thứ tự (viết controller trước rồi mới sửa spec) dẫn tới spec mô tả sai hiện
thực, và client sinh ra sai. Đừng làm.

## Nghiêm cấm

- ❌ Sửa tay file trong `mobile/src/api/generated/` hoặc `admin/src/api/generated/`.
  Chúng bị ghi đè mỗi lần chạy generator. Muốn đổi gì thì sửa `openapi.yaml`.
- ❌ Thêm endpoint ở backend mà không cập nhật `openapi.yaml`.
- ❌ Tự khai báo lại interface DTO ở mobile/admin khi client sinh tự động đã có type đó.
- ❌ Đổi kiểu hoặc xoá field đã publish mà không đánh version — xem "Thay đổi phá vỡ" bên dưới.

## Quy ước viết openapi.yaml

**Đặt tên**
- `operationId` dạng `camelCase`, động từ + danh từ: `listPlaces`, `getPlaceById`,
  `createReview`, `searchNearbyPlaces`. Đây là tên hàm sinh ra ở client, nên phải rõ.
- Path dùng danh từ số nhiều, `kebab-case`: `/places`, `/places/{placeId}/reviews`,
  `/places/nearby`.
- Tên schema `PascalCase`: `PlaceSummary`, `PlaceDetail`, `CreateReviewRequest`,
  `PageOfPlaceSummary`.

**Cấu trúc**
- Mọi endpoint phải có `tags` (trùng tên module backend: `auth`, `place`, `review`, …),
  `summary` tiếng Việt ngắn gọn, và mô tả cho từng parameter.
- Danh sách luôn phân trang. Dùng schema chung `Page` với `content`, `page`, `size`,
  `totalElements`, `totalPages`. Không trả mảng trần.
- Lỗi luôn dùng schema chung `ApiError`: `{ code, message, details? , traceId }`.
  `code` là chuỗi `SCREAMING_SNAKE_CASE` ổn định (client so sánh bằng code, không bằng message).
- Field bắt buộc phải nằm trong `required`. Field có thể null phải khai `nullable: true`.
  Bỏ sót hai thứ này là nguyên nhân số một khiến TS client sai kiểu.
- Enum khai đầy đủ giá trị, viết `SCREAMING_SNAKE_CASE`, khớp đúng enum Java.

**Kiểu dữ liệu**
- Thời gian: `type: string, format: date-time`, luôn UTC ISO-8601.
- Toạ độ: `latitude` / `longitude` là `number, format: double`, có `minimum`/`maximum`.
- Tiền: số nguyên VND, không dùng float.
- ID: `string, format: uuid`.

## Sau khi sửa spec

```bash
./scripts/gen-api-client.sh          # Windows: .\scripts\gen-api-client.ps1
cd mobile && npx tsc --noEmit
cd ../admin && npx tsc --noEmit
```

TypeScript báo lỗi ở chỗ nào là chỗ đó đang dùng API cũ — sửa hết trước khi commit.
Đây là tính năng, không phải phiền toái: nó chỉ đúng chỗ client bị ảnh hưởng.

## Kiểm tra backend có khớp spec không

Backend chạy springdoc, sinh spec từ code tại `/v3/api-docs`. So sánh với file nguồn:

```bash
curl -s http://localhost:8080/v3/api-docs > /tmp/actual.json
# đối chiếu với docs/03-api/openapi.yaml
```

Lệch nhau nghĩa là code và hợp đồng đã trôi khỏi nhau. Sửa bên nào tuỳ tình huống,
nhưng phải sửa. Subagent `api-contract-guard` làm việc này.

## Thay đổi phá vỡ (breaking change)

Coi là phá vỡ nếu: xoá field, đổi kiểu field, thêm field bắt buộc vào request,
xoá giá trị enum, đổi mã lỗi, đổi path.

Mobile không cập nhật tức thì được (user phải tải bản mới), nên với API đã lên production:
- Thêm field mới thay vì đổi field cũ; đánh dấu field cũ `deprecated: true`.
- Giữ field cũ ít nhất **2 phiên bản app** rồi mới gỡ.
- Bắt buộc phải phá vỡ → tạo path mới `/v2/...`, giữ `/v1/...` song song.

Ghi lại mọi thay đổi phá vỡ vào `docs/03-api/CHANGELOG.md`.
