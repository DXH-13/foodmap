# FoodMap — Hướng dẫn cho AI agent

Tài liệu này là nguồn ngữ cảnh chính cho mọi AI agent làm việc trong workspace FoodMap.
`CLAUDE.md` chỉ import file này. Các repo con có `CLAUDE.md` riêng, hẹp hơn và cụ thể hơn.

---

## 1. Dự án là gì

**FoodMap** — ứng dụng mobile (iOS + Android) bản đồ quán ăn, hàng ăn và chợ đồ ăn ngon
trên đất nước Việt Nam. Người dùng tìm quán quanh mình trên bản đồ, đọc/viết review kèm
ảnh và video, gửi feedback về quán, lưu quán yêu thích và theo dõi lịch sử đã đến.

**Tính năng v1 (9 nhóm):**

| # | Nhóm | Mô tả ngắn |
|---|------|-----------|
| 1 | Bản đồ | Hiển thị địa điểm, tìm quanh đây, lọc theo danh mục, cập nhật dữ liệu vị trí |
| 2 | Review | Đánh giá 1–5 sao, nội dung, đính kèm ảnh/video |
| 3 | Feedback | User báo sai thông tin quán (địa chỉ, giờ mở cửa, đã đóng cửa) |
| 4 | Đa ngôn ngữ | Tiếng Việt + tiếng Anh, cả UI lẫn nội dung động |
| 5 | Chatbot AI | Gợi ý quán ăn bằng hội thoại tự nhiên |
| 6 | Trang admin | CRUD địa điểm, duyệt review/feedback, quản lý user, thống kê |
| 7 | Xác thực | Đăng ký, đăng nhập, refresh token, quên/đặt lại mật khẩu |
| 8 | Yêu thích & đã đến | Danh sách yêu thích, lịch sử đã đến, đếm số lượt đến |
| 9 | Thông báo | In-app + push (Expo Push) |

Chi tiết đầy đủ: `docs/01-srs/srs.md`.

---

## 2. Bản đồ workspace

Repo cha `foodmap` chứa 4 submodule. **Mỗi submodule là một git repo độc lập** —
commit và push riêng, rồi mới cập nhật con trỏ ở repo cha.

```
foodmap/                    ← repo cha: config, script, hạ tầng dev
├─ docs/      → foodmap-docs      Tài liệu: SRS, kiến trúc, ADR, openapi.yaml
├─ backend/   → foodmap-backend   Java 21 + Spring Boot 3 + PostgreSQL/PostGIS
├─ mobile/    → foodmap-mobile    React Native + Expo + TypeScript
├─ admin/     → foodmap-admin     Next.js 15 + TypeScript
├─ infra/                         docker-compose cho môi trường dev
├─ scripts/                       bootstrap, dev-up, gen-api-client (.sh + .ps1)
└─ .claude/                       skills, subagents, slash commands
```

Khi được giao một việc, **xác định nó thuộc repo con nào trước khi sửa file**.
Việc chạm nhiều repo (ví dụ thêm một endpoint) phải theo đúng thứ tự ở mục 4.

---

## 3. Tech stack và lý do chọn

| Thành phần | Công nghệ | Lý do |
|---|---|---|
| Mobile | React Native + Expo, TypeScript | Một codebase cho iOS + Android; hệ sinh thái map/media/social mạnh nhất; EAS Build |
| Backend | Java 21 + Spring Boot 3, Gradle Kotlin DSL | Đội đã quen Java; hệ sinh thái ổn định; Hibernate Spatial cho truy vấn địa lý |
| CSDL | PostgreSQL 16 + PostGIS | Truy vấn "quanh đây" bằng chỉ mục không gian GiST, chính xác và nhanh |
| Cache | Redis 7 | Cache kết quả tìm kiếm, rate limit, blacklist refresh token |
| Lưu trữ media | MinIO (dev) / S3 (prod) | API tương thích, đổi môi trường không đổi code |
| Admin | Next.js 15 App Router + shadcn/ui | Cùng ngôn ngữ TypeScript với mobile, dùng chung TS client sinh từ OpenAPI |
| Bản đồ | Google Maps | Dữ liệu POI quán ăn Việt Nam đầy đủ nhất; Places API để seed dữ liệu ban đầu |
| Chatbot | Claude API (`claude-opus-5`) qua Anthropic Java SDK | Tool use + streaming, gọi thẳng vào service tìm kiếm địa điểm của backend |
| Migration | Flyway | Migration tuần tự, versioned, chạy tự động khi khởi động |

ADR ghi lại quyết định: `docs/02-architecture/adr/`.

---

## 4. Quy tắc quan trọng nhất: contract-first

`docs/03-api/openapi.yaml` là **nguồn sự thật duy nhất** cho hợp đồng API.
Java và TypeScript không share type trực tiếp được, nên OpenAPI là cầu nối.

Khi thêm hoặc sửa một endpoint, **luôn theo đúng thứ tự này**:

```
1. Sửa docs/03-api/openapi.yaml          ← trước tiên, luôn luôn
2. Chạy scripts/gen-api-client           ← sinh lại TS client cho mobile + admin
3. Implement controller/service ở backend
4. Dùng client đã sinh ở mobile / admin
5. Viết test ở backend
```

**Nghiêm cấm:**
- Sửa tay file trong `mobile/src/api/generated/` hoặc `admin/src/api/generated/` — sẽ bị ghi đè.
- Thêm endpoint ở backend mà không cập nhật `openapi.yaml`.
- Định nghĩa lại DTO bằng tay ở mobile/admin trong khi client sinh tự động đã có.

Skill `api-contract` mô tả chi tiết quy trình này.

---

## 5. Quy ước chung

### Ngôn ngữ
- **Giao tiếp với người dùng, tài liệu, commit message, comment giải thích nghiệp vụ: tiếng Việt.**
- **Định danh trong code (tên biến, hàm, class, bảng, cột, key i18n): tiếng Anh.**
- Không trộn tiếng Việt vào tên định danh.

### Commit — Conventional Commits
```
feat(place): them api tim quan quanh day
fix(auth): sua loi refresh token het han sai mui gio
docs(srs): bo sung use case gui feedback
chore(deps): nang expo len sdk 54
```
Loại dùng: `feat` `fix` `docs` `refactor` `test` `chore` `perf` `ci`.
Scope = tên module (`auth`, `place`, `review`, `chat`, `admin`, `infra`, …).

### Branch
```
main          nhánh chính, luôn build được
feat/<mo-ta>  tính năng mới
fix/<mo-ta>   sửa lỗi
```
Không push thẳng lên `main` ở các repo con khi làm tính năng — mở PR.

### Bí mật
- Không bao giờ commit API key, mật khẩu, token, file `.env`.
- Mọi biến môi trường mới phải được thêm vào `infra/.env.example` với giá trị giả.
- Key cần có: `GOOGLE_MAPS_API_KEY`, `ANTHROPIC_API_KEY`, `JWT_SECRET`, `S3_*`.

---

## 6. Chạy môi trường dev

```bash
# Lần đầu (hoặc sau khi clone mới)
./scripts/bootstrap.sh          # Windows: .\scripts\bootstrap.ps1

# Bật hạ tầng (Postgres+PostGIS, Redis, MinIO, Mailpit)
./scripts/dev-up.sh

# Backend
cd backend && ./gradlew bootRun          # http://localhost:8080

# Mobile
cd mobile && npx expo start

# Admin
cd admin && npm run dev                  # http://localhost:3000

# Sinh lại TS client sau khi sửa openapi.yaml
./scripts/gen-api-client.sh
```

Cổng dịch vụ dev: Postgres `5433` · Redis `6380` · MinIO API `9002` / Console `9003` ·
Mailpit SMTP `1025` / UI `8025` · Backend `8080` · Admin `3000`.

Cổng lệch chuẩn là **cố ý** — máy dev thường đã có Postgres/Redis/MinIO của dự án khác
chiếm cổng mặc định. Tất cả đều là biến trong `infra/.env`, đổi được.

---

## 7. Làm việc với submodule

```bash
# Cập nhật tất cả submodule về đúng commit repo cha đang trỏ
git submodule update --init --recursive

# Làm việc trong một submodule
cd backend
git checkout -b feat/them-api-review
# ... sửa code, commit, push ...

# Sau đó cập nhật con trỏ ở repo cha
cd ..
git add backend
git commit -m "chore(submodule): cap nhat backend len ban moi nhat"
```

**Bẫy thường gặp:** commit ở repo con nhưng quên cập nhật con trỏ ở repo cha —
người khác clone về sẽ thấy code cũ. Luôn kiểm tra `git status` ở repo cha sau khi
làm việc trong submodule. CI của repo cha có bước chặn việc này, và workflow
`bump-submodules.yml` kéo con trỏ lên bản mới nhất mỗi tuần.

**Submodule là private.** CI của repo cha cần secret `SUBMODULE_TOKEN` (Personal Access
Token có quyền đọc 4 repo con) mới checkout được chúng. Chưa đặt secret thì các job
cần submodule sẽ thất bại.

---

## 7b. Bẫy môi trường đã gặp thật

Ghi lại để không mất thời gian lần thứ hai.

| Triệu chứng | Nguyên nhân | Cách xử lý |
|---|---|---|
| Script `.ps1` báo lỗi cú pháp, ký tự tiếng Việt thành `Ã¡Â»` | Windows PowerShell 5.1 đọc `.ps1` theo bảng mã ANSI khi file không có BOM | Lưu file `.ps1` bằng **UTF-8 kèm BOM**. Bốn script trong `scripts/` đã có BOM — giữ nguyên khi sửa |
| `npx @next/codemod` làm hỏng ký tự tiếng Việt trong file nó sửa | Cùng nguyên nhân: công cụ đọc/ghi không đúng bảng mã | Sau khi chạy codemod, kiểm tra lại file bị sửa và viết lại phần comment nếu cần |
| Cổng 5432/6379/9000 đã bị chiếm | Dự án khác trên máy đang chạy Postgres/Redis/MinIO | FoodMap cố ý dùng 5433/6380/9002 — đổi được trong `infra/.env` |
| `Cannot find module 'eslint'` khi chạy `expo lint` lần đầu | `expo lint` tự thêm eslint vào `package.json` nhưng chưa cài | Chạy `npm install` rồi lint lại |

---

## 8. Trước khi báo hoàn thành

- [ ] Code build được (`./gradlew build` / `tsc --noEmit`)
- [ ] Nếu đổi API: `openapi.yaml` đã cập nhật và TS client đã sinh lại
- [ ] Nếu đổi schema DB: có file migration Flyway mới, không sửa migration cũ
- [ ] Nếu thêm chuỗi hiển thị: đã có cả `vi` và `en`
- [ ] Không có secret nào bị commit
- [ ] Test liên quan chạy pass — nếu fail thì nói rõ, không giấu
