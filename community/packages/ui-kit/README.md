# @YOUR_NPM_SCOPE_UPPER/ui

> **YOUR_TOKEN Organisation — Exclusive Design System Library**
> Thư viện component React/TypeScript độc quyền, trích xuất từ YOUR_TOKEN Design System.

---

## Cài đặt

```bash
# Trong monorepo axvietnam
pnpm add @YOUR_NPM_SCOPE_UPPER/ui
```

---

## Cấu trúc thư viện

```
@YOUR_NPM_SCOPE_UPPER/ui
├── tokens/
│   ├── colors.ts          ← Brand + Semantic + Shade scales
│   ├── typography.ts      ← Work Sans — sizes, weights, line-heights
│   ├── spacing.ts         ← 4px grid — spacing, radius, shadow, z-index
│   └── cssVariables.ts    ← CSS Custom Properties (--YOUR_TOKEN-*)
└── components/
    ├── Typography/
    │   ├── Text.tsx           ← <Text variant="h1" weight="semibold">
    │   └── TypographyScale.tsx ← Reference / docs component
    ├── ColorPalette/
    │   └── ColorPalette.tsx    ← Reference / docs component
    └── Icon/
        ├── icons.tsx          ← 100+ SVG icon components
        ├── IconGallery.tsx    ← Searchable icon reference
        └── index.ts
```

---

## 1 — Tokens

### Colors

```tsx
import { colorBrand, colorShades, colors } from "@YOUR_NPM_SCOPE_UPPER/ui";

// Brand palette
colorBrand.dark     // #000000
colorBrand.magenta  // #FD9FDD
colorBrand.orange   // #FC7339
colorBrand.greeny   // #BEFF6C
colorBrand.violet   // #AF96FB

// Semantic
colors.info         // #0095FF
colors.success      // #00D68F
colors.warning      // #FFAA00
colors.error        // #FF3D71

// Shade scales (index 0 = darkest, 7 = lightest)
colorShades.info[3]       // #0095FF  (base)
colorShades.greyscale[2]  // #2E3A59
```

### Typography

```tsx
import { fontSize, fontWeight, fontFamily } from "@YOUR_NPM_SCOPE_UPPER/ui";

fontSize.h1        // "6rem"    (96px)
fontSize.body2     // "0.875rem"(14px)
fontWeight.semibold // 600
fontFamily.base    // "'Work Sans', ..."
```

### CSS Variables

```tsx
import { injectYOUR_TOKENTokens } from "@YOUR_NPM_SCOPE_UPPER/ui";

// Gọi một lần ở App root — inject tất cả --YOUR_TOKEN-* variables vào <head>
injectYOUR_TOKENTokens();
```

```css
/* Sử dụng trong CSS */
.my-element {
  background: var(--YOUR_TOKEN-brand-violet);
  font-size:  var(--YOUR_TOKEN-fs-h5);
  color:      var(--YOUR_TOKEN-grey-700);
  padding:    var(--YOUR_TOKEN-space-4);
  border-radius: var(--YOUR_TOKEN-radius-lg);
}
```

---

## 2 — Typography Component

```tsx
import { Text } from "@YOUR_NPM_SCOPE_UPPER/ui";

// Headings
<Text variant="h1">YOUR_INFRA</Text>
<Text variant="h3" weight="medium" color="#2E3A59">Dashboard</Text>

// Body
<Text variant="body1">Đây là nội dung chính.</Text>
<Text variant="caption" color="#8F9BB3">Ghi chú nhỏ</Text>

// Overline (tự động uppercase)
<Text variant="overline">Section label</Text>

// Button label
<Text variant="btnLarge">Tiếp tục</Text>

// Truncate overflow
<Text variant="subtitle1" truncate>Nội dung rất dài sẽ bị cắt ngắn...</Text>

// Custom tag
<Text variant="h2" as="span">Inline heading</Text>
```

| Prop | Type | Default |
|------|------|---------|
| `variant` | `h1…h6 \| subtitle1/2 \| body1/2 \| caption \| overline \| btnGiant/Large/Medium/Small` | `body1` |
| `weight` | `regular \| medium \| semibold` | variant default |
| `color` | `string` | `#2E3A59` |
| `align` | `left \| center \| right \| justify` | `left` |
| `truncate` | `boolean` | `false` |
| `as` | `ElementType` | variant default tag |

### TypographyScale — Reference

```tsx
import { TypographyScale } from "@YOUR_NPM_SCOPE_UPPER/ui";

// Dùng trong Storybook hoặc docs page
<TypographyScale />
```

---

## 3 — Color Palette Component

```tsx
import { ColorPalette } from "@YOUR_NPM_SCOPE_UPPER/ui";

// Reference component hiển thị toàn bộ bảng màu YOUR_TOKEN
<ColorPalette />
```

---

## 4 — Icon Set

Tất cả icon là SVG inline, **zero external dependency**, linear stroke style.

```tsx
import {
  ArrowRight, Wallet, Shield, Bell, User,
  Search, Home, Settings2, CreditCard, Send,
} from "@YOUR_NPM_SCOPE_UPPER/ui";

// Basic usage
<ArrowRight />
<Wallet size={32} color="#0095FF" />
<Shield size={20} strokeWidth={2} />

// Dynamic icon by name
import { YOUR_TOKENIcon } from "@YOUR_NPM_SCOPE_UPPER/ui";
<YOUR_TOKENIcon name="Wallet" size={24} color="#00D68F" />
```

### Props

| Prop | Type | Default |
|------|------|---------|
| `size` | `number` | `24` |
| `color` | `string` | `currentColor` |
| `strokeWidth` | `number` | `1.5` |
| + tất cả `SVGAttributes` | | |

### IconGallery — Reference

```tsx
import { IconGallery } from "@YOUR_NPM_SCOPE_UPPER/ui";

// Searchable gallery — dùng trong Storybook
<IconGallery />
```

### Danh sách categories

| Category | Số icon |
|----------|---------|
| Arrow | 12 |
| Archive | 5 |
| Business | 7 |
| Call | 5 |
| Files | 6 |
| Money | 10 |
| Users | 8 |
| Security | 8 |
| Settings | 6 |
| Notifications | 3 |
| Location | 4 |
| Search | 3 |
| Shop | 4 |
| Time | 3 |
| Grid / Layout | 7 |
| Content | 6 |
| Delivery | 2 |
| Building | 2 |
| Essential | 19 |
| **Total** | **~120** |

---

## License

`UNLICENSED` — © YOUR_TOKEN Organisation. All rights reserved.
