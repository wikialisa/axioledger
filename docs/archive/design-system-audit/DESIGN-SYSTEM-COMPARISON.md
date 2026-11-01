# 📊 So sánh 3 tài nguyên Design System

> **Mục đích:** Đánh giá 3 nguồn thiết kế đang tồn tại đồng thời trong dự án để quyết định giữ lại 1 nguồn duy nhất, tránh xung đột dependency và token.  
> **Ngày kiểm tra:** 2025  
> **Người lập:** Bob (AI Engineering)

---

## 1. Tổng quan 3 tài nguyên

| Tiêu chí | **A** `axioledger-monorepo/design-system` | **B** `axioledger-monorepo/packages/axio-design-system` | **C** `/root/design-system` |
|---|---|---|---|
| **Package name** | `@axioledger/axio-design-system` | `@axioledger/axio-design-system` | `@veraciphers/axio-design-system` |
| **Version** | `2.0.0` | `5.0.0` | `4.0.0` |
| **NPM registry** | GitHub Packages (axioledger org) | GitHub Packages (axioledger org) | GitHub Packages (veraciphers org) |
| **License** | MIT | MIT | — |
| **Loại build** | Vite (ES + CJS, pre-built) | Source-only (no build step) | Vite (ES + CJS, pre-built) |
| **Storybook** | ✅ v8.0.0 | ❌ Không có | ✅ v8.2.4 |
| **Testing** | ✅ Jest 29 + coverage thresholds | ❌ Chỉ `typecheck` | ❌ Không có |
| **TypeScript** | Strict, ES2020 | Strict, ES2020, `preserve` JSX | Strict, ES2020 |
| **Peer deps** | React ≥ 18 | React ≥ 18 | React ≥ 18 |
| **Runtime deps** | **Zero** | **Zero** | **Zero** |

---

## 2. Quy mô Component

| Tiêu chí | **A** `monorepo/design-system` | **B** `packages/axio-design-system` | **C** `/root/design-system` |
|---|---|---|---|
| **Số lượng component** | 24 | 7 | 14 React + 18 CSS files |
| **Hệ thống Icon** | ❌ Không có | ❌ Không có | ✅ **1,897 icons** (linear + bold), SVG sprite |
| **Core UI** | Button, Input, Card, Badge, Toggle, Avatar, Checkbox, Dropdown, OTPInput, SearchBar | Button, Input | Button, Input, Badge, Alert, Toast, Skeleton, Progress, Avatar, BottomSheet, Tooltip, EmptyState |
| **Overlay** | Modal, BottomSheet, Tooltip, Navbar | — | BottomSheet, Tooltip |
| **Feedback** | Toast, Alert, SecurityAlert, EmptyState, Skeleton, ProgressBar, StepIndicator | Toast, SecurityAlert | Toast, Skeleton, Progress, EmptyState |
| **Crypto-specific** | NamespaceBadge, AddressDisplay, PasskeyButton, CryptoAssetCard, QRCodeDisplay, TransactionItem, BalanceDisplay, PriceTicker | NamespaceBadge, AddressDisplay, PasskeyButton | SwapCard, WalletHome |
| **Composite** | — | — | SwapCard, WalletHome |

---

## 3. Kiến trúc Token (3 lớp)

| Tiêu chí | **A** `monorepo/design-system` | **B** `packages/axio-design-system` | **C** `/root/design-system` |
|---|---|---|---|
| **Cấu trúc** | Primitive → Semantic → Component | Primitive → Semantic → Component | Primitive → Semantic → Component |
| **Prefix token** | `--axq-*` | `--axq-*` | `--color-*` / `--axq-p-*` (legacy compat) |
| **Layer 1 file** | `tokens/color-tokens.json` | `tokens/primitive.css` | `tokens/color-tokens.json` |
| **Layer 2 file** | `tokens/variables.css` (auto-generated) | `tokens/semantic.css` | `tokens/variables.css` |
| **Layer 3 file** | `tokens/variables.css` (merged) | `tokens/component.css` | `tokens/variables.css` (merged) |
| **Dark mode** | ✅ `[data-theme="dark"]` | ✅ `[data-theme="dark"]` + `prefers-color-scheme` | ✅ `[data-theme="dark"]` |
| **Tailwind export** | ❌ Không có | ❌ Không có | ✅ `tokens/tailwind-tokens.js` |
| **Typography** | Work Sans, 10 scale | Work Sans, 10 scale | Work Sans, 10 scale |
| **Spacing scale** | 0–128px (18 bước) | 0–128px (20 bước) | 0–128px (18 bước) |
| **DTCG format** | ✅ JSON W3C-compatible | ✅ JSON W3C-compatible | ✅ JSON W3C-compatible |

---

## 4. TLP (Traffic Light Protocol) — Bảo mật namespace

| Tiêu chí | **A** `monorepo/design-system` | **B** `packages/axio-design-system` | **C** `/root/design-system` |
|---|---|---|---|
| **Hỗ trợ TLP** | ✅ NamespaceBadge, SecurityAlert | ✅ NamespaceBadge, SecurityAlert, tokens.ts | ❌ Không có |
| **TLP levels** | SAFE / CAUTION / BLOCKED / SYSTEM | SAFE / CAUTION / BLOCKED / SYSTEM | — |
| **ANS resolver** | ✅ `useANSResolver` hook | ✅ AddressDisplay (client-side cache) | ❌ Không có |
| **PasskeyButton** | ✅ WebAuthn abstraction | ✅ P-256 + DER parsing | ❌ Không có |

---

## 5. Build & Phân phối

| Tiêu chí | **A** `monorepo/design-system` | **B** `packages/axio-design-system` | **C** `/root/design-system` |
|---|---|---|---|
| **Build tool** | Vite 5.4.0 + vite-plugin-dts | Không có (source-only) | Vite 5.3.4 + vite-plugin-dts |
| **Output formats** | ESM + CJS | ESM (via bundler) | ESM + CJS |
| **Tree-shakeable** | ✅ Named exports | ✅ Named exports | ✅ Named exports |
| **CSS output** | Single merged `styles.css` | Per-layer CSS + entry barrel | Per-layer CSS |
| **Bundle budget** | JS ≤ 50KB gz, CSS ≤ 25KB gz | Không enforce | Không enforce |
| **SVG sprite** | ❌ | ❌ | ✅ 1,897 icons auto-generated |
| **Granular exports** | 4 export paths | **8 export paths** (per layer) | 4 export paths |
| **Prepublish hook** | ✅ `build` | ❌ Chỉ `typecheck` | ✅ `build` |

---

## 6. Tài liệu & DevX

| Tiêu chí | **A** `monorepo/design-system` | **B** `packages/axio-design-system` | **C** `/root/design-system` |
|---|---|---|---|
| **README** | ✅ Tiếng Việt, đầy đủ | ❌ Chưa có | ✅ Tiếng Anh |
| **Storybook** | ✅ Port 6006, a11y + themes | ❌ Không có | ✅ Port 6006, a11y + interactions |
| **Guidelines** | ✅ accessibility, dark-mode, icon-catalog | ❌ Không có | ✅ accessibility, dark-mode, icon-usage |
| **Changelog** | ✅ CHANGELOG.md | ❌ Không có | ❌ Không có |
| **Component spec docs** | ✅ 5 file markdown | ❌ Không có | ✅ 5 file markdown |
| **Deployment plan** | ✅ DEPLOYMENT-PLAN.md | ❌ Không có | ❌ Không có |

---

## 7. Rủi ro xung đột nếu dùng nhiều hơn 1

| Rủi ro | Chi tiết |
|---|---|
| **Package name trùng** | **A** và **B** đều là `@axioledger/axio-design-system` → conflict trực tiếp nếu resolve cùng lúc |
| **CSS token override** | Cả 3 đều khai báo `--axq-*` variables → rule nào load sau sẽ ghi đè |
| **Dark mode conflict** | 3 schema `[data-theme="dark"]` khác nhau → không thể dùng song song |
| **Version skew** | A=2.0.0, B=5.0.0, C=4.0.0 → có thể chứa breaking changes giữa các version |
| **Icon sprite** | Chỉ C có icon system → nếu chọn A hoặc B phải bổ sung icon riêng |
| **Registry mismatch** | A+B từ org `axioledger`, C từ org `veraciphers` → authen token khác nhau |

---

## 8. Điểm mạnh & điểm yếu

### Resource A — `axioledger-monorepo/design-system` (v2.0.0)
| ✅ Điểm mạnh | ⚠️ Điểm yếu |
|---|---|
| 24 components đầy đủ nhất | Version thấp nhất (2.0.0) |
| Jest testing với coverage thresholds | Không có icon system |
| README tiếng Việt, docs đầy đủ | Package name trùng với B |
| Bundle size monitoring script | |
| Crypto-specific components (8) | |
| Storybook v8 + a11y + themes | |
| AxioProvider với ANS + theme context | |

### Resource B — `packages/axio-design-system` (v5.0.0)
| ✅ Điểm mạnh | ⚠️ Điểm yếu |
|---|---|
| Version cao nhất (5.0.0) — likely nhất hiện tại | Chỉ 7 components |
| Granular export paths (8 paths) | Không có build step → chỉ dùng được trong monorepo |
| Layer token tách riêng rõ ràng nhất | Không có Storybook |
| Source-only → Next.js tree-shake tối ưu | Không có testing |
| TLP tokens dưới dạng TypeScript constants | Không có docs/changelog |
| Legacy compat tokens (--color-*) | Package name trùng với A |

### Resource C — `/root/design-system` (v4.0.0)
| ✅ Điểm mạnh | ⚠️ Điểm yếu |
|---|---|
| **1,897 icons** (linear + bold) — duy nhất | Khác org (veraciphers vs axioledger) |
| Storybook v8.2.4 với interactions addon | Không có TLP / ANS / Passkey |
| SVG sprite auto-generated | Không có crypto-specific components |
| Tailwind token export | Không có testing |
| Composite DeFi components (SwapCard, WalletHome) | |
| WCAG 2.1 AA accessibility checks | |

---

## 9. Ma trận quyết định

> Câu hỏi: Với bối cảnh dự án **Axioledger** (blockchain/DeFi, ANS resolver, TLP security, Web3 wallet), tài nguyên nào phù hợp nhất để duy trì lâu dài?

| Tiêu chí | Trọng số | A (v2.0) | B (v5.0) | C (v4.0) |
|---|---|---|---|---|
| Số lượng & độ phủ component | 20% | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ |
| Crypto/Web3 features | 20% | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| Kiến trúc token | 15% | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Testing & quality | 15% | ⭐⭐⭐⭐⭐ | ⭐ | ⭐ |
| Tài liệu & DX | 10% | ⭐⭐⭐⭐⭐ | ⭐ | ⭐⭐⭐ |
| Icon system | 10% | ⭐ | ⭐ | ⭐⭐⭐⭐⭐ |
| Build & phân phối | 10% | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Tổng (có trọng số)** | **100%** | **4.3/5** | **3.0/5** | **3.1/5** |

---

## 10. Các phương án để hỏi cố vấn

### Phương án 1 — Giữ A (`monorepo/design-system` v2.0.0), bổ sung icon từ C
- Hợp nhất icon sprite của C vào A
- Xóa B và C
- **Ưu:** Component đầy đủ nhất + testing + docs + crypto features
- **Nhược:** Cần migration từ B (v5.0 → v2.0 là downgrade về version)

### Phương án 2 — Nâng cấp B (`packages/axio-design-system` v5.0.0) thành nguồn chính
- Port toàn bộ component từ A vào B
- Thêm icon system từ C, Storybook, testing
- Xóa A và C
- **Ưu:** Version cao nhất, source-only tối ưu cho monorepo, layer token rõ ràng nhất
- **Nhược:** Tốn nhiều effort rebuild; hiện tại thiếu nhiều component

### Phương án 3 — Merge A + C, bỏ B
- Giữ A làm nền tảng (component + docs + testing)
- Tích hợp icon system (1,897 icons) và `tailwind-tokens.js` từ C
- Đổi package name về `@axioledger/axio-design-system`
- **Ưu:** Giữ tất cả điểm mạnh quan trọng nhất
- **Nhược:** Cần kiểm tra compatibility giữa CSS token của A và C

### Phương án 4 — Greenfield từ B (v5.0.0) làm nền, cherry-pick component
- Giữ kiến trúc token của B (rõ ràng nhất, version cao nhất)
- Lần lượt port component từ A, icon từ C
- **Ưu:** Kiến trúc sạch, không legacy debt
- **Nhược:** Tốn effort nhất; cần freeze feature dev trong thời gian migration

---

## 11. Câu hỏi đề xuất cho cố vấn

1. **Về version:** B có version 5.0.0 nhưng thiếu nhiều thứ so với A (v2.0.0) — version này có phản ánh đúng mức độ trưởng thành không? Hay chỉ là bump số bởi người khác?
2. **Về icon:** Dự án có thực sự cần 1,897 icons? Hay có thể dùng icon library bên ngoài (Heroicons, Lucide) để giảm complexity?
3. **Về monorepo source-only (B):** Nếu apps bên ngoài monorepo cần dùng design system, có thể dùng B không? Hay bắt buộc phải có build step như A và C?
4. **Về TLP/ANS:** Đây là feature cốt lõi của Axioledger — cố vấn có xác nhận đây là requirement production hay chỉ là POC?
5. **Về test coverage:** A có Jest + coverage thresholds (70–80%). Tiêu chuẩn này có cần thiết không, hay có thể dùng e2e tests thay thế?
6. **Về registry:** C dùng org `veraciphers` — đây có phải là org cũ/fork? Có plan chuyển về `axioledger` không?
7. **Timeline:** Quyết định này có ảnh hưởng đến release schedule nào không? Cần biết để plan migration effort.

---

## 12. Khuyến nghị sơ bộ (chờ xác nhận cố vấn)

> ⚡ **Nếu cần quyết định nhanh:** Chọn **Phương án 3** (Merge A + C)  
> Giữ `axioledger-monorepo/design-system` (A) làm nguồn chính, tích hợp icon sprite từ `/root/design-system` (C), xóa `packages/axio-design-system` (B) sau khi đảm bảo không có app nào đang import trực tiếp từ B.

> 🏗️ **Nếu có thời gian refactor:** Chọn **Phương án 2** — nâng B lên thành nguồn chính vì kiến trúc token của B là sạch nhất và version 5.0.0 thể hiện intent dài hạn.

---

*Tài liệu này được tạo tự động bằng Bob AI. Vui lòng xác minh lại với team trước khi thực thi.*
