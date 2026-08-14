---
description: Đồng bộ toàn bộ submodule về đúng commit repo cha đang trỏ, rồi cài lại dependency
allowed-tools: Bash(git submodule:*), Bash(git status:*), Bash(npm install:*), Bash(./gradlew:*)
---

Đồng bộ workspace FoodMap:

1. Chạy `git submodule update --init --recursive` để kéo đủ 4 submodule
   (`docs`, `backend`, `mobile`, `admin`) về đúng commit repo cha đang trỏ.
2. Chạy `git submodule status` và báo lại trạng thái từng submodule.
   Dòng có tiền tố `+` nghĩa là submodule đang ở commit khác con trỏ repo cha —
   nêu rõ cái nào, và hỏi người dùng muốn giữ hay reset.
3. Cài dependency cho phần nào có thay đổi trong file khoá:
   - `mobile/package-lock.json` đổi → `cd mobile && npm install`
   - `admin/package-lock.json` đổi → `cd admin && npm install`
   - `backend/build.gradle.kts` đổi → `cd backend && ./gradlew build --refresh-dependencies`
4. Báo tóm tắt: submodule nào đã cập nhật, dependency nào đã cài lại.

Không tự động commit hay push bất cứ thứ gì.
