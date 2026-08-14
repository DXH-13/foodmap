---
name: i18n-workflow
description: Quy trình đa ngôn ngữ vi/en cho FoodMap - dùng khi thêm hoặc sửa bất kỳ chuỗi hiển thị nào, thông báo lỗi, nội dung email, hoặc nội dung động do admin nhập. Đọc trước khi hardcode một chuỗi tiếng Việt vào code.
---

# Đa ngôn ngữ (vi / en)

FoodMap hỗ trợ **tiếng Việt** (mặc định) và **tiếng Anh**. Có hai loại nội dung, xử lý khác nhau.

## Loại 1 — Chuỗi giao diện (static)

Nhãn nút, tiêu đề màn hình, thông báo lỗi, email. Nằm trong file dịch của từng phần.

**Thêm một chuỗi mới = sửa đủ 3 nơi liên quan, mỗi nơi 2 ngôn ngữ.**
Bỏ sót một nơi là lỗi chỉ lộ ra khi người dùng đổi ngôn ngữ — rất khó phát hiện.

| Phần | File | Định dạng |
|---|---|---|
| Backend | `backend/src/main/resources/messages_vi.properties`<br>`backend/src/main/resources/messages_en.properties` | `key=giá trị` |
| Mobile | `mobile/src/i18n/locales/vi.json`<br>`mobile/src/i18n/locales/en.json` | JSON lồng nhau |
| Admin | `admin/messages/vi.json`<br>`admin/messages/en.json` | JSON lồng nhau |

### Quy ước đặt key

`namespace.subject.action` hoặc `namespace.subject.state`, `snake_case`, luôn tiếng Anh:

```
place.nearby.title
place.detail.opening_hours
review.form.submit_button
review.error.rating_required
auth.login.forgot_password_link
common.action.cancel
common.state.loading
```

- Bắt đầu bằng namespace = module (`place`, `review`, `auth`, `chat`, `admin`, `common`).
- Chuỗi dùng chung ở nhiều màn hình → `common.*`.
- **Không** đặt key theo nội dung tiếng Việt (`nut_huy` là sai), cũng không theo vị trí
  màn hình (`screen1.button2` là sai).

### Backend

```properties
# messages_vi.properties
review.error.rating_required=Vui lòng chọn số sao đánh giá
place.error.not_found=Không tìm thấy địa điểm

# messages_en.properties
review.error.rating_required=Please select a rating
place.error.not_found=Place not found
```

Ngôn ngữ lấy từ header `Accept-Language` của request, mặc định `vi`.
`ApiError.message` đã được dịch sẵn; `ApiError.code` thì **không dịch** — nó là mã ổn định
để client so sánh.

### Mobile / Admin

```json
{
  "review": {
    "error": { "rating_required": "Vui lòng chọn số sao đánh giá" },
    "form": { "submit_button": "Gửi đánh giá" }
  }
}
```

Mobile dùng `i18next` + `expo-localization`; Admin dùng `next-intl`. Cả hai đều
fallback về `vi` khi thiếu key ở `en`.

## Loại 2 — Nội dung động (do người dùng / admin nhập)

Tên địa điểm, mô tả, tên danh mục — lưu trong DB, không nằm trong file dịch.

Bảng dịch riêng, khoá `(entity_id, locale)`:

```sql
CREATE TABLE place_translations (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    place_id    UUID NOT NULL REFERENCES places(id) ON DELETE CASCADE,
    locale      VARCHAR(5) NOT NULL CONSTRAINT place_translations_locale_check
                CHECK (locale IN ('vi','en')),
    name        VARCHAR(255) NOT NULL,
    description TEXT,
    CONSTRAINT uq_place_translations UNIQUE (place_id, locale)
);
```

**Quy tắc fallback:** thiếu bản dịch `en` → trả bản `vi`. Không trả chuỗi rỗng,
không trả `null`, không trả key. Người dùng chọn tiếng Anh mà quán chưa có tên tiếng Anh
thì thấy tên tiếng Việt — chấp nhận được; thấy ô trống thì không.

Bản `vi` là **bắt buộc** khi tạo place. Bản `en` là tuỳ chọn.

**Review không dịch.** Giữ nguyên ngôn ngữ tác giả viết, có cột `locale` để đánh dấu
và hiển thị nhãn "Viết bằng tiếng Việt" khi cần.

## Checklist khi thêm chuỗi mới

- [ ] Có key trong cả `vi` và `en` ở đúng phần (backend / mobile / admin)
- [ ] Key theo đúng quy ước `namespace.subject.action`
- [ ] Không hardcode chuỗi tiếng Việt trực tiếp trong JSX / Java
- [ ] Chuỗi có biến dùng interpolation, không nối chuỗi:
      `"Còn {{count}} đánh giá"` chứ không phải `"Còn " + count + " đánh giá"`
      (thứ tự từ khác nhau giữa hai ngôn ngữ)
- [ ] Nếu là nội dung động: có bản `vi`, và fallback hoạt động khi thiếu `en`

## Bẫy thường gặp

- **Số nhiều.** Tiếng Việt không chia số nhiều, tiếng Anh có. Dùng cơ chế plural của
  i18next / next-intl thay vì tự viết `if (count > 1)`.
- **Định dạng ngày giờ và số.** Đừng tự format. Dùng `Intl.DateTimeFormat` /
  `Intl.NumberFormat` với locale hiện tại. Tiền hiển thị `50.000 ₫` ở `vi`, `50,000 ₫` ở `en`.
- **Múi giờ.** Backend lưu UTC; client hiển thị theo `Asia/Ho_Chi_Minh`. Đừng đổi múi giờ
  ở backend rồi lại đổi lần nữa ở client.
- **Độ dài chuỗi.** Tiếng Anh thường dài hơn tiếng Việt 20–30%. Nút và nhãn phải co giãn được,
  đừng đặt chiều rộng cố định theo chuỗi tiếng Việt.
