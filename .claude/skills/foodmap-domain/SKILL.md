---
name: foodmap-domain
description: Nghiệp vụ và thuật ngữ FoodMap - dùng khi làm việc với địa điểm (place), review, rating, feedback, lượt đến (visit), yêu thích, kiểm duyệt, hoặc khi cần biết một quy tắc nghiệp vụ. Đọc trước khi thiết kế bảng, viết validation, hay đặt tên field.
---

# Nghiệp vụ FoodMap

## Từ điển thuật ngữ (Việt ↔ Anh)

Định danh trong code luôn dùng cột **Code**. Đừng tự đặt tên khác.

| Tiếng Việt | Code | Ghi chú |
|---|---|---|
| Địa điểm | `place` | Danh từ chung cho quán ăn, hàng ăn, chợ |
| Quán ăn | `place_type = RESTAURANT` | Có mặt bằng cố định, bàn ghế |
| Hàng ăn / xe đẩy | `place_type = STREET_FOOD` | Vỉa hè, xe đẩy, gánh hàng rong |
| Chợ đồ ăn | `place_type = FOOD_MARKET` | Khu chợ, food court |
| Quán cà phê | `place_type = CAFE` | |
| Danh mục món | `category` | Phở, bún, bánh mì, hải sản… — nhiều-nhiều với place |
| Đánh giá | `review` | Gồm `rating` (1–5) + `content` + media |
| Điểm trung bình | `average_rating` | Cột dẫn xuất, lưu sẵn trên `place` |
| Góp ý / báo sai | `feedback` | Người dùng báo thông tin quán sai, khác với review |
| Lượt đến | `visit` | Một lần check-in của user tại place |
| Yêu thích | `favorite` | Bookmark, không có trạng thái trung gian |
| Kiểm duyệt viên | role `MODERATOR` | Duyệt review và feedback |
| Quản trị viên | role `ADMIN` | Toàn quyền, gồm cả quản lý user |

**Đừng nhầm `review` với `feedback`.** Review là cảm nhận của người dùng về món ăn,
hiển thị công khai, có sao. Feedback là báo cáo dữ liệu sai (địa chỉ lệch, quán đã đóng
cửa, giờ mở cửa không đúng), không công khai, chỉ moderator/admin thấy.

---

## Quy tắc nghiệp vụ

### Rating và điểm trung bình

- `rating` là số nguyên 1–5. Không có nửa sao.
- Mỗi user chỉ được có **một** review đang hoạt động cho mỗi place.
  Viết lại = cập nhật review cũ, không tạo bản ghi mới.
- `place.average_rating` và `place.review_count` là cột dẫn xuất, tính lại mỗi khi
  review được **duyệt**, **sửa** hoặc **gỡ**. Review đang chờ duyệt hoặc bị từ chối
  **không** tính vào điểm trung bình.
- Place chưa có review nào: `average_rating = NULL`, không phải `0`. Hiển thị
  "Chưa có đánh giá", không hiển thị 0 sao.

### Kiểm duyệt review

Vòng đời: `PENDING` → `APPROVED` hoặc `REJECTED`, và bất kỳ lúc nào có thể → `HIDDEN`.

- Review mới luôn vào `PENDING`. Chỉ `APPROVED` mới hiển thị công khai.
- Tác giả luôn nhìn thấy review của chính mình bất kể trạng thái, kèm nhãn trạng thái.
- Chuyển sang `REJECTED` **bắt buộc** kèm `moderation_note` (lý do), gửi thông báo cho tác giả.
- `HIDDEN` là ẩn tạm bởi moderator/admin, khác `REJECTED` ở chỗ có thể hiện lại.
- Media đính kèm review bị từ chối vẫn giữ trên storage 30 ngày rồi mới xoá.

### Đếm lượt đến (visit) — chống spam

Đếm lượt đến dễ bị lạm dụng, nên các ràng buộc sau là bắt buộc:

- Một user chỉ được ghi nhận **tối đa 1 visit / place / ngày** (theo giờ Việt Nam, `Asia/Ho_Chi_Minh`).
- Ghi nhận visit yêu cầu toạ độ người dùng nằm trong bán kính **200m** quanh place.
- `place.visit_count` là **tổng số lượt** (không phải số user khác nhau).
  Nếu cần số user khác nhau thì dùng `distinct_visitor_count`, tính riêng.
- Visit không thể xoá bởi user — chỉ admin xoá được, dùng khi xử lý gian lận.

### Feedback

- Loại: `WRONG_ADDRESS` `WRONG_HOURS` `CLOSED_PERMANENTLY` `DUPLICATE` `INAPPROPRIATE` `OTHER`.
- Trạng thái: `OPEN` → `IN_REVIEW` → `RESOLVED` hoặc `DISMISSED`.
- Cùng một user + cùng một place + cùng một loại đang `OPEN` → không tạo bản ghi mới,
  trả 409 kèm id bản ghi đang mở.
- `CLOSED_PERMANENTLY` được 3 user khác nhau báo trong 30 ngày → tự động gắn cờ
  `place.needs_review = true` và tạo thông báo cho moderator.

### Địa điểm

- Toạ độ lưu bằng PostGIS `geography(Point, 4326)`, **không** lưu hai cột lat/lng rời.
- Trong JSON API thì phơi ra `latitude` / `longitude` dạng số cho dễ dùng ở client.
- Bán kính tìm kiếm mặc định **2 km**, tối đa cho phép **50 km**.
  Vượt quá thì trả 400, không âm thầm cắt bớt.
- `status`: `DRAFT` `PUBLISHED` `TEMPORARILY_CLOSED` `PERMANENTLY_CLOSED`.
  API công khai chỉ trả `PUBLISHED` và `TEMPORARILY_CLOSED`.
- Giờ mở cửa lưu theo từng ngày trong tuần, cho phép nhiều khoảng trong ngày
  (quán bán sáng và tối, nghỉ trưa).

### Yêu thích

- Bookmark thuần: có hoặc không, không có trạng thái trung gian.
- Bấm yêu thích một place đã yêu thích → idempotent, trả 200, không trả lỗi.
- Yêu thích một place đã `PERMANENTLY_CLOSED` vẫn giữ trong danh sách nhưng gắn nhãn.

### Đa ngôn ngữ nội dung động

- Chuỗi giao diện nằm ở file i18n của từng client — xem skill `i18n-workflow`.
- Nội dung do người dùng/admin nhập (tên place, mô tả, tên danh mục) lưu ở bảng dịch
  riêng: `place_translation`, `category_translation`, khoá `(entity_id, locale)`.
- `locale` chỉ nhận `vi` và `en`. Mặc định `vi`.
- Thiếu bản dịch `en` → **fallback về `vi`**, không trả chuỗi rỗng, không trả null.
- Review do user viết **không dịch**, giữ nguyên ngôn ngữ gốc, có cột `locale` để đánh dấu.

### Thông báo

Loại: `REVIEW_APPROVED` `REVIEW_REJECTED` `FEEDBACK_RESOLVED` `NEW_PLACE_NEARBY`
`PLACE_UPDATED` `SYSTEM_ANNOUNCEMENT`.

- Mỗi thông báo lưu bản ghi in-app; push chỉ là kênh gửi thêm, không thay thế.
- Người dùng tắt push vẫn phải thấy thông báo trong app.
- Không gửi push trong khoảng 22:00–07:00 giờ Việt Nam trừ loại `SYSTEM_ANNOUNCEMENT`.

---

## Phân quyền

| Hành động | GUEST | USER | MODERATOR | ADMIN |
|---|:---:|:---:|:---:|:---:|
| Xem place, review công khai | ✅ | ✅ | ✅ | ✅ |
| Viết review, gửi feedback, yêu thích, ghi visit | ❌ | ✅ | ✅ | ✅ |
| Duyệt / từ chối / ẩn review | ❌ | ❌ | ✅ | ✅ |
| Xử lý feedback | ❌ | ❌ | ✅ | ✅ |
| CRUD place, category | ❌ | ❌ | ✅ | ✅ |
| Quản lý user, gán role | ❌ | ❌ | ❌ | ✅ |
| Xem thống kê hệ thống | ❌ | ❌ | ✅ | ✅ |
