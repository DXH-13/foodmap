# FoodMap

Ứng dụng bản đồ quán ăn, hàng ăn và chợ đồ ăn ngon trên đất nước Việt Nam — chạy trên
cả iOS và Android.

Đây là **repo cha**. Toàn bộ mã nguồn và tài liệu nằm trong 4 submodule.

## Cấu trúc

| Thư mục | Repo | Nội dung |
|---|---|---|
| `docs/` | [foodmap-docs](https://github.com/DXH-13/foodmap-docs) | SRS, kiến trúc, ADR, `openapi.yaml` |
| `backend/` | [foodmap-backend](https://github.com/DXH-13/foodmap-backend) | Java 21 · Spring Boot 3 · PostgreSQL + PostGIS |
| `mobile/` | [foodmap-mobile](https://github.com/DXH-13/foodmap-mobile) | React Native · Expo · TypeScript |
| `admin/` | [foodmap-admin](https://github.com/DXH-13/foodmap-admin) | Next.js 15 · TypeScript |

## Kiến trúc

```
Mobile (Expo/RN)  ─┐
                   ├─→  Spring Boot API  ─→  PostgreSQL + PostGIS
Admin (Next.js)   ─┘         │                Redis
                             │                MinIO / S3
                             ├─→  Claude API      (chatbot)
                             ├─→  Expo Push       (thông báo)
                             └─→  Google Maps API (geocode, seed dữ liệu)
```

Hợp đồng API là `docs/03-api/openapi.yaml`. Backend implement theo nó; mobile và admin
**sinh** TypeScript client từ nó. Sửa API luôn bắt đầu từ file này.

## Bắt đầu

Cần có: **Git**, **Docker Desktop**, **JDK 21**, **Node 20+**.

```bash
git clone --recurse-submodules https://github.com/DXH-13/foodmap.git
cd foodmap

# macOS / Linux
./scripts/bootstrap.sh
./scripts/dev-up.sh

# Windows PowerShell
.\scripts\bootstrap.ps1
.\scripts\dev-up.ps1
```

Nếu đã lỡ clone không kèm submodule:

```bash
git submodule update --init --recursive
```

Sau đó chạy từng phần:

```bash
cd backend && ./gradlew bootRun     # http://localhost:8080
cd mobile  && npx expo start
cd admin   && npm run dev           # http://localhost:3000
```

## Script

| Script | Việc |
|---|---|
| `scripts/bootstrap` | Khởi tạo submodule, cài dependency, tạo `.env` từ `.env.example` |
| `scripts/dev-up` | Bật hạ tầng dev bằng Docker |
| `scripts/dev-down` | Tắt hạ tầng dev |
| `scripts/gen-api-client` | Sinh lại TypeScript client từ `openapi.yaml` |

## Dịch vụ dev

| Dịch vụ | Cổng | Ghi chú |
|---|---|---|
| PostgreSQL + PostGIS | 5433 | user/db/pass: `foodmap` |
| Redis | 6380 | |
| MinIO | 9002 / 9003 | Console ở 9003, `minioadmin` / `minioadmin` |
| Mailpit | 1025 / 8025 | Hộp thư giả, UI ở 8025 |

Cổng lệch chuẩn (5433 thay vì 5432, 6380 thay vì 6379…) là cố ý, để không đụng
Postgres/Redis/MinIO của dự án khác đang chạy trên cùng máy. Đổi được trong `infra/.env`.

## Đóng góp

Commit theo [Conventional Commits](https://www.conventionalcommits.org/).
Quy ước đầy đủ: [`AGENTS.md`](./AGENTS.md).
