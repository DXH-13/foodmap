---
name: expo-mobile
description: Quy ước code mobile FoodMap (React Native + Expo + TypeScript) - dùng khi viết màn hình, component, hook, gọi API, xử lý bản đồ, quyền vị trí, upload media hoặc push notification trong thư mục mobile/. Đọc trước khi tạo file mới trong app/ hoặc src/.
---

# Quy ước mobile — Expo + React Native + TypeScript

## Cấu trúc

Route nằm ở **`src/app`**, không phải `app/` ở gốc — template Expo SDK 57 dùng layout này.

```
src/app/                    expo-router: file = route
  _layout.tsx               provider gốc: QueryClient, i18n, khôi phục phiên
  (tabs)/                   nhóm route có tab bar
    _layout.tsx
    index.tsx               Bản đồ — màn hình mặc định
    explore.tsx  favorites.tsx  profile.tsx
  (auth)/login.tsx          nhóm route chưa đăng nhập
  place/[id].tsx            chi tiết địa điểm
  chat/index.tsx            chatbot

src/
  api/generated/            ⚠️ SINH TỰ ĐỘNG — KHÔNG SỬA TAY
  api/client.ts             openapi-fetch + middleware gắn token, Accept-Language
  api/queryKeys.ts          khai tập trung mọi query key
  components/               component dùng chung, không gắn với feature
  features/<tên>/           component + hook riêng của một feature
  hooks/                    hook dùng chung
  i18n/                     cấu hình i18next + locales/vi.json, en.json
  store/                    zustand
  constants/                màu, typography, spacing
  types/                    khai báo kiểu bổ sung (ví dụ *.css)
```

Cấu hình Expo ở **`app.config.ts`** (không phải `app.json`) để đọc được biến môi trường.

**`src/api/generated/` bị ghi đè mỗi lần chạy `scripts/gen-api-client`.** Muốn đổi kiểu
dữ liệu API thì sửa `docs/SDD/api/openapi.yaml` — xem skill `api-contract`.

## Điều hướng (expo-router)

- Route dựa trên file. Đặt tên file `kebab-case`, tham số động `[id].tsx`.
- Dùng `<Link href="/place/123">` và `router.push()`. Không tự dựng navigator thủ công.
- Nhóm `(auth)` / `(tabs)` không xuất hiện trong URL, chỉ để tổ chức layout.
- Chặn route cần đăng nhập ở `app/(tabs)/_layout.tsx` bằng redirect, không kiểm tra
  rải rác trong từng màn hình.

## Gọi API — TanStack Query

Mọi lần gọi mạng đi qua TanStack Query. Không `useEffect` + `fetch` thủ công.

**Query key có cấu trúc, khai tập trung** ở `src/api/queryKeys.ts`:

```ts
export const qk = {
  places: {
    all: ['places'] as const,
    nearby: (lat: number, lng: number, radius: number) =>
      ['places', 'nearby', lat, lng, radius] as const,
    detail: (id: string) => ['places', 'detail', id] as const,
  },
  reviews: {
    byPlace: (placeId: string) => ['reviews', 'place', placeId] as const,
  },
} as const;
```

Key rời rạc khiến `invalidateQueries` sót chỗ, dữ liệu cũ đọng lại trên màn hình.

Sau mutation, invalidate đúng nhánh:

```ts
onSuccess: () => {
  queryClient.invalidateQueries({ queryKey: qk.reviews.byPlace(placeId) });
  queryClient.invalidateQueries({ queryKey: qk.places.detail(placeId) });
}
```

## Bản đồ

- `react-native-maps` với `provider={PROVIDER_GOOGLE}` trên **cả hai** nền tảng, để
  giao diện và hành vi đồng nhất.
- API key khai trong `app.json` → `ios.config.googleMapsApiKey` và
  `android.config.googleMaps.apiKey`, đọc từ biến môi trường, không hardcode.
- Nhiều marker thì bật clustering; render vài trăm marker rời sẽ giật.
- Chỉ gọi API tìm quanh đây khi bản đồ **ngừng** di chuyển (`onRegionChangeComplete`)
  và có debounce ~500ms. Gọi theo từng frame di chuyển sẽ spam server.
- Bán kính suy ra từ `region.latitudeDelta`, giới hạn trong 2–50 km (xem skill `foodmap-domain`).

## Quyền (permission)

Xin quyền **đúng lúc cần**, kèm giải thích, không xin hàng loạt lúc mở app.

```ts
const { status } = await Location.requestForegroundPermissionsAsync();
if (status !== 'granted') {
  // Hiển thị trạng thái rỗng có ý nghĩa + nút mở Cài đặt.
  // KHÔNG để màn hình trắng, KHÔNG crash.
}
```

Quyền cần: vị trí (bản đồ, ghi visit), thư viện ảnh + camera (đính kèm review),
thông báo (push). Mỗi quyền phải có đường thoát khi bị từ chối.

## Media

- Chọn ảnh/video bằng `expo-image-picker`; nén trước khi upload
  (ảnh ≤ 1600px cạnh dài, video ≤ 60 giây).
- Upload qua presigned URL do backend cấp, **không** gửi thẳng file qua API backend.
- Hiển thị ảnh bằng `expo-image` (có cache sẵn), video bằng `expo-video`.
- Luôn có placeholder và trạng thái lỗi — mạng di động ở Việt Nam không ổn định.

## State

- **TanStack Query** giữ state của server (dữ liệu từ API). Không copy sang zustand.
- **zustand** giữ state client: phiên đăng nhập, bộ lọc bản đồ, ngôn ngữ đang chọn.
- Token lưu bằng `expo-secure-store`, **không** dùng `AsyncStorage`.

## Đa ngôn ngữ

Không hardcode chuỗi tiếng Việt trong JSX.

```tsx
const { t } = useTranslation();
<Text>{t('place.nearby.title')}</Text>
```

Thêm key phải có cả `vi.json` và `en.json` — xem skill `i18n-workflow`.

## Component

- Function component + hook. Không class component.
- Một file một component export mặc định; component phụ nhỏ có thể ở cùng file.
- Props khai bằng `type`, không `interface` (nhất quán trong repo này).
- Tên file `PascalCase.tsx` cho component, `camelCase.ts` cho hook và tiện ích.
- Style bằng **NativeWind** (className). Chỉ dùng `StyleSheet` khi NativeWind không diễn đạt được.
- Danh sách dài dùng `FlashList`, không `ScrollView` chứa `.map()`.

## Form

`react-hook-form` + `zod`. Schema zod là nguồn sự thật cho validation phía client:

```ts
const schema = z.object({
  rating: z.number().int().min(1).max(5),
  content: z.string().max(2000).optional(),
});
```

Validation client là để UX, **không** thay thế validation server. Backend luôn kiểm tra lại.

## Thông báo đẩy

- `expo-notifications`; đăng ký token và gửi lên backend sau khi đăng nhập.
- Gỡ token khi đăng xuất — nếu không, thiết bị vẫn nhận thông báo của tài khoản cũ.
- Xử lý cả hai trường hợp: app đang mở (foreground) và bấm vào thông báo khi app đóng.

## Kiểm tra trước khi commit

```bash
cd mobile
npx tsc --noEmit
npm run lint
npx expo start          # bundle thành công, mở được trên thiết bị
```
