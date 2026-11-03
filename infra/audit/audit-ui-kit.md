# Báo Cáo Audit UI Kit

> **Phạm vi kiểm tra:** 4 trang Figma — UI kits · Typography · Color palette · Buttons & Inputs  
> **Ngày audit:** 2026-08-30  
> **Trạng thái tổng thể:** 🟡 Nền tảng có, nhưng còn nhiều khoảng trống cần bổ sung trước khi bàn giao cho dev

---

## 1. Typography

### ✅ Đã có
| Nhóm | Chi tiết |
|---|---|
| Font family | Work Sans — 3 weight: **Semibold**, **Medium**, **Regular** |
| Headlines | H1–H6 × 3 weight (96 / 60 / 48 / 34 / 24 / 20px) |
| Subtitle | S1 (16px), S2 (14px) × Medium + Regular |
| Body | B1 Medium 16px · B2 Regular 14px · Caption 12px · Overline 10px |
| Button | Giant 20px · Large 16px · Medium 14px · Small 12px — mỗi size có 2 case (ALL CAPS & Title) |

### ❌ Còn thiếu / Cần bổ sung
- **Line-height & Letter-spacing** chưa được ghi rõ trên spec — dev không thể implement chính xác nếu thiếu giá trị này.
- **Link style** (màu, underline, hover/visited state) chưa có Text Style riêng.
- **Dark mode text tokens** chưa xuất hiện — tất cả text styles đang dùng màu cứng `#1E2A59`, chưa liên kết Color Variable.
- **Truncation / Ellipsis rule** chưa được định nghĩa (single-line vs multi-line).
- **Numeric / Monospace style** cần cho màn hình giá crypto (BTC price, balance) — hiện không có.

---

## 2. Color Palette

### ✅ Đã có
| Nhóm | Màu |
|---|---|
| Default tones | Dark `#000000` · Info `#0095FF` · Success `#00D68F` · Warning `#FFAA00` · Error `#FF3D71` · Greyscale `#2E3A59` · White `#FFFFFF` |
| Brand colors | Dark · Grey `#EFEFEF` · Magenta `#FD9FDD` · Orange `#FC7339` · Greeny `#BEFF6C` · Violet `#AF96FB` · Blue `#49DBC8` · Yellow `#FFF172` |
| Shade scales | Info · Success · Warning · Error · Greyscale — mỗi màu có ~8 bậc sáng/tối |

### ❌ Còn thiếu / Cần bổ sung
- **Semantic / Alias tokens chưa có:** Palette liệt kê màu thô nhưng chưa có lớp alias như `background-primary`, `surface-card`, `text-on-dark`, `border-default`… Đây là lớp bắt buộc để component tự đổi theo Light/Dark mode.
- **Dark mode palette hoàn toàn vắng mặt** — chưa có bộ màu nền, surface, border riêng cho dark theme.
- **Brand color shades chưa có scale** — Magenta, Orange, Greeny, Violet, Blue, Yellow chỉ có 1 tone duy nhất, không có 50→900 như Info/Success/Warning/Error.
- **Opacity tokens** (màu với alpha: `#0095FF/10%` dùng cho badge background) chưa được định nghĩa.
- **Gradient tokens** nếu UI có dùng gradient (ví dụ card crypto) cần được liệt kê riêng.
- **Contrast ratio chưa được kiểm tra** — cần đảm bảo ít nhất WCAG AA (4.5:1 cho text nhỏ).

---

## 3. Buttons & Inputs

### ✅ Đã có
| Thành phần | Chi tiết |
|---|---|
| Button variants | 3 kiểu: **Filled** (solid) · **Outlined** · **Ghost/Text** |
| Button colors | 8 màu nền: Black · Grey (disabled) · Blue · Green · Yellow · Pink/Error · Dark Navy · Dark nền trắng |
| Icon support | Icon trái + Icon phải (star icon placeholder) |
| Dark background set | Row cuối cùng hiển thị button trên nền dark navy |

### ❌ Còn thiếu / Cần bổ sung
- **Kích thước (Size variants) chưa thấy:** Spec Typography định nghĩa Giant/Large/Medium/Small nhưng trang Buttons chỉ có **một size duy nhất** — thiếu 3 size còn lại.
- **States chưa đủ:** Chỉ thấy Default. Cần: `Hover` · `Pressed/Active` · `Disabled` · `Loading` (spinner) — hiện **Grey button** có vẻ dùng như disabled nhưng không được label rõ.
- **Icon-only button** chưa có (dùng nhiều trong toolbar, FAB).
- **Full-width / Block button** chưa được spec.
- **Input fields thiếu hoàn toàn dưới dạng spec riêng:** Trang "Buttons & Inputs" trong file chỉ có Button types — phần Input thực tế nằm trong UI kits (xem mục 4) nhưng không được tổ chức thành component spec.
- **Form elements khác:** Checkbox · Radio button · Dropdown/Select · Date picker chưa xuất hiện.

---

## 4. UI Kits (Components)

### ✅ Đã có
| Component | Ghi chú |
|---|---|
| Bottom Navigation Bar | 6 trạng thái active (Home/Crypto/Card/Cashback/More) + icon active states |
| App Header / Headline Bar | Dạng Back+Title+Action và Back+Title+Menu |
| Status Bar (iOS) | 9:41 placeholder, signal/battery |
| Tab Bar | 2 kiểu: Default + Icon+Label; 2 theme: Light + Dark |
| Radio / Checkbox | 2 trạng thái (on/off), có nhãn "Today" |
| Toggle Switch | On/Off, 2 màu (green/grey) |
| Category Row | Label + "View all" link |
| List Item - Transaction | Icon + Name + Amount (có % change màu xanh/đỏ) |
| List Item - Contact | Avatar + Name |
| Stepper / Counter | Nút +/− và số đếm |
| Badge / Chip | Ví dụ: "12.7% BTC" |
| Text Input | 3 state: Default · With caption · Error (viền đỏ) |
| List Item - Navigation | Icon + Label + Chevron (2 kiểu: với/không icon) |
| Accordion / FAQ | Expand/Collapse (+/−) |
| List Item - Settings | Icon + Title + Description + Chevron |
| Payment Method Card | Logo ngân hàng + masked card number |

### ❌ Còn thiếu / Cần bổ sung

#### Thiếu components thiết yếu
- **Modal / Bottom Sheet** — chưa có, dùng rất nhiều cho xác nhận giao dịch, filter, OTP.
- **Toast / Snackbar** — thông báo tạm thời (success/error/info).
- **Alert / Banner** — thông báo cố định trên trang.
- **Empty State** — màn hình trống (no transaction, no result…).
- **Skeleton / Loading placeholder** — trạng thái loading của card, list.
- **Progress Bar / Step Indicator** — cần thiết cho luồng onboarding, KYC, send money.
- **Avatar** — chỉ thấy trong list, chưa thành component độc lập với size variants.
- **Tooltip** — chưa có.
- **Dropdown / Select** — chưa có component spec.
- **Search Bar** — chưa có (dù icon search đã có trong icon library).
- **Date Picker / Calendar** — cần cho lọc giao dịch theo ngày.
- **OTP / PIN Input** — quan trọng với app tài chính/crypto.
- **Crypto Asset Card** — card hiển thị balance, % change, sparkline.
- **QR Code display** — cần cho receive/send crypto.

#### Thiếu về tổ chức component
- **Interactive states** của tất cả component chưa được định nghĩa (hover, focus, disabled, error).
- **Responsive / Adaptive behavior** chưa được spec (component thay đổi như thế nào trên tablet/màn lớn hơn).
- **Dark mode variant** của component chưa có — chỉ có Bottom Nav và Tab Bar có preview dark.

---

## 5. Tổng Kết & Mức Độ Ưu Tiên

| Hạng mục | Trạng thái | Ưu tiên |
|---|---|---|
| Typography scale | ✅ Có, cần bổ sung line-height & tokens | 🔴 Cao |
| Color - Raw palette | ✅ Đầy đủ | — |
| Color - Semantic tokens | ❌ Chưa có | 🔴 Cao |
| Color - Dark mode | ❌ Chưa có | 🔴 Cao |
| Button sizes | ❌ Thiếu 3/4 sizes | 🔴 Cao |
| Button states | ❌ Thiếu hover/pressed/loading | 🔴 Cao |
| Input / Form components | 🟡 Có cơ bản, chưa spec riêng | 🔴 Cao |
| Navigation components | ✅ Bottom nav, header, tab | — |
| Modal / Sheet / Toast | ❌ Chưa có | 🔴 Cao |
| Empty state / Skeleton | ❌ Chưa có | 🟡 Trung bình |
| Crypto-specific components | ❌ Chưa có (Asset card, QR, OTP) | 🔴 Cao |
| Icon system | ✅ 1900 SVG (linear + bold) | — |
| Accessibility (contrast) | ❌ Chưa kiểm tra | 🟡 Trung bình |
| Dark mode full coverage | ❌ Chưa có | 🟡 Trung bình |

---

## 6. Đề Xuất Bước Tiếp Theo

1. **Thiết lập Semantic Color Tokens** trong Figma Local Variables trước khi làm thêm component bất kỳ.
2. **Bổ sung đủ 4 size + 5 state cho Button** — đây là component dùng nhiều nhất.
3. **Tách Input thành component spec độc lập** với đủ type: Text, Password, Search, OTP.
4. **Xây Modal + Bottom Sheet + Toast** — 3 component block luồng UX nhiều nhất.
5. **Bổ sung line-height, letter-spacing** vào tất cả Text Styles hiện có.
6. **Kiểm tra contrast ratio** toàn bộ màu text-on-background bằng Figma plugin Contrast hoặc Stark.
