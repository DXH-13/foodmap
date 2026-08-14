---
description: Bật hạ tầng dev (Postgres+PostGIS, Redis, MinIO, Mailpit) và kiểm tra sức khoẻ
allowed-tools: Bash(docker compose:*), Bash(docker ps:*), Bash(docker exec:*), Bash(curl:*)
---

Bật môi trường dev FoodMap:

1. Kiểm tra `infra/.env` đã tồn tại chưa. Chưa có thì copy từ `infra/.env.example`
   và **báo cho người dùng biết cần điền các giá trị thật**
   (`GOOGLE_MAPS_API_KEY`, `ANTHROPIC_API_KEY`, `JWT_SECRET`).
2. Chạy `docker compose -f infra/docker-compose.yml up -d`.
3. Đợi và kiểm tra healthcheck bằng `docker compose -f infra/docker-compose.yml ps`.
   Chờ tới khi cả 4 service ở trạng thái `healthy` (tối đa ~60 giây).
4. Xác nhận PostGIS đã bật:
   `docker exec foodmap-db psql -U foodmap -d foodmap -c "SELECT PostGIS_Version();"`
5. Báo bảng tóm tắt: tên service, trạng thái, cổng, và đường dẫn UI
   (MinIO Console http://localhost:9001 · Mailpit http://localhost:8025).

Service nào không lên được thì lấy log của riêng nó
(`docker compose -f infra/docker-compose.yml logs <service> --tail 50`)
và chẩn đoán, đừng chỉ báo "thất bại".
