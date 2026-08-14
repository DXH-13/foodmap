---
description: Cập nhật hoặc rà soát tài liệu SRS và tài liệu dự án trong docs/
argument-hint: <việc cần làm, ví dụ "bổ sung yêu cầu chia sẻ địa điểm qua link">
---

Cập nhật tài liệu dự án FoodMap: **$ARGUMENTS**

Dùng subagent `srs-writer`, hoặc tự làm theo hướng dẫn của nó.

### Việc cần làm

1. Đọc skill `foodmap-domain` để dùng đúng thuật ngữ
   (`place` chứ không phải "nhà hàng"; phân biệt `review` và `feedback`).
2. Đọc tài liệu hiện có liên quan trong `docs/` trước khi viết thêm —
   tránh viết trùng hoặc mâu thuẫn với phần đã có.
3. Cập nhật đúng file:
   - Yêu cầu chức năng / phi chức năng → `docs/01-srs/srs.md`
   - Use case → `docs/01-srs/use-cases.md`
   - Tiêu chí nghiệm thu → `docs/01-srs/acceptance-criteria.md`
   - Quyết định kiến trúc → `docs/02-architecture/adr/ADR-XXXX-<tên>.md` (**file mới**,
     không sửa ADR cũ)
   - Kế hoạch / backlog → `docs/07-plan/`
4. Yêu cầu mới phải: có mã (`FR-<module>-<số>` hoặc `NFR-<số>`), **kiểm chứng được**,
   và nói rõ ảnh hưởng tới phần nào (backend / mobile / admin / DB).
5. Nếu yêu cầu mới kéo theo thay đổi API hoặc schema, **nêu rõ điều đó** ở cuối —
   nhưng đừng tự sửa `openapi.yaml` hay viết migration trong lệnh này.

### Nếu là rà soát

Đọc tài liệu và đối chiếu với code hiện tại. Báo cáo từng điểm lệch, nêu rõ nên sửa
tài liệu hay sửa code, và tại sao. Đừng âm thầm sửa tài liệu cho khớp code khi code
mới là chỗ sai.
