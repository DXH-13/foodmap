---
description: Sinh hoặc lấy giao diện FoodMap qua Google Stitch MCP, rồi implement đúng stack (Expo / Next.js)
argument-hint: <màn hình, ví dụ "tab bản đồ" hoặc "chi tiết địa điểm">
---

Dùng Stitch MCP để làm UI FoodMap cho: **$ARGUMENTS**

Đọc skill `stitch-ui` (kể cả `prompts.md`) và `expo-mobile` nếu là mobile.

1. Kiểm tra MCP Stitch đã nối (`GetMcpTools`). Chưa nối thì dừng và hướng dẫn lấy API key + `STITCH_API_KEY`.
2. Bám `docs/SDD/giao-dien/man-hinh.md` — đúng Function ID, không thêm Won't Have.
3. Prompt Stitch bằng khối tương ứng trong `prompts.md` (ràng buộc chung + một màn).
4. Lấy screenshot + HTML; **không** paste HTML vào React Native.
5. Implement route đúng, i18n vi và en.
6. Báo `projectId` / `screenId` và link Stitch nếu tool trả về.
