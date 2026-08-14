---
description: Tạo một migration Flyway mới đúng quy ước, kèm cập nhật entity và tài liệu dữ liệu
argument-hint: <mô tả thay đổi schema, ví dụ "thêm bảng giờ mở cửa cho địa điểm">
---

Tạo migration mới cho FoodMap: **$ARGUMENTS**

Đọc skill `db-migration` và `foodmap-domain` trước.

### 1. Kiểm tra hiện trạng

- Liệt kê `backend/src/main/resources/db/migration/` để biết số version cao nhất.
- Đọc `docs/04-data/erd.md` để nắm lược đồ hiện tại.
- **Xác nhận không sửa migration cũ.** Nếu việc cần làm là "sửa" một thay đổi trước đó,
  thì viết migration mới để sửa, không đụng vào file đã có.

### 2. Viết migration

Tên file `V{số kế tiếp}__{mô_tả_snake_case}.sql`. Bảo đảm:
- `TIMESTAMPTZ` cho mọi cột thời gian
- Enum bằng `VARCHAR` + `CHECK` constraint có tên tường minh
- Khoá ngoại khai rõ `ON DELETE`
- Toạ độ dùng `geography(Point, 4326)` + index GiST
- Có index cho khoá ngoại và cột lọc thường dùng
- Ràng buộc nghiệp vụ ép được ở DB thì ép (unique, check)

Có backfill dữ liệu thì tách thành migration riêng, không gộp vào migration đổi cấu trúc.

### 3. Cập nhật entity JPA

Sửa entity tương ứng trong `backend/src/main/java/com/foodmap/<module>/`.
Quan hệ để `FetchType.LAZY`. Giữ `ddl-auto: validate` — schema do Flyway quản lý.

### 4. Kiểm tra

```bash
cd backend
./gradlew flywayClean flywayMigrate    # chạy lại từ DB rỗng
./gradlew test                          # Testcontainers dựng DB sạch
```

Phải chạy sạch **từ database rỗng**, không chỉ trên DB dev hiện tại của bạn.

### 5. Cập nhật tài liệu

Sửa `docs/04-data/erd.md` và `docs/04-data/data-dictionary.md` cho khớp.

### 6. Nếu schema mới lộ ra API

Thì phải cập nhật `docs/03-api/openapi.yaml` và sinh lại client — xem `/new-endpoint`.
