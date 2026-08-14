---
name: db-migration
description: Quy ước migration Flyway và PostGIS cho FoodMap - dùng khi thêm/sửa bảng, cột, index, hoặc khi làm việc với cột toạ độ và truy vấn "quanh đây". Đọc trước khi tạo file SQL mới trong backend/src/main/resources/db/migration.
---

# Migration Flyway + PostGIS

Vị trí: `backend/src/main/resources/db/migration/`

## Quy tắc bất di bất dịch

**Không bao giờ sửa một file migration đã được merge vào `main`.**
Flyway lưu checksum; sửa file cũ làm mọi môi trường đã chạy nó hỏng ngay lần khởi động
tiếp theo (`FlywayValidateException`). Sai thì viết migration mới để sửa lại.

Ngoại lệ duy nhất: migration chưa rời khỏi máy bạn và chưa push.

## Đặt tên

```
V{số}__{mô_tả_snake_case}.sql
```

```
V1__init_schema.sql
V2__add_place_opening_hours.sql
V3__add_review_moderation_status.sql
V4__index_place_location_gist.sql
```

- Hai dấu gạch dưới giữa số và mô tả. Một dấu là sai, Flyway không nhận.
- Số tăng dần, không nhảy cóc, không trùng. Trước khi tạo file, kiểm tra số cao nhất hiện có.
- Mô tả bằng tiếng Anh, `snake_case`, nói rõ *làm gì*: `add_...`, `drop_...`, `index_...`, `backfill_...`.
- Migration lặp lại được (view, function) dùng tiền tố `R__`, ví dụ `R__place_search_view.sql`.

## Quy ước schema

- Tên bảng: số nhiều, `snake_case` — `places`, `reviews`, `place_translations`.
- Khoá chính: `id UUID PRIMARY KEY DEFAULT gen_random_uuid()` (cần extension `pgcrypto`).
- Mọi bảng nghiệp vụ có: `created_at TIMESTAMPTZ NOT NULL DEFAULT now()`,
  `updated_at TIMESTAMPTZ NOT NULL DEFAULT now()`.
- Thời gian luôn `TIMESTAMPTZ`, **không dùng** `TIMESTAMP` trần. Lưu UTC.
- Xoá mềm dùng `deleted_at TIMESTAMPTZ NULL`, không dùng cờ boolean.
- Enum lưu bằng `VARCHAR` + `CHECK` constraint, **không** dùng kiểu ENUM của Postgres
  (thêm giá trị vào ENUM Postgres cần `ALTER TYPE`, phiền khi rollback).

```sql
status VARCHAR(32) NOT NULL DEFAULT 'PENDING'
    CONSTRAINT reviews_status_check
    CHECK (status IN ('PENDING','APPROVED','REJECTED','HIDDEN'))
```

- Đặt tên constraint tường minh (`reviews_status_check`), đừng để Postgres tự sinh —
  tên tự sinh khiến migration sau khó `DROP CONSTRAINT`.
- Khoá ngoại luôn khai `ON DELETE` rõ ràng: `CASCADE` cho dữ liệu phụ thuộc
  (review → media), `RESTRICT` cho tham chiếu quan trọng (review → place).

## PostGIS

Bật extension trong migration đầu tiên:

```sql
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
```

**Toạ độ lưu bằng một cột `geography`, không phải hai cột lat/lng:**

```sql
location geography(Point, 4326) NOT NULL
```

`geography` (không phải `geometry`) vì nó tính khoảng cách bằng mét trên mặt cầu —
đúng cho "quanh đây" mà không phải chọn hệ chiếu.

**Bắt buộc có index GiST**, nếu không truy vấn quanh đây sẽ quét toàn bảng:

```sql
CREATE INDEX idx_places_location ON places USING GIST (location);
```

**Truy vấn quanh đây** — dùng `ST_DWithin`, đơn vị mét:

```sql
SELECT p.*, ST_Distance(p.location, :origin) AS distance_meters
FROM places p
WHERE p.status = 'PUBLISHED'
  AND p.deleted_at IS NULL
  AND ST_DWithin(p.location, :origin, :radius_meters)
ORDER BY p.location <-> :origin
LIMIT :limit;
```

- `ST_DWithin` dùng được index; `ST_Distance(...) < x` trong `WHERE` thì **không** —
  đừng viết kiểu đó.
- `<->` là toán tử KNN, sắp xếp theo khoảng cách và cũng dùng index.
- Tạo điểm từ lat/lng: `ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography`.
  **Thứ tự là (lng, lat)** — đảo ngược so với cách người ta hay đọc. Nhầm thứ tự này là
  lỗi phổ biến nhất khi làm PostGIS; kết quả sẽ ra giữa đại dương.

Phía Java: dùng Hibernate Spatial, kiểu `org.locationtech.jts.geom.Point`.
Nhớ cấu hình `hibernate.dialect` là `PostgisPGDialect`.

## Index cần có

Đặt index cho: cột khoá ngoại, cột dùng lọc thường xuyên (`status`, `deleted_at`),
cột sắp xếp (`created_at`), và index tổ hợp cho truy vấn hay dùng.

```sql
CREATE INDEX idx_reviews_place_status ON reviews (place_id, status) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX uq_favorites_user_place ON favorites (user_id, place_id);
CREATE UNIQUE INDEX uq_visits_user_place_day ON visits (user_id, place_id, visit_date);
```

Index bộ phận (`WHERE deleted_at IS NULL`) nhỏ hơn và nhanh hơn khi hầu hết truy vấn
đều lọc bản ghi chưa xoá.

## Migration có backfill dữ liệu

Tách làm hai bước, không gộp:

```sql
-- V5__add_place_visit_count.sql
ALTER TABLE places ADD COLUMN visit_count BIGINT NOT NULL DEFAULT 0;

-- V6__backfill_place_visit_count.sql
UPDATE places p SET visit_count = (SELECT count(*) FROM visits v WHERE v.place_id = p.id);
```

Bảng lớn thì backfill theo lô, đừng `UPDATE` một phát toàn bảng (khoá bảng quá lâu).

## Kiểm tra trước khi commit

```bash
cd backend
./gradlew flywayClean flywayMigrate    # chạy lại từ đầu trên DB dev
./gradlew test                          # Testcontainers dựng DB sạch và chạy migration
```

Migration phải chạy sạch **từ đầu trên database rỗng**, không chỉ trên DB hiện có của bạn.
