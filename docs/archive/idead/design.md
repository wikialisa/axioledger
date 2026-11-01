# AXQ Design System — Variable Token Architecture

> Variable / Token Architecture — 3-Layer Model (Primitive → Semantic → Component)  
> Trích xuất trực tiếp từ 14 token files · 6 component scopes · Light & Dark mode · Font: Work Sans

---

## Mục Lục

1. [Kiến Trúc 3 Tầng](#kiến-trúc-3-tầng)
2. [Tổng Quan Collections](#tổng-quan--collections-trong-axq-variable-system)
3. [Layer 1 — Primitive Color](#layer-1--primitive-color-palette)
   - [Greyscale](#greyscale)
   - [Brand Colors](#brand-colors--axq-accent-palette)
   - [Status Colors — Thang đầy đủ 100–900](#status-colors--thang-đầy-đủ-100900)
4. [Layer 1 — Primitive Spacing, Radius & Font Size](#layer-1--primitive-spacing-radius--font-size)
5. [Layer 2 — Semantic (Light Mode)](#layer-2--semantic-alias-từ-primitive-light-mode)
   - [Text](#color--text)
   - [Background & Surface](#color--background--surface)
   - [Icon](#color--icon)
   - [Border](#color--border)
   - [Status](#color--status)
   - [Accent](#color--accent)
   - [Radius Mapping](#semantic-radius-mapping)
   - [Spacing Mapping](#semantic-spacing-mapping)
   - [Typography](#semantic-typography)
6. [Dark Mode Overrides](#dark-mode-overrides)
7. [Layer 3 — Component Tokens](#layer-3--component-tokens)
   - [Button](#button)
   - [Input](#input)
   - [Card](#card)
   - [Badge & Chip](#badge--chip)
   - [Toggle](#toggle)
   - [Navbar](#navbar)
   - [Modal](#modal)
   - [Avatar](#avatar)
   - [Tooltip](#tooltip)
8. [Typography — Work Sans](#typography--font-work-sans)
9. [CSS Custom Properties Output](#css-custom-properties-output)
10. [Figma JSON Token Export](#figma-json-token-export-example)
11. [Naming Convention & Do/Don't Rules](#naming-convention--dodont-rules)
12. [Quy Trình Thiết Lập trong Figma](#quy-trình-thiết-lập-variable-system-trong-figma)

---

## Kiến Trúc 3 Tầng

```
┌──────────────────────┐       ┌──────────────────────┐       ┌──────────────────────┐
│       LAYER 1        │  -->  │       LAYER 2        │  -->  │       LAYER 3        │
│      Primitive       │       │       Semantic       │       │      Component       │
│                      │       │                      │       │                      │
│  Giá trị gốc,        │       │  Ý nghĩa sử dụng UI  │       │  Token linh kiện     │
│  tuyệt đối           │       │  — ngữ cảnh rõ ràng  │       │  cụ thể              │
│                      │       │                      │       │                      │
│  #49DBC8             │  -->  │  bg/brand            │  -->  │  button/primary-bg   │
│  greyscale/900       │  -->  │  text/primary        │  -->  │  input/text          │
│  radius/2xl          │  -->  │  radius/button       │  -->  │  button/radius       │
└──────────────────────┘       └──────────────────────┘       └──────────────────────┘
```

**Nguyên tắc:** Component tokens **không bao giờ** trỏ thẳng về Primitive. Mọi thay đổi theme chỉ cần override tại Layer 2.

---

## Tổng Quan — Collections trong AXQ Variable System

### Layer 1 — Primitive Collections

| Collection | Mode | Nội dung |
|---|---|---|
| `AXQ / Primitive / Color` | Value | white, black · greyscale/100–900 · brand × 7 · info/100–900 · success/100–900 · warning/100–900 · error/100–900 |
| `AXQ / Primitive / Spacing` | Value | space/0 → space/128 (18 steps) |
| `AXQ / Primitive / Radius` | Value | none, xs, sm, md, lg, xl, 2xl, 3xl, full |
| `AXQ / Primitive / Font Size` | Value | 10, 12, 14, 16, 20, 24, 34, 48, 60, 96 |

### Layer 2 — Semantic Collections

| Collection | Mode | Nội dung |
|---|---|---|
| `AXQ / Semantic / Color` | Light / **Dark** | bg/ · surface/ · text/ · icon/ · border/ · status/ · accent/ |
| `AXQ / Semantic / Spacing+Radius+FontSize` | Default | spacing/ · inset/ · gap/ · radius/ · type/ |

### Layer 3 — Component Collection

| Collection | Mode | Scope |
|---|---|---|
| `AXQ / Component` | Default | button/ · input/ · card/ · badge/ · chip/ · toggle/ · navbar/ · modal/ · avatar/ · tooltip/ |

---

## Layer 1 — Primitive Color Palette

### Greyscale

| Token | Hex | Mô tả | Dùng cho |
|---|---|---|---|
| `white` | `#FFFFFF` | Pure White | Background, inverse text |
| `black` | `#000000` | Pure Black | Brand primary, text brand |
| `greyscale/100` | `#EDF1F7` | Lightest surface | Border subtle, bg tertiary hover |
| `greyscale/200` | `#E4E9F2` | Disabled background | Disabled state, input border |
| `greyscale/300` | `#C5CEE0` | Disabled text | Placeholder, disabled label |
| `greyscale/400` | `#8F9BB3` | Tertiary text | Placeholder active, icon inactive |
| `greyscale/500` | `#2E3A59` | Secondary text | Body secondary, icon secondary |
| `greyscale/600` | `#222B45` | Dark | Dark mode base |
| `greyscale/700` | `#192038` | Darker | Dark mode surface |
| `greyscale/800` | `#151A30` | Very dark | Dark mode elevated |
| `greyscale/900` | `#101426` | Primary text (darkest) | Body text, heading |

### Brand Colors — AXQ Accent Palette

| Token | Hex | Role | Contrast pairing |
|---|---|---|---|
| `brand/teal` | `#49DBC8` | Accent Teal | Dark text on light bg |
| `brand/green` | `#BEFF6C` | Accent Green | Dark text on light bg |
| `brand/orange` | `#FC7339` | Accent Orange | White text on dark bg |
| `brand/pink` | `#FD9FDD` | Accent Pink | Dark text on light bg |
| `brand/purple` | `#AF96FB` | Accent Purple | Dark text on light bg |
| `brand/yellow` | `#FFF172` | Accent Yellow | Dark text on light bg |
| `brand/grey` | `#EFEFEF` | Accent Grey | Dark text |

### Status Colors — Thang đầy đủ 100–900

#### Info

| Token | Hex | Dùng cho |
|---|---|---|
| `info/100` | `#F2F8FF` | Background nhạt (badge bg, alert bg) |
| `info/200` | `#C7E2FF` | Subtle bg hover |
| `info/300` | `#94CBFF` | Subtle border |
| `info/400` | `#42AAFF` | Hover state |
| `info/500` | `#0095FF` | **Default** — button, icon, border focus |
| `info/600` | `#006FD6` | Active / pressed state |
| `info/700` | `#0057C2` | Text on light bg (accessible) |
| `info/800` | `#003F8F` | Dark text, dark mode |
| `info/900` | `#002885` | Darkest — dark mode text |

#### Success

| Token | Hex | Dùng cho |
|---|---|---|
| `success/100` | `#F0FFF5` | Background nhạt |
| `success/200` | `#CCFCE3` | Subtle bg hover |
| `success/300` | `#8CFAC7` | Subtle border |
| `success/400` | `#2CE69B` | Hover state |
| `success/500` | `#00D68F` | **Default** — toggle active, button success |
| `success/600` | `#00B887` | Active / pressed |
| `success/700` | `#00997A` | Text on light bg |
| `success/800` | `#007D6C` | Dark text |
| `success/900` | `#004A45` | Darkest |

#### Warning

| Token | Hex | Dùng cho |
|---|---|---|
| `warning/100` | `#FFFDF2` | Background nhạt |
| `warning/200` | `#FFF1C2` | Subtle bg hover |
| `warning/300` | `#FFE59E` | Subtle border |
| `warning/400` | `#FFC94D` | Hover state |
| `warning/500` | `#FFAA00` | **Default** — button warning |
| `warning/600` | `#DB8B00` | Active / pressed |
| `warning/700` | `#B86E00` | Text on light bg |
| `warning/800` | `#945400` | Dark text |
| `warning/900` | `#703C00` | Darkest |

#### Error

| Token | Hex | Dùng cho |
|---|---|---|
| `error/100` | `#FFF2F2` | Background nhạt |
| `error/200` | `#FFD6D9` | Subtle bg hover |
| `error/300` | `#FFA8B4` | Subtle border |
| `error/400` | `#FF708D` | Hover state |
| `error/500` | `#FF3D71` | **Default** — button danger, input error |
| `error/600` | `#DB2C66` | Active / pressed |
| `error/700` | `#B81D5B` | Text on light bg |
| `error/800` | `#94124E` | Dark text |
| `error/900` | `#700940` | Darkest |

---

## Layer 1 — Primitive Spacing, Radius & Font Size

### Radius Scale

| Token | Value | Dùng cho |
|---|---|---|
| `radius/none` | 0px | Square elements, table cells |
| `radius/xs` | 2px | Tags, tiny badges |
| `radius/sm` | 4px | Badges, tooltips, small chips |
| `radius/md` | 8px | Dropdowns, popovers, small cards |
| `radius/lg` | 12px | Inputs, text fields |
| `radius/xl` | 16px | Cards, panels |
| `radius/2xl` | 24px | Buttons, modals |
| `radius/3xl` | 32px | Large modals, bottom sheets |
| `radius/full` | 9999px | Pills, chips, avatars, toggles |

### Font Size Scale

| Token | Value | Semantic | Dùng cho |
|---|---|---|---|
| `fontSize/10` | 10px | Overline | Label nhỏ, metadata |
| `fontSize/12` | 12px | Caption | Caption, helper text, badge |
| `fontSize/14` | 14px | Body-sm | Body text nhỏ, label |
| `fontSize/16` | 16px | Body | Body text chính |
| `fontSize/20` | 20px | H6 | Subheading, card title |
| `fontSize/24` | 24px | H5 | Section heading |
| `fontSize/34` | 34px | H4 | Page section title |
| `fontSize/48` | 48px | H3 | Major section |
| `fontSize/60` | 60px | H2 | Hero subheading |
| `fontSize/96` | 96px | H1 | Hero heading |

### Spacing Scale — `space/*`

| Token | Value | Gợi ý dùng |
|---|---|---|
| `space/0` | 0px | Reset |
| `space/2` | 2px | Icon gap nhỏ nhất |
| `space/4` | 4px | Inline gap, badge padding |
| `space/6` | 6px | Icon-text gap nhỏ |
| `space/8` | 8px | Button padding-y, gap trong row |
| `space/10` | 10px | — |
| `space/12` | 12px | Card gap, list gap |
| `space/16` | 16px | Button padding-x, input padding |
| `space/20` | 20px | Section gap nhỏ |
| `space/24` | 24px | Card padding, form gap |
| `space/32` | 32px | Section padding |
| `space/40` | 40px | Page section gap |
| `space/48` | 48px | Hero padding |
| `space/56` | 56px | — |
| `space/64` | 64px | Page padding lớn |
| `space/80` | 80px | Section top/bottom |
| `space/96` | 96px | Hero section |
| `space/128` | 128px | Full-bleed spacing |

---

## Layer 2 — Semantic Alias từ Primitive (Light Mode)

### Color — Text

| Semantic Token | Alias → Primitive | Hex | Dùng cho |
|---|---|---|---|
| `text/primary` | `greyscale/900` | `#101426` | Body text, heading chính |
| `text/secondary` | `greyscale/500` | `#2E3A59` | Subtext, description, label |
| `text/tertiary` | `greyscale/400` | `#8F9BB3` | Placeholder, helper text, metadata |
| `text/disabled` | `greyscale/300` | `#C5CEE0` | Trạng thái disabled |
| `text/inverse` | `white` | `#FFFFFF` | Text trên bg tối (button primary) |
| `text/brand` | `black` | `#000000` | Logo text, brand emphasis |
| `text/link` | `info/700` | `#0057C2` | Link, anchor text |
| `text/on-color` | `white` | `#FFFFFF` | Text trên bg màu status |

### Color — Background & Surface

| Semantic Token | Alias → Primitive | Hex | Dùng cho |
|---|---|---|---|
| `bg/primary` | `white` | `#FFFFFF` | Trang chính, panel nền |
| `bg/secondary` | `greyscale/100` | `#EDF1F7` | Sidebar, nền phụ |
| `bg/tertiary` | `greyscale/200` | `#E4E9F2` | Toggle inactive, skeleton |
| `bg/inverse` | `greyscale/900` | `#101426` | Tooltip, dark overlay |
| `bg/brand` | `black` | `#000000` | Button primary, header brand |
| `bg/disabled` | `greyscale/200` | `#E4E9F2` | Input disabled, button disabled |
| `surface/default` | `white` | `#FFFFFF` | Card, input, dropdown |
| `surface/raised` | `white` | `#FFFFFF` | Popover, elevated card |
| `surface/overlay` | `greyscale/100` | `#EDF1F7` | Modal backdrop tint |
| `surface/sunken` | `greyscale/100` | `#EDF1F7` | Inset field, code block |

### Color — Icon

| Semantic Token | Alias → Primitive | Hex | Dùng cho |
|---|---|---|---|
| `icon/primary` | `greyscale/900` | `#101426` | Icon mặc định |
| `icon/secondary` | `greyscale/500` | `#2E3A59` | Icon phụ, nav inactive |
| `icon/tertiary` | `greyscale/400` | `#8F9BB3` | Icon hint, placeholder icon |
| `icon/disabled` | `greyscale/300` | `#C5CEE0` | Icon disabled |
| `icon/inverse` | `white` | `#FFFFFF` | Icon trên bg tối |
| `icon/brand` | `black` | `#000000` | Icon brand, nav active |

### Color — Border

| Semantic Token | Alias → Primitive | Hex | Dùng cho |
|---|---|---|---|
| `border/default` | `greyscale/200` | `#E4E9F2` | Input border, card border |
| `border/subtle` | `greyscale/100` | `#EDF1F7` | Divider, separator nhẹ |
| `border/strong` | `greyscale/400` | `#8F9BB3` | Border nhấn mạnh |
| `border/disabled` | `greyscale/200` | `#E4E9F2` | Input disabled border |
| `border/focus` | `info/500` | `#0095FF` | Focus ring, active input |

### Color — Status

| Semantic Token | Alias → Primitive | Hex | Dùng cho |
|---|---|---|---|
| `status/info-bg` | `info/100` | `#F2F8FF` | Alert/badge bg |
| `status/info-subtle` | `info/200` | `#C7E2FF` | Hover bg |
| `status/info-default` | `info/500` | `#0095FF` | Icon, button, indicator |
| `status/info-text` | `info/700` | `#0057C2` | Text trên bg sáng |
| `status/success-bg` | `success/100` | `#F0FFF5` | Alert/badge bg |
| `status/success-subtle` | `success/200` | `#CCFCE3` | Hover bg |
| `status/success-default` | `success/500` | `#00D68F` | Icon, button, toggle |
| `status/success-text` | `success/700` | `#00997A` | Text trên bg sáng |
| `status/warning-bg` | `warning/100` | `#FFFDF2` | Alert/badge bg |
| `status/warning-subtle` | `warning/200` | `#FFF1C2` | Hover bg |
| `status/warning-default` | `warning/500` | `#FFAA00` | Icon, button, indicator |
| `status/warning-text` | `warning/700` | `#B86E00` | Text trên bg sáng |
| `status/error-bg` | `error/100` | `#FFF2F2` | Alert/badge bg |
| `status/error-subtle` | `error/200` | `#FFD6D9` | Hover bg |
| `status/error-default` | `error/500` | `#FF3D71` | Icon, button danger, input error |
| `status/error-text` | `error/700` | `#B81D5B` | Text trên bg sáng |

### Color — Accent

| Semantic Token | Alias → Primitive | Hex |
|---|---|---|
| `accent/teal` | `brand/teal` | `#49DBC8` |
| `accent/green` | `brand/green` | `#BEFF6C` |
| `accent/orange` | `brand/orange` | `#FC7339` |
| `accent/pink` | `brand/pink` | `#FD9FDD` |
| `accent/purple` | `brand/purple` | `#AF96FB` |
| `accent/yellow` | `brand/yellow` | `#FFF172` |

### Semantic Radius Mapping

| Semantic Token | Value | Alias → Primitive | Dùng cho |
|---|---|---|---|
| `radius/button` | 24px | `radius/2xl` | Button, pill CTA |
| `radius/input` | 12px | `radius/lg` | Input, textarea, select |
| `radius/card` | 16px | `radius/xl` | Card, panel, section |
| `radius/modal` | 24px | `radius/2xl` | Modal, drawer, bottom sheet |
| `radius/chip` | 9999px | `radius/full` | Chip, tag |
| `radius/avatar` | 9999px | `radius/full` | Avatar, user icon |
| `radius/badge` | 4px | `radius/sm` | Badge, label nhỏ |
| `radius/tooltip` | 8px | `radius/md` | Tooltip, popover |
| `radius/dropdown` | 8px | `radius/md` | Dropdown menu |

### Semantic Spacing Mapping

#### Inset (padding trong component)

| Semantic Token | Value | Alias → Primitive | Dùng cho |
|---|---|---|---|
| `inset/xs` | 4px | `space/4` | Chip, badge padding |
| `inset/sm` | 8px | `space/8` | Button padding-y, input padding-y |
| `inset/md` | 16px | `space/16` | Button padding-x, input padding-x |
| `inset/lg` | 24px | `space/24` | Card padding |
| `inset/xl` | 32px | `space/32` | Modal padding, section inset |
| `inset/2xl` | 48px | `space/48` | Hero padding |

#### Gap (khoảng cách giữa elements)

| Semantic Token | Value | Alias → Primitive | Dùng cho |
|---|---|---|---|
| `gap/xs` | 4px | `space/4` | Icon + label nhỏ |
| `gap/sm` | 8px | `space/8` | Button icon gap, form row gap nhỏ |
| `gap/md` | 12px | `space/12` | Card item gap |
| `gap/lg` | 16px | `space/16` | Form field gap, list gap |
| `gap/xl` | 24px | `space/24` | Section gap, grid gap |

#### Spacing scale (layout)

| Semantic Token | Value | Alias → Primitive |
|---|---|---|
| `spacing/none` | 0px | `space/0` |
| `spacing/3xs` | 2px | `space/2` |
| `spacing/2xs` | 4px | `space/4` |
| `spacing/xs` | 8px | `space/8` |
| `spacing/sm` | 12px | `space/12` |
| `spacing/md` | 16px | `space/16` |
| `spacing/lg` | 24px | `space/24` |
| `spacing/xl` | 32px | `space/32` |
| `spacing/2xl` | 40px | `space/40` |
| `spacing/3xl` | 64px | `space/64` |
| `spacing/4xl` | 96px | `space/96` |

### Semantic Typography

| Semantic Token | Value | Line Height | Weight default | Alias → Primitive |
|---|---|---|---|---|
| `type/overline` | 10px | 1.4 | 400 | `fontSize/10` |
| `type/caption` | 12px | 1.5 | 400 | `fontSize/12` |
| `type/body-sm` | 14px | 1.6 | 400 | `fontSize/14` |
| `type/body` | 16px | 1.6 | 400 | `fontSize/16` |
| `type/h6` | 20px | 1.4 | 600 | `fontSize/20` |
| `type/h5` | 24px | 1.3 | 600 | `fontSize/24` |
| `type/h4` | 34px | 1.25 | 700 | `fontSize/34` |
| `type/h3` | 48px | 1.2 | 700 | `fontSize/48` |
| `type/h2` | 60px | 1.15 | 700 | `fontSize/60` |
| `type/h1` | 96px | 1.1 | 700 | `fontSize/96` |

---

## Dark Mode Overrides

> Chỉ override tại **`AXQ / Semantic / Color`** mode **Dark** — tất cả Component tokens tự thích nghi.

| Semantic Token | Light | Dark |
|---|---|---|
| `text/primary` | `#101426` | `#F4F5F7` |
| `text/secondary` | `#2E3A59` | `#B0B5C1` |
| `text/tertiary` | `#8F9BB3` | `#757D8F` |
| `text/disabled` | `#C5CEE0` | `#373D49` |
| `text/inverse` | `#FFFFFF` | `#1A1A1A` |
| `text/brand` | `#000000` | `#FFFFFF` |
| `bg/primary` | `#FFFFFF` | `#121318` |
| `bg/secondary` | `#EDF1F7` | `#1A1C23` |
| `bg/tertiary` | `#E4E9F2` | `#21242D` |
| `bg/brand` | `#000000` | `#FFFFFF` |
| `bg/disabled` | `#E4E9F2` | `#2B2E38` |
| `surface/default` | `#FFFFFF` | `#1A1C23` |
| `surface/raised` | `#FFFFFF` | `#21242D` |
| `surface/sunken` | `#EDF1F7` | `#121318` |
| `border/default` | `#E4E9F2` | `#2B2E38` |
| `border/subtle` | `#EDF1F7` | `#21242D` |
| `border/strong` | `#8F9BB3` | `#373D49` |
| `icon/primary` | `#101426` | `#F4F5F7` |
| `icon/secondary` | `#2E3A59` | `#B0B5C1` |
| `icon/brand` | `#000000` | `#FFFFFF` |

---

## Layer 3 — Component Tokens

### Button

| Token | Value | Alias → Semantic | Trạng thái |
|---|---|---|---|
| `button/primary-bg` | `#000000` | `bg/brand` | default |
| `button/primary-text` | `#FFFFFF` | `text/inverse` | default |
| `button/primary-border` | `#000000` | `bg/brand` | default |
| `button/info-bg` | `#0095FF` | `status/info-default` | default |
| `button/info-text` | `#FFFFFF` | `text/inverse` | default |
| `button/success-bg` | `#00D68F` | `status/success-default` | default |
| `button/success-text` | `#FFFFFF` | `text/inverse` | default |
| `button/warning-bg` | `#FFAA00` | `status/warning-default` | default |
| `button/warning-text` | `#FFFFFF` | `text/inverse` | default |
| `button/danger-bg` | `#FF3D71` | `status/error-default` | default |
| `button/danger-text` | `#FFFFFF` | `text/inverse` | default |
| `button/disabled-bg` | `#E4E9F2` | `bg/disabled` | disabled |
| `button/disabled-text` | `#C5CEE0` | `text/disabled` | disabled |
| `button/ghost-bg` | `#FFFFFF` | `bg/primary` | default |
| `button/ghost-text` | `#101426` | `text/primary` | default |
| `button/ghost-border` | `#E4E9F2` | `border/default` | default |
| `button/ghost-border-hover` | `#8F9BB3` | `border/strong` | hover |
| `button/padding-x` | 16px | `inset/md` | — |
| `button/padding-y` | 8px | `inset/sm` | — |
| `button/gap` | 8px | `gap/sm` | — |
| `button/radius` | 24px | `radius/button` | — |
| `button/font-size` | 16px | `type/body` | — |

### Input

| Token | Value | Alias → Semantic | Trạng thái |
|---|---|---|---|
| `input/bg` | `#FFFFFF` | `surface/default` | default |
| `input/text` | `#101426` | `text/primary` | default |
| `input/placeholder` | `#8F9BB3` | `text/tertiary` | default |
| `input/border` | `#E4E9F2` | `border/default` | default |
| `input/border-hover` | `#8F9BB3` | `border/strong` | hover |
| `input/border-focus` | `#0095FF` | `border/focus` | focus |
| `input/border-error` | `#FF3D71` | `status/error-default` | error |
| `input/border-disabled` | `#E4E9F2` | `border/disabled` | disabled |
| `input/bg-disabled` | `#E4E9F2` | `bg/disabled` | disabled |
| `input/text-disabled` | `#C5CEE0` | `text/disabled` | disabled |
| `input/label` | `#2E3A59` | `text/secondary` | default |
| `input/helper-text` | `#8F9BB3` | `text/tertiary` | default |
| `input/error-text` | `#B81D5B` | `status/error-text` | error |
| `input/padding-x` | 16px | `inset/md` | — |
| `input/padding-y` | 8px | `inset/sm` | — |
| `input/radius` | 12px | `radius/input` | — |
| `input/font-size` | 16px | `type/body` | — |
| `input/label-size` | 12px | `type/caption` | — |
| `input/helper-size` | 12px | `type/caption` | — |

### Card

| Token | Value | Alias → Semantic |
|---|---|---|
| `card/bg` | `#FFFFFF` | `surface/default` |
| `card/bg-hover` | `#EDF1F7` | `surface/overlay` |
| `card/border` | `#EDF1F7` | `border/subtle` |
| `card/border-hover` | `#E4E9F2` | `border/default` |
| `card/title` | `#101426` | `text/primary` |
| `card/description` | `#2E3A59` | `text/secondary` |
| `card/metadata` | `#8F9BB3` | `text/tertiary` |
| `card/padding` | 24px | `inset/lg` |
| `card/gap` | 12px | `gap/md` |
| `card/radius` | 16px | `radius/card` |

### Badge & Chip

| Token | Value | Alias → Semantic |
|---|---|---|
| `badge/info-bg` | `#F2F8FF` | `status/info-bg` |
| `badge/info-text` | `#0057C2` | `status/info-text` |
| `badge/info-border` | `#C7E2FF` | `status/info-subtle` |
| `badge/success-bg` | `#F0FFF5` | `status/success-bg` |
| `badge/success-text` | `#00997A` | `status/success-text` |
| `badge/warning-bg` | `#FFFDF2` | `status/warning-bg` |
| `badge/warning-text` | `#B86E00` | `status/warning-text` |
| `badge/error-bg` | `#FFF2F2` | `status/error-bg` |
| `badge/error-text` | `#B81D5B` | `status/error-text` |
| `badge/radius` | 4px | `radius/badge` |
| `badge/font-size` | 12px | `type/caption` |
| `badge/padding-x` | 8px | `gap/sm` |
| `badge/padding-y` | 4px | `gap/xs` |
| `chip/bg` | `#EDF1F7` | `bg/secondary` |
| `chip/bg-active` | `#000000` | `bg/brand` |
| `chip/text` | `#101426` | `text/primary` |
| `chip/text-active` | `#FFFFFF` | `text/inverse` |
| `chip/border` | `#E4E9F2` | `border/default` |
| `chip/radius` | 9999px | `radius/chip` |
| `chip/font-size` | 14px | `type/body-sm` |

### Toggle

| Token | Value | Alias → Semantic | Trạng thái |
|---|---|---|---|
| `toggle/active-bg` | `#00D68F` | `status/success-default` | on |
| `toggle/inactive-bg` | `#E4E9F2` | `bg/tertiary` | off |
| `toggle/thumb` | `#FFFFFF` | `bg/primary` | both |
| `toggle/disabled-bg` | `#E4E9F2` | `bg/disabled` | disabled |
| `toggle/disabled-thumb` | `#C5CEE0` | `text/disabled` | disabled |
| `toggle/focus-ring` | `#0095FF` | `border/focus` | focus |

### Navbar

| Token | Value | Alias → Semantic |
|---|---|---|
| `navbar/bg` | `#FFFFFF` | `surface/default` |
| `navbar/border` | `#EDF1F7` | `border/subtle` |
| `navbar/icon-active` | `#000000` | `icon/brand` |
| `navbar/icon-inactive` | `#2E3A59` | `icon/secondary` |
| `navbar/label-active` | `#000000` | `text/brand` |
| `navbar/label-inactive` | `#2E3A59` | `text/secondary` |
| `navbar/indicator-bg` | `#000000` | `bg/brand` |
| `navbar/indicator-text` | `#FFFFFF` | `text/inverse` |
| `navbar/icon-size` | 24px | `type/h5` |
| `navbar/label-size` | 12px | `type/caption` |
| `navbar/height` | 64px | `spacing/3xl` |

### Modal

| Token | Value | Alias → Semantic |
|---|---|---|
| `modal/bg` | `#FFFFFF` | `surface/default` |
| `modal/overlay` | `rgba(16,20,38,0.6)` | `bg/inverse` @ 60% |
| `modal/border` | `#E4E9F2` | `border/default` |
| `modal/title` | `#101426` | `text/primary` |
| `modal/description` | `#2E3A59` | `text/secondary` |
| `modal/close-icon` | `#8F9BB3` | `icon/tertiary` |
| `modal/close-hover` | `#101426` | `icon/primary` |
| `modal/padding` | 32px | `inset/xl` |
| `modal/gap` | 16px | `gap/lg` |
| `modal/radius` | 24px | `radius/modal` |

### Avatar

| Token | Value | Alias → Semantic |
|---|---|---|
| `avatar/bg-default` | `#EDF1F7` | `bg/secondary` |
| `avatar/text-default` | `#2E3A59` | `text/secondary` |
| `avatar/border` | `#FFFFFF` | `bg/primary` |
| `avatar/border-ring` | `#000000` | `bg/brand` |
| `avatar/radius` | 9999px | `radius/avatar` |
| `avatar/size-xs` | 24px | — |
| `avatar/size-sm` | 32px | — |
| `avatar/size-md` | 40px | — |
| `avatar/size-lg` | 56px | — |
| `avatar/size-xl` | 80px | — |

### Tooltip

| Token | Value | Alias → Semantic |
|---|---|---|
| `tooltip/bg` | `#101426` | `bg/inverse` |
| `tooltip/text` | `#FFFFFF` | `text/inverse` |
| `tooltip/radius` | 8px | `radius/tooltip` |
| `tooltip/padding-x` | 12px | `gap/md` |
| `tooltip/padding-y` | 6px | `gap/xs` |
| `tooltip/font-size` | 12px | `type/caption` |
| `tooltip/arrow-size` | 6px | — |

---

## Typography — Font: Work Sans

| Style Name | Size | Token | Weight | Line Height | Letter Spacing | Transform |
|---|---|---|---|---|---|---|
| **Headline / H1** | 96px | `type/h1` | 400 / 500 / 700 | 1.1 | -2px | Default |
| **Headline / H2** | 60px | `type/h2` | 400 / 500 / 700 | 1.15 | -1px | Default |
| **Headline / H3** | 48px | `type/h3` | 400 / 500 / 700 | 1.2 | -0.5px | Default |
| **Headline / H4** | 34px | `type/h4` | 400 / 500 / 700 | 1.25 | -0.25px | Default |
| **Headline / H5** | 24px | `type/h5` | 400 / 500 / 600 | 1.3 | 0 | Default |
| **Headline / H6** | 20px | `type/h6` | 400 / 500 / 600 | 1.4 | 0 | Default |
| **Body / Default** | 16px | `type/body` | 400 / 500 | 1.6 | 0 | Default |
| **Body / Small** | 14px | `type/body-sm` | 400 / 500 | 1.6 | 0 | Default |
| **Caption** | 12px | `type/caption` | 400 / 500 | 1.5 | 0.1px | Default |
| **Overline** | 10px | `type/overline` | 400 | 1.4 | 1.5px | UPPERCASE |

---

## CSS Custom Properties Output

Đây là output CSS tương ứng khi export token system sang code:

```css
/* ══════════════════════════════════════════════════
   AXQ Design System — CSS Custom Properties
   Auto-generated from Variable Token System v1.0
   ══════════════════════════════════════════════════ */

/* ── Primitive: Color ──────────────────────────── */
:root {
  /* Greyscale */
  --axq-white: #FFFFFF;
  --axq-black: #000000;
  --axq-grey-100: #EDF1F7;
  --axq-grey-200: #E4E9F2;
  --axq-grey-300: #C5CEE0;
  --axq-grey-400: #8F9BB3;
  --axq-grey-500: #2E3A59;
  --axq-grey-600: #222B45;
  --axq-grey-700: #192038;
  --axq-grey-800: #151A30;
  --axq-grey-900: #101426;

  /* Brand Accent */
  --axq-brand-teal:   #49DBC8;
  --axq-brand-green:  #BEFF6C;
  --axq-brand-orange: #FC7339;
  --axq-brand-pink:   #FD9FDD;
  --axq-brand-purple: #AF96FB;
  --axq-brand-yellow: #FFF172;
  --axq-brand-grey:   #EFEFEF;

  /* Status — Info */
  --axq-info-100: #F2F8FF;
  --axq-info-500: #0095FF;
  --axq-info-700: #0057C2;

  /* Status — Success */
  --axq-success-100: #F0FFF5;
  --axq-success-500: #00D68F;
  --axq-success-700: #00997A;

  /* Status — Warning */
  --axq-warning-100: #FFFDF2;
  --axq-warning-500: #FFAA00;
  --axq-warning-700: #B86E00;

  /* Status — Error */
  --axq-error-100: #FFF2F2;
  --axq-error-500: #FF3D71;
  --axq-error-700: #B81D5B;
}

/* ── Primitive: Spacing ────────────────────────── */
:root {
  --axq-space-0:   0px;
  --axq-space-2:   2px;
  --axq-space-4:   4px;
  --axq-space-6:   6px;
  --axq-space-8:   8px;
  --axq-space-10:  10px;
  --axq-space-12:  12px;
  --axq-space-16:  16px;
  --axq-space-20:  20px;
  --axq-space-24:  24px;
  --axq-space-32:  32px;
  --axq-space-40:  40px;
  --axq-space-48:  48px;
  --axq-space-64:  64px;
  --axq-space-80:  80px;
  --axq-space-96:  96px;
  --axq-space-128: 128px;
}

/* ── Primitive: Radius ─────────────────────────── */
:root {
  --axq-radius-none: 0px;
  --axq-radius-xs:   2px;
  --axq-radius-sm:   4px;
  --axq-radius-md:   8px;
  --axq-radius-lg:   12px;
  --axq-radius-xl:   16px;
  --axq-radius-2xl:  24px;
  --axq-radius-3xl:  32px;
  --axq-radius-full: 9999px;
}

/* ── Primitive: Font Size ──────────────────────── */
:root {
  --axq-fs-10: 10px;
  --axq-fs-12: 12px;
  --axq-fs-14: 14px;
  --axq-fs-16: 16px;
  --axq-fs-20: 20px;
  --axq-fs-24: 24px;
  --axq-fs-34: 34px;
  --axq-fs-48: 48px;
  --axq-fs-60: 60px;
  --axq-fs-96: 96px;
}

/* ── Semantic: Color — Light Mode ─────────────── */
:root,
[data-theme="light"] {
  /* Text */
  --axq-text-primary:   var(--axq-grey-900);
  --axq-text-secondary: var(--axq-grey-500);
  --axq-text-tertiary:  var(--axq-grey-400);
  --axq-text-disabled:  var(--axq-grey-300);
  --axq-text-inverse:   var(--axq-white);
  --axq-text-brand:     var(--axq-black);
  --axq-text-link:      var(--axq-info-700);
  --axq-text-on-color:  var(--axq-white);

  /* Background */
  --axq-bg-primary:     var(--axq-white);
  --axq-bg-secondary:   var(--axq-grey-100);
  --axq-bg-tertiary:    var(--axq-grey-200);
  --axq-bg-inverse:     var(--axq-grey-900);
  --axq-bg-brand:       var(--axq-black);
  --axq-bg-disabled:    var(--axq-grey-200);

  /* Surface */
  --axq-surface-default: var(--axq-white);
  --axq-surface-raised:  var(--axq-white);
  --axq-surface-sunken:  var(--axq-grey-100);

  /* Border */
  --axq-border-default:  var(--axq-grey-200);
  --axq-border-subtle:   var(--axq-grey-100);
  --axq-border-strong:   var(--axq-grey-400);
  --axq-border-disabled: var(--axq-grey-200);
  --axq-border-focus:    var(--axq-info-500);

  /* Icon */
  --axq-icon-primary:    var(--axq-grey-900);
  --axq-icon-secondary:  var(--axq-grey-500);
  --axq-icon-tertiary:   var(--axq-grey-400);
  --axq-icon-disabled:   var(--axq-grey-300);
  --axq-icon-inverse:    var(--axq-white);
  --axq-icon-brand:      var(--axq-black);

  /* Semantic: Radius */
  --axq-radius-button:   var(--axq-radius-2xl);
  --axq-radius-input:    var(--axq-radius-lg);
  --axq-radius-card:     var(--axq-radius-xl);
  --axq-radius-modal:    var(--axq-radius-2xl);
  --axq-radius-chip:     var(--axq-radius-full);
  --axq-radius-avatar:   var(--axq-radius-full);
  --axq-radius-badge:    var(--axq-radius-sm);
  --axq-radius-tooltip:  var(--axq-radius-md);
}

/* ── Semantic: Color — Dark Mode ──────────────── */
[data-theme="dark"] {
  --axq-text-primary:    #F4F5F7;
  --axq-text-secondary:  #B0B5C1;
  --axq-text-tertiary:   #757D8F;
  --axq-text-disabled:   #373D49;
  --axq-text-inverse:    #1A1A1A;
  --axq-text-brand:      #FFFFFF;

  --axq-bg-primary:      #121318;
  --axq-bg-secondary:    #1A1C23;
  --axq-bg-tertiary:     #21242D;
  --axq-bg-inverse:      #F4F5F7;
  --axq-bg-brand:        #FFFFFF;
  --axq-bg-disabled:     #2B2E38;

  --axq-surface-default: #1A1C23;
  --axq-surface-raised:  #21242D;
  --axq-surface-sunken:  #121318;

  --axq-border-default:  #2B2E38;
  --axq-border-subtle:   #21242D;
  --axq-border-strong:   #373D49;

  --axq-icon-primary:    #F4F5F7;
  --axq-icon-secondary:  #B0B5C1;
  --axq-icon-brand:      #FFFFFF;
}
```

---

## Figma JSON Token Export Example

Ví dụ cấu trúc JSON khi export từ Figma Variables hoặc dùng với [Token Studio](https://tokens.studio/):

```json
{
  "AXQ": {
    "primitive": {
      "color": {
        "white":  { "$value": "#FFFFFF", "$type": "color" },
        "black":  { "$value": "#000000", "$type": "color" },
        "greyscale": {
          "100": { "$value": "#EDF1F7", "$type": "color" },
          "200": { "$value": "#E4E9F2", "$type": "color" },
          "300": { "$value": "#C5CEE0", "$type": "color" },
          "400": { "$value": "#8F9BB3", "$type": "color" },
          "500": { "$value": "#2E3A59", "$type": "color" },
          "900": { "$value": "#101426", "$type": "color" }
        },
        "brand": {
          "teal":   { "$value": "#49DBC8", "$type": "color" },
          "green":  { "$value": "#BEFF6C", "$type": "color" },
          "orange": { "$value": "#FC7339", "$type": "color" }
        },
        "info": {
          "100": { "$value": "#F2F8FF", "$type": "color" },
          "500": { "$value": "#0095FF", "$type": "color" },
          "700": { "$value": "#0057C2", "$type": "color" }
        }
      },
      "spacing": {
        "0":   { "$value": "0",    "$type": "dimension" },
        "4":   { "$value": "4px",  "$type": "dimension" },
        "8":   { "$value": "8px",  "$type": "dimension" },
        "16":  { "$value": "16px", "$type": "dimension" },
        "24":  { "$value": "24px", "$type": "dimension" }
      },
      "radius": {
        "sm":   { "$value": "4px",    "$type": "borderRadius" },
        "md":   { "$value": "8px",    "$type": "borderRadius" },
        "lg":   { "$value": "12px",   "$type": "borderRadius" },
        "xl":   { "$value": "16px",   "$type": "borderRadius" },
        "2xl":  { "$value": "24px",   "$type": "borderRadius" },
        "full": { "$value": "9999px", "$type": "borderRadius" }
      }
    },
    "semantic": {
      "color": {
        "text": {
          "primary":   { "$value": "{AXQ.primitive.color.greyscale.900}", "$type": "color" },
          "secondary": { "$value": "{AXQ.primitive.color.greyscale.500}", "$type": "color" },
          "disabled":  { "$value": "{AXQ.primitive.color.greyscale.300}", "$type": "color" },
          "inverse":   { "$value": "{AXQ.primitive.color.white}",         "$type": "color" },
          "brand":     { "$value": "{AXQ.primitive.color.black}",         "$type": "color" }
        },
        "bg": {
          "primary":  { "$value": "{AXQ.primitive.color.white}",          "$type": "color" },
          "brand":    { "$value": "{AXQ.primitive.color.black}",          "$type": "color" },
          "disabled": { "$value": "{AXQ.primitive.color.greyscale.200}",  "$type": "color" }
        },
        "border": {
          "default": { "$value": "{AXQ.primitive.color.greyscale.200}", "$type": "color" },
          "focus":   { "$value": "{AXQ.primitive.color.info.500}",      "$type": "color" }
        }
      },
      "radius": {
        "button": { "$value": "{AXQ.primitive.radius.2xl}",  "$type": "borderRadius" },
        "input":  { "$value": "{AXQ.primitive.radius.lg}",   "$type": "borderRadius" },
        "card":   { "$value": "{AXQ.primitive.radius.xl}",   "$type": "borderRadius" }
      }
    },
    "component": {
      "button": {
        "primary-bg":   { "$value": "{AXQ.semantic.color.bg.brand}",    "$type": "color" },
        "primary-text": { "$value": "{AXQ.semantic.color.text.inverse}", "$type": "color" },
        "radius":       { "$value": "{AXQ.semantic.radius.button}",      "$type": "borderRadius" },
        "font-size":    { "$value": "{AXQ.primitive.fontSize.16}",       "$type": "dimension" }
      },
      "input": {
        "border":       { "$value": "{AXQ.semantic.color.border.default}", "$type": "color" },
        "border-focus": { "$value": "{AXQ.semantic.color.border.focus}",   "$type": "color" },
        "radius":       { "$value": "{AXQ.semantic.radius.input}",         "$type": "borderRadius" }
      }
    }
  }
}
```

---

## Naming Convention & Do/Don't Rules

### Quy tắc đặt tên

| Quy tắc | Mô tả |
|---|---|
| **Prefix `AXQ /`** | Tất cả collection trong Figma phải bắt đầu bằng `AXQ /` |
| **Phân cấp bằng `/`** | Dùng `/` để phân cấp: `category/group/name` |
| **Lowercase, kebab-case** | Token name viết thường, dùng `-` nối: `body-sm`, `on-color` |
| **Không dùng tên màu cụ thể** | Semantic token dùng `text/primary`, **không** dùng `text/dark-blue` |
| **Không dùng giá trị trong tên** | Dùng `radius/button`, **không** dùng `radius/24px` |
| **Số trong Primitive** | Primitive dùng số: `fontSize/16`, `space/8`, `greyscale/500` |
| **Ngữ nghĩa trong Semantic** | Semantic dùng mô tả ý nghĩa: `type/body`, `inset/md` |

### ✅ Do — Nên làm

```
✅ button/primary-bg      → alias tới semantic/bg/brand
✅ text/primary           → alias tới primitive/greyscale/900
✅ radius/button          → alias tới primitive/radius/2xl
✅ status/info-default    → alias tới primitive/info/500
✅ AXQ / Semantic / Color → naming collection đúng chuẩn
```

### ❌ Don't — Không nên làm

```
❌ button/black           → dùng tên màu thay vì ngữ nghĩa
❌ button/bg → info/500   → skip layer Semantic, trỏ thẳng về Primitive
❌ text-primary           → thiếu phân cấp `/`
❌ Radius24               → dùng giá trị số trong tên Semantic
❌ Semantic / Color       → thiếu prefix AXQ /
❌ button/hover           → đặt trạng thái vào collection thay vì variant
```

### Token Chain Rule

```
Component token
    └── trỏ tới Semantic token
            └── trỏ tới Primitive token
                        └── giá trị thô (hex, px)
```

> **Không bao giờ** component trỏ trực tiếp tới primitive. Chain phải qua đủ 3 tầng.

---

## Quy Trình Thiết Lập Variable System trong Figma

### Bước 1 — Tạo 7 Collections

Mở bảng **Variables** (`Ctrl/Cmd + L`) → tạo tuần tự:

```
AXQ / Primitive / Color           [mode: Value]
AXQ / Primitive / Spacing         [mode: Value]
AXQ / Primitive / Radius          [mode: Value]
AXQ / Primitive / Font Size       [mode: Value]
AXQ / Semantic / Color            [mode: Light, Dark]
AXQ / Semantic / Spacing+Radius   [mode: Default]
AXQ / Component                   [mode: Default]
```

### Bước 2 — Khai báo Primitive

Nhập toàn bộ giá trị thô. **Không** alias sang collection khác ở bước này.

- Type `Color` → nhập hex
- Type `Number` → nhập giá trị px (không kèm đơn vị)

### Bước 3 — Semantic aliases từ Primitive

Chuột phải vào ô value → **"Apply alias"** → chọn Primitive token.

```
text/primary       →  AXQ / Primitive / Color / greyscale/900
bg/brand           →  AXQ / Primitive / Color / black
border/focus       →  AXQ / Primitive / Color / info/500
radius/button      →  AXQ / Primitive / Radius / 2xl
type/body          →  AXQ / Primitive / Font Size / 16
```

### Bước 4 — Semantic Color Dark Mode

Trong collection `AXQ / Semantic / Color`:
1. Click **+ Mode** → đặt tên **Dark**
2. Override các giá trị: `text/primary = #F4F5F7`, `bg/primary = #121318`, ...
3. Kiểm tra bằng cách chọn frame → đổi mode sang Dark trong panel Variables

### Bước 5 — Component tokens từ Semantic

```
button/primary-bg   →  AXQ / Semantic / Color / bg/brand
input/border-focus  →  AXQ / Semantic / Color / border/focus
card/radius         →  AXQ / Semantic / Spacing+Radius / radius/card
```

### Bước 6 — Gán Variable vào Master Components

1. Chọn layer fill/stroke → click **⬥ biểu tượng Variable** (góc phải ô màu)
2. Chọn token Component tương ứng
3. Kiểm tra: chọn frame cha → đổi mode Light/Dark → component phải cập nhật

### Bước 7 — Publish Library

1. **Assets panel** → ☁ **Publish** → tick *Variables*
2. Các file dùng chung sẽ nhận update qua **"Update to latest"**

---

> **Lưu ý naming convention AXQ:** Tất cả collection đặt prefix `AXQ /` để phân biệt với các library khác trong cùng file.  
> Ví dụ: `AXQ / Primitive / Color` · `AXQ / Semantic / Color` · `AXQ / Component`
>
> **Phiên bản:** v1.1 — mở rộng từ v1.0 với Dark Mode, status scale đầy đủ, 3 component mới, CSS output, JSON export, naming rules.

---

*AXQ Design System — Variable Token Architecture v1.1*
