---

# TUYÊN THỆ TÁC GIẢ
# AFFIDAVIT OF AUTHORSHIP

**Số hiệu hồ sơ / File No.:** ___________________________  
**Ngày lập / Date:** ___________________________

---

## CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM
## SOCIALIST REPUBLIC OF VIETNAM

*Tài liệu này được lập theo quy định của Bộ luật Dân sự Việt Nam 2015 và Luật Sở hữu Trí tuệ 2005 (sửa đổi 2022), nhằm thiết lập bằng chứng về quyền tác giả đối với phần mềm máy tính.*

*This document is prepared pursuant to the Civil Code of Vietnam 2015 and the Intellectual Property Law 2005 (amended 2022), establishing authorship evidence for computer software.*

---

## PHẦN I: NHÂN THÂN TÁC GIẢ / AUTHOR IDENTITY

Tôi, người ký tên dưới đây:

| | Tiếng Việt | English |
|--|-----------|---------|
| **Họ và tên / Full name** | TRẦN ĐỨC NHÂN | TRAN DUC NHAN |
| **Ngày sinh / Date of birth** | 19/05/1976 | May 19, 1976 |
| **Quốc tịch / Nationality** | Việt Nam | Vietnamese |
| **Số CCCD / National ID No.** | *(điền tay + đính kèm bản sao công chứng)* | *(fill by hand)* |
| **Địa chỉ / Address** | 16A/11/20 Nguyễn Tuyển, Bình Trưng Tây, TP.Thủ Đức, TP.HCM | Same |
| **Email kỹ thuật / Technical contact** | core@axqprotocol.axq | same |

---

## PHẦN II: TUYÊN BỐ / DECLARATIONS

Với nhận thức đầy đủ về trách nhiệm pháp lý, tôi **TRẦN ĐỨC NHÂN** xin tuyên thệ những điều sau:

### Điều 1 — Quyền Tác Giả Độc Lập

Tôi là **tác giả duy nhất và chủ sở hữu** của toàn bộ hệ sinh thái phần mềm mang tên **AXIOLEDGER Ecosystem** (phiên bản 2.0.0), bao gồm toàn bộ mã nguồn, kiến trúc hệ thống, tài liệu đặc tả kỹ thuật và tài liệu thiết kế liên quan, với tổng quy mô ước tính **500.000 dòng mã (Lines of Code)**.

Phần mềm này được sáng tác từ ngày **2026-08-28** và đạt phiên bản hoàn chỉnh vào ngày **2026-09-02**.

### Điều 2 — Tính Nguyên Gốc (Clean-Room Engineering)

Tôi tuyên bố rằng:

- (a) Toàn bộ mã nguồn lõi được viết **độc lập**, không sao chép từ phần mềm độc quyền của bên thứ ba.
- (b) Các thư viện nguồn mở được sử dụng đều được **ghi nhận đầy đủ** và có giấy phép tương thích (MIT, Apache-2.0, BSD).
- (c) Kiến trúc "**1 Hub & 4 Pillars**", hệ thống tên miền ANS với 5 TLD (`.axq`, `.vpx`, `.sqx`, `.kpx`, `.vrq`), thuật toán **Quadratic Voting**, và mô hình Tokenomics 500 tỷ `$AXQ` là **sáng kiến độc bản** của tôi.

### Điều 3 — Bằng Chứng Mật Mã Học (Cryptographic Proof)

Tôi kiểm soát và nắm giữ **độc quyền** các khóa mật mã sau, đóng vai trò bằng chứng kỹ thuật số về quyền sở hữu:

**3.1 Khóa GPG (Code Signing)**

```
Key ID      : B1EE6B2116DA203D
Fingerprint : D19C5C5D 42834783 A67EB8E1 B1EE6B21 16DA203D
UID         : Axioledger Core (Axioledger Core Protocol Inc.)
              <core@axqprotocol.axq>
Algorithm   : ed25519 (Edwards-curve Digital Signature Algorithm)
Created     : 2026-08-28
```

**3.2 Khóa PKI Root CA (Infrastructure Authority)**

```
Subject     : /C=VN/ST=Hanoi/L=Hanoi/O=Axioledger Foundation
              /OU=Core Settlement Hub/CN=Axioledger Root CA
Serial      : 4E9AF158A110D804F7BD69E32E0FAF1EB4DBDB6A
SHA-256     : 01:5D:37:79:B6:33:AC:2B:19:CF:49:22:42:22:AD:B9:
              A8:74:1E:CA:04:57:3D:4F:A6:F1:B1:E0:FF:95:9A:F9
Algorithm   : RSA-4096 (self-signed)
Valid Until : 2036-08-28
```

**3.3 SHA-256 của Tuyên Bố Định Danh (Document Hash)**

```
File    : identity-declaration.json
SHA-256 : ed67a1f2833f3c6c73237f0aefa6812faf1976efcf3249ecc37868599f268870
Signed  : RSA-SHA256 với Root CA private key — kết quả: "Verified OK"
Location: https://github.com/axioledger/axioledger/blob/main/identity-declaration.json
```

### Điều 4 — Bằng Chứng Lịch Sử Triển Khai

Các hợp đồng thông minh sau đã được triển khai công khai trên mạng Sepolia Testnet, chứng minh năng lực kỹ thuật thực tế:

| Hợp đồng | Mạng | Trạng thái |
|----------|------|-----------|
| `VRQPasskeyValidator` — ERC-7579 Passkey validator | Ethereum Sepolia | ✅ Đã triển khai |
| `KPXRouterGateway` — AMM Router gasless swap | Ethereum Sepolia | ✅ Đã triển khai |
| `VPXOracleFeed` — Hợp đồng Oracle giá tài sản | Ethereum Sepolia | ✅ Đã triển khai |

Broadcast logs và địa chỉ hợp đồng được lưu tại:  
`https://github.com/axioledger/axioledger/tree/main/core/contracts`

### Điều 5 — Cam Kết Bảo Mật Tài Sản Trí Tuệ

Tôi cam kết:

- Lưu trữ khóa bí mật Root CA RSA-4096 trong **môi trường ngoại tuyến (Cold Storage / HSM)**.
- Áp dụng **giấy phép BSL-1.1** cho mã nguồn lõi nhằm bảo vệ tài sản trí tuệ khỏi khai thác thương mại trái phép.
- Không chuyển nhượng quyền tác giả mà không có văn bản pháp lý có chữ ký đầy đủ.

---

## PHẦN III: XÁC NHẬN / ATTESTATION

Tôi xin cam kết rằng tất cả những điều khai báo ở trên là **đúng sự thật**. Tôi hiểu rằng khai báo gian dối về quyền sở hữu trí tuệ là hành vi vi phạm pháp luật và có thể bị xử lý theo Điều 170, 171 Bộ luật Hình sự Việt Nam.

---

**Ký tên / Signature:**

&nbsp;

&nbsp;

___________________________________  
**TRẦN ĐỨC NHÂN**  
Ngày ký / Date: ___________________________  
Địa điểm / Place: ___________________________

---

**XÁC NHẬN CỦA CÔNG CHỨNG VIÊN / NOTARY ATTESTATION:**

Tôi, _________________________________________, là Công chứng viên tại _________________________________________, xác nhận rằng **TRẦN ĐỨC NHÂN** đã ký tên trước mặt tôi vào ngày _______________ và đã xuất trình Căn cước Công dân số *(không ghi vào đây — lưu trong hồ sơ công chứng riêng)*.

Công chứng viên / Notary: ___________________________  
Số công chứng / Notary No.: ___________________________  
Ngày / Date: ___________________________  
Con dấu / Seal: *(đóng dấu tại đây)*

---

## PHỤ LỤC / ANNEXES

- **Phụ lục A:** Bản in `identity-declaration.json` (có chữ ký số RSA-SHA256)
- **Phụ lục B:** Bản Mô Tả Đặc Tính Kỹ Thuật Phần Mềm (`SOFTWARE-TECHNICAL-SPEC.md`)
- **Phụ lục C:** Bản sao công chứng CCCD của tác giả *(lưu riêng, không đính kèm bản số)*
- **Phụ lục D:** Screenshot lịch sử commit GitHub (proof of creation timeline)
- **Phụ lục E:** Giấy phép BSL-1.1 (`LICENSE` trong repository)

---

*Tài liệu này được soạn thảo theo tiêu chuẩn để nộp cho:*  
*(1) Cục Sở hữu Trí tuệ Việt Nam — 386 Nguyễn Trãi, Thanh Xuân, Hà Nội*  
*(2) Văn phòng Bản quyền tác giả — Cục Bản quyền tác giả, Bộ Văn hóa, Thể thao và Du lịch*  
*(3) WIPO — World Intellectual Property Organization (tùy chọn — qua luật sư quốc tế)*
