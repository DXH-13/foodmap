---
name: stitch-ui
description: Quy trình Google Stitch MCP cho FoodMap — tạo/sửa màn hình trên Stitch rồi chuyển sang Expo hoặc Next.js. Dùng khi người dùng muốn sinh UI bằng Stitch, prompt Stitch, lấy HTML/ảnh thiết kế, hoặc implement màn hình theo Stitch.
---

# Stitch → code FoodMap

Stitch sinh **mock HTML/CSS** (web). FoodMap mobile là **React Native + Expo**. Không dán HTML Stitch vào `mobile/`. Đọc HTML + screenshot, rồi implement bằng component RN / shadcn theo skill `expo-mobile` (mobile) hoặc quy ước admin.

## Trước khi gọi MCP

1. Gọi `GetMcpTools` với server Stitch (tên thường là `stitch` hoặc `user-stitch`).
2. Nếu không có server / `needsAuth` / 0 tool:
   - Nhắc user: Settings → Tools & MCP, server `stitch` phải xanh.
   - Key: [Stitch settings](https://stitch.withgoogle.com) → API key. Gán `STITCH_API_KEY` (User env Windows) rồi **restart Cursor**.
   - Không bịa tool, không giả kết quả Stitch.
3. Đọc schema từng tool rồi mới `CallMcpTool`. Tên tool tùy phiên bản (thường có `list_projects`, tạo/sửa screen, `get_screen_code`, `get_screen_image`).

## Thứ tự bắt buộc

```
1. Đọc docs/SDD/giao-dien/man-hinh.md + thiet-ke-tinh-nang.md
   (đúng Function ID, đừng thêm Won't Have)
2. Lấy hoặc tạo project Stitch tên "FoodMap"
3. Generate / edit screen bằng prompt trong prompts.md (cùng thư mục skill)
   — một màn một lần, mobile 390×844; admin 1440 desktop
4. Lấy screenshot + HTML từ Stitch
5. Implement vào đúng route (expo-router hoặc App Router)
6. Chuỗi UI: i18n vi + en, không hardcode tiếng Việt trong JSX
```

## Prompt Stitch — ràng buộc luôn gửi kèm

- App: **FoodMap** — bản đồ quán ăn / hàng / chợ Việt Nam.
- Default locale **Vietnamese** trên UI; có chỗ đổi EN.
- Khách xem bản đồ không cần login.
- Không màn báo cáo review, không cấu hình loại thông báo, không check-in.
- Phong cách: ấm, ẩm thực đường phố, không SaaS tím generic. Marker phân biệt quán / hàng / chợ / café.
- Trạng thái: skeleton, rỗng có CTA, lỗi + Thử lại — Stitch nên có ít nhất bản happy path; ghi chú empty/error trong prompt nếu generate thêm variant.

## Sau khi có thiết kế

- Map HTML → RN: `View`/`Text`/`Pressable`, theme `mobile/src/constants/theme.ts`, NativeWind nếu file đã dùng.
- Bản đồ: `react-native-maps`, không nhúng Google Maps JS của Stitch.
- Admin: shadcn/ui, bảng phân trang server.
- Lưu `projectId` / `screenId` vào `docs/SDD/giao-dien/stitch-screens.md` khi user đồng ý ghi tài liệu.

## Cấm

- Commit API key.
- Generate cả 20 màn một lượt (quota Stitch, dễ lệch design system).
- Sửa `mobile/src/api/generated/`.
- Coi HTML Stitch là source of truth cho logic — source of truth nghiệp vụ vẫn là SDD/SRS.
