# Cấu hình Thông tin Tác giả / Author Configuration

Tài liệu `SOFTWARE-TECHNICAL-SPEC.md` sử dụng biến cấu hình để cho phép người fork tự điền
thông tin tác giả của mình mà không cần sửa trực tiếp vào nội dung tài liệu kỹ thuật.

---

## Cách 1 — File `author.config.json` (khuyến nghị)

Tạo file `author.config.json` tại thư mục gốc của repo (đã có trong `.gitignore` — không commit lên Git):

```json
{
  "API_AUTHOR_NAME":        "Họ và Tên Đầy Đủ",
  "API_AUTHOR_NATIONALITY": "Việt Nam",
  "API_AUTHOR_ADDRESS":     "Số nhà, Đường, Phường/Xã, Quận/Huyện, Tỉnh/TP",
  "API_AUTHOR_ID_NUMBER":   "0123456789xx",
  "API_AUTHOR_EMAIL":       "email@domain.com"
}
```

> ⚠️ **Không commit `author.config.json` lên Git.** File này chứa thông tin cá nhân.
> Thêm dòng `author.config.json` vào `.gitignore` nếu chưa có.

---

## Cách 2 — Biến môi trường `.env`

Khai báo trong file `.env` tại thư mục gốc (cũng đã có trong `.gitignore`):

```env
API_AUTHOR_NAME=Họ và Tên Đầy Đủ
API_AUTHOR_NATIONALITY=Việt Nam
API_AUTHOR_ADDRESS=Số nhà, Đường, Phường/Xã, Quận/Huyện, Tỉnh/TP
API_AUTHOR_ID_NUMBER=0123456789xx
API_AUTHOR_EMAIL=email@domain.com
```

---

## Sử dụng biến khi tạo tài liệu PDF / in ấn

Nếu dùng script để xuất tài liệu ra PDF hoặc điền vào form (ví dụ dùng `sed`, `envsubst`, hoặc Node.js):

```bash
# Ví dụ với envsubst (Linux/macOS)
export $(cat .env | xargs)
envsubst < docs/SOFTWARE-TECHNICAL-SPEC.md > output/SOFTWARE-TECHNICAL-SPEC-filled.md
```

```js
// Ví dụ với Node.js
const fs = require('fs');
const config = require('./author.config.json');
let doc = fs.readFileSync('docs/SOFTWARE-TECHNICAL-SPEC.md', 'utf8');
for (const [key, val] of Object.entries(config)) {
  doc = doc.replaceAll(`{${key}}`, val);
}
fs.writeFileSync('output/SOFTWARE-TECHNICAL-SPEC-filled.md', doc);
```

---

## Mô tả các biến

| Biến | Bắt buộc | Mô tả |
|------|----------|-------|
| `API_AUTHOR_NAME` | Có | Họ tên đầy đủ theo CCCD, viết HOA |
| `API_AUTHOR_NATIONALITY` | Không | Mặc định: `Việt Nam` |
| `API_AUTHOR_ADDRESS` | Có | Địa chỉ thường trú theo CCCD |
| `API_AUTHOR_ID_NUMBER` | Không | Điền tay trực tiếp khi ký bản in — **không lưu trong file** |
| `API_AUTHOR_EMAIL` | Có | Email liên hệ kỹ thuật |

---

*File này là tài liệu hướng dẫn — không chứa thông tin cá nhân và có thể commit lên Git.*
