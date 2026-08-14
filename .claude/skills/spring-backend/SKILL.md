---
name: spring-backend
description: Quy ước code backend FoodMap (Java 21, Spring Boot 3) - dùng khi viết controller, service, repository, DTO, exception, hoặc test trong thư mục backend/. Đọc trước khi tạo class mới.
---

# Quy ước backend — Java 21 + Spring Boot 3

## Cấu trúc: package-by-feature

Nhóm theo **tính năng**, không theo tầng kỹ thuật. Không có package `controllers/`,
`services/`, `repositories/` ở cấp cao nhất.

```
com.foodmap
├─ config/          SecurityConfig, OpenApiConfig, JacksonConfig, CorsConfig, RedisConfig
├─ common/          ApiResponse, ApiError, GlobalExceptionHandler, BaseEntity, PageMapper
├─ place/
│   ├─ PlaceController.java
│   ├─ PlaceService.java
│   ├─ PlaceRepository.java
│   ├─ Place.java              (entity)
│   ├─ PlaceMapper.java        (MapStruct)
│   └─ dto/  PlaceSummaryDto, PlaceDetailDto, CreatePlaceRequest, NearbyQuery
├─ review/  user/  auth/  favorite/  visit/  feedback/  media/  notification/  chat/  admin/
```

Class chỉ dùng nội bộ một feature thì để `package-private`, không `public`. Cần dùng
chéo feature thì đi qua service `public`, không truy cập repository của feature khác.

## Tầng và trách nhiệm

| Tầng | Được làm | Không được làm |
|---|---|---|
| Controller | Nhận HTTP, validate cú pháp (`@Valid`), gọi service, trả DTO | Chứa logic nghiệp vụ, gọi repository trực tiếp |
| Service | Logic nghiệp vụ, `@Transactional`, phối hợp repository | Biết về `HttpServletRequest`, `ResponseEntity` |
| Repository | Truy vấn dữ liệu | Chứa logic nghiệp vụ |

**Controller không bao giờ trả entity.** Luôn map sang DTO. Trả entity làm lộ cấu trúc DB,
gây lazy-loading exception, và khiến hợp đồng API trôi theo schema.

## DTO và mapping

- Dùng `record` cho DTO (Java 21). Bất biến, ngắn gọn.
- Request DTO tên `...Request`, response DTO tên `...Dto` hoặc `...Response`.
- Map bằng **MapStruct**, không viết tay, không dùng `BeanUtils.copyProperties`.

```java
public record CreateReviewRequest(
    @NotNull @Min(1) @Max(5) Integer rating,
    @Size(max = 2000) String content,
    List<UUID> mediaIds
) {}
```

Validation ở DTO là validation **cú pháp** (bắt buộc, độ dài, khoảng giá trị).
Validation **nghiệp vụ** (user đã review place này chưa, place có tồn tại không)
nằm ở service.

## Response và lỗi

Mọi lỗi đi qua `GlobalExceptionHandler`, trả đúng schema `ApiError` trong `openapi.yaml`:

```json
{ "code": "PLACE_NOT_FOUND", "message": "Không tìm thấy địa điểm", "traceId": "..." }
```

- `code` là hằng `SCREAMING_SNAKE_CASE`, **không dịch** — client so sánh bằng code.
- `message` **được dịch** theo `Accept-Language` qua `MessageSource`.
- Không bao giờ để stack trace lọt ra response.

Exception nghiệp vụ kế thừa `BusinessException`, mang sẵn `code` và HTTP status:

```java
throw new NotFoundException("PLACE_NOT_FOUND", "place.error.not_found");
```

## Entity

```java
@Entity
@Table(name = "places")
public class Place extends BaseEntity {   // BaseEntity: id, createdAt, updatedAt, deletedAt
    @Column(nullable = false)
    private String slug;

    @Column(columnDefinition = "geography(Point,4326)", nullable = false)
    private Point location;               // org.locationtech.jts.geom.Point
    ...
}
```

- Quan hệ mặc định `FetchType.LAZY`. `EAGER` gây N+1 âm thầm.
- Cần nạp kèm thì dùng `@EntityGraph` hoặc `JOIN FETCH` ở query cụ thể.
- **Không** dùng `spring.jpa.hibernate.ddl-auto` khác `validate`. Schema do Flyway quản lý.

## Transaction

- `@Transactional` đặt ở **service**, không ở controller, không ở repository.
- Chỉ đọc thì `@Transactional(readOnly = true)`.
- Gọi API bên ngoài (Claude, S3, Expo Push) **không** đặt trong transaction đang mở —
  giữ kết nối DB suốt thời gian chờ mạng. Tách ra hoặc dùng sự kiện sau commit
  (`@TransactionalEventListener(phase = AFTER_COMMIT)`).

## Bảo mật

- JWT: access token 15 phút, refresh token 30 ngày lưu trong Redis (thu hồi được).
- Mật khẩu băm bằng BCrypt, cost 12.
- Phân quyền bằng `@PreAuthorize("hasRole('MODERATOR')")` ở service, không ở controller —
  để mọi đường vào đều được bảo vệ.
- Endpoint công khai khai báo tường minh trong `SecurityConfig`; mặc định là **chặn**.
- Không log token, mật khẩu, hay toàn bộ request body của endpoint auth.

## Test

- Unit test service: JUnit 5 + Mockito, mock repository.
- Integration test: **Testcontainers** với image `postgis/postgis:16-3.4`, không dùng H2
  (H2 không có PostGIS, test địa lý sẽ vô nghĩa).
- Test controller: `@WebMvcTest` + `MockMvc`.
- Mỗi endpoint mới phải có ít nhất: 1 test happy path, 1 test lỗi validation,
  1 test phân quyền (user không đủ quyền → 403).

```java
@Testcontainers
@SpringBootTest
class PlaceServiceIT {
    @Container
    static PostgreSQLContainer<?> db = new PostgreSQLContainer<>("postgis/postgis:16-3.4");
    ...
}
```

## Cấu hình

- `application.yml` — chung; `application-local.yml`, `application-dev.yml`,
  `application-prod.yml` — theo môi trường.
- Bí mật **chỉ** qua biến môi trường: `${JWT_SECRET}`, `${ANTHROPIC_API_KEY}`.
  Không có giá trị mặc định cho secret trong file yml.
- Gom cấu hình theo nhóm bằng `@ConfigurationProperties`, không rải `@Value` khắp nơi.

## Chatbot (module `chat`)

- Dùng Anthropic Java SDK (`com.anthropic:anthropic-java`), model `claude-opus-5`.
- Bật adaptive thinking (`ThinkingConfigAdaptive`), effort `high`.
- Đăng ký tool để model gọi ngược vào service của mình: `search_places`,
  `get_place_detail`, `recommend_nearby`. Tool chạy phía server, không lộ ra client.
- Stream về mobile bằng SSE. `max_tokens` lớn thì bắt buộc streaming, tránh timeout HTTP.
- `ANTHROPIC_API_KEY` qua biến môi trường. Không đưa key vào prompt, không log prompt
  chứa dữ liệu cá nhân.
