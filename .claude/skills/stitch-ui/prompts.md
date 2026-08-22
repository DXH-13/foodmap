# Prompt Stitch — FoodMap

Gửi phần **Ràng buộc chung** + **một** khối màn hình. Device: iPhone 14 (390×844) trừ khi ghi Desktop.

## Ràng buộc chung

```
Design a high-fidelity UI for FoodMap, a Vietnam street-food map app (quán ăn, hàng ăn, chợ đồ ăn, quán cà phê).
Language on screen: Vietnamese. Clean, warm, food-stall aesthetic (terracotta, steam, night-market light). Not generic purple SaaS.
Typography: readable Vietnamese (full diacritics). Bottom tab bar: Bản đồ, Khám phá, Yêu thích, Tôi.
Guest can use the map without signing in. Sign-in only when writing a review, favoriting, or opening chatbot.
Do not include: report-review, visit/check-in, notification-type settings, table booking.
Show status chips: Đang mở / Tạm đóng. Ratings are 1–5 integers; if no reviews show "Chưa có đánh giá" not 0 stars.
```

## Mobile — làm lần lượt

### 1. Bản đồ (MAP-01…06, DISCOVERY-01) — làm trước

```
Mobile screen: Map tab (default home). Full-screen map of Ho Chi Minh City at night-market warmth.
User location blue dot + recenter button. Clustered markers: restaurant / street cart / food market / cafe, distinct shapes.
Bottom sheet (peek): list of nearby places, each row: thumbnail, Vietnamese name, category chip, distance in m, star + count or "Chưa có đánh giá", open-now pill.
Top: search field "Tìm phở, bún, khu vực…", filter chips (Loại, Danh mục, Đang mở, Giá).
Safe-area tab bar. No login wall.
```

### 2. Chi tiết địa điểm (PLACE-01…03)

```
Mobile screen: Place detail for "Phở Lệ — Quận 3". Photo gallery on top. Title, place type STREET_FOOD, categories Phở / Bún.
averageRating 4.6 (128), visit not shown. Address, phone, today hours + "Đang mở". Favorite heart (outline).
Primary CTA: Viết đánh giá. Secondary: Chỉ đường (external maps).
Review list: avatar, name, stars, Vietnamese text, 2 photos. One review labeled "Đang chờ duyệt" as author's own.
```

### 3. Đăng nhập (AUTH-02)

```
Mobile screen: Login. FoodMap wordmark, email + password, primary "Đăng nhập", links "Quên mật khẩu" and "Tạo tài khoản".
Optional Google button visually secondary (may be disabled/hidden later). No dark overlay blocking the rest of the app conceptually — this is a dedicated auth screen.
```

### 4. Khám phá (DISCOVERY-02…06)

```
Mobile screen: Explore tab. Search. Horizontal category chips (Phở, Bún, Bánh mì, Hải sản, Chè…).
Sections: Gần đây (horizontal recent cards), Thịnh hành, Phổ biến, Gợi ý cho bạn.
Each card: image, name, rating, distance. Empty recent: "Chưa xem quán nào".
```

### 5. Viết đánh giá (REVIEW-02…06)

```
Mobile screen: Write review. 5-star tap, optional text area 2000 chars, add up to 5 photos + 1 video with upload progress per file.
Submit "Gửi đánh giá". Helper: "Đánh giá sẽ được duyệt trước khi hiện công khai."
```

### 6. Chatbot (AI-01…05)

```
Mobile screen: Chat. Streamed assistant bubble + place cards (image, name, rating) tappable.
Composer at bottom. Suggestion chips: "Quanh đây quán bún bò ngon", "Mở cửa đêm".
```

### 7. Yêu thích / Thông báo / Cá nhân / Quên mật khẩu

Generate after 1–6, same visual language. Favorites: closed places labeled "Đã đóng cửa". Notifications: unread dot, tap opens place. Profile: language vi|en, logout.

## Admin — Desktop 1440

### A. Dashboard (ADMIN-01)

```
Desktop admin for FoodMap. Light, dense, shadcn-like. Sidebar: Tổng quan, Địa điểm, Danh mục, Duyệt đánh giá, Người dùng.
KPI cards: places by status, reviews PENDING, new users today. Simple bar: users last 7 days. Vietnamese UI.
```

### B. Hàng chờ review (ADMIN-04)

```
Desktop: moderation queue table. Columns: thumbnail, place name, author, rating, excerpt, prior rejections, actions Duyệt / Từ chối / Ẩn.
Reject opens required reason field. Server-side pagination footer.
```

### C. Form địa điểm (ADMIN-03)

```
Desktop: edit place. Map picker with draggable pin (no raw lat/lng as primary). Tabs or columns for Vietnamese name (required) and English (optional).
Opening hours: per weekday, multiple ranges, closed toggle. Categories multi-select. priceLevel 1–4 optional. Status select.
```
