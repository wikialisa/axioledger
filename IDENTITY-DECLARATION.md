# BẢN TUYÊN BỐ ĐỊNH DANH SỞ HỮU TRÍ TUỆ ĐỘC LẬP
# INDEPENDENT INTELLECTUAL PROPERTY IDENTITY DECLARATION

---

**Tên dự án / Project Name:** AXIOLEDGER ECOSYSTEM  
**Phiên bản / Version:** 2.0.0  
**Ngày xác lập / Declaration Date:** 2026-09-02T00:00:00Z  
**PKI Genesis:** 2026-08-31T08:09:06Z  
**Định giá IP lõi / Core IP Valuation:** 10.000.000.000.000 VNĐ (~390,000,000 USD)  
**Quy mô mã nguồn / Codebase Scale:** 500,000 LOC (Lines of Code)

---

## ĐIỀU 1 — TỔ CHỨC SỞ HỮU & PHÁP NHÂN

Bản tuyên bố này xác nhận chủ quyền sở hữu trí tuệ toàn vẹn của hệ sinh thái AXIOLEDGER theo mô hình **1 Hub & 4 Pillars**:

| Tổ chức | Token | Phạm vi | LOC |
|---------|-------|---------|-----|
| **Axioledger Foundation** (Hub) | `$AXQ` | Quản trị DAO, Treasury, Tokenomics, ANS Registry | ~50,000 |
| **Valiprecision Network Ltd.** | `$VPX` | Oracle Network, Validator Client, P2P Consensus | ~120,000 |
| **Sequentichain Infrastructure Inc.** | `$SQX` | L2 Rollup, SVM Execution, AF_XDP NIC Bypass | ~150,000 |
| **Kineto Protocol Foundation** | `$KPX` | AMM Router, Cross-chain Bridge, RWA DeFi | ~80,000 |
| **Veraciphers Cryptography Ltd.** | `$VRQ` | ZK-Circuits, DID, Passkey Wallet, Design System | ~100,000 |

---

## ĐIỀU 2 — BẰNG CHỨNG MẬT MÃ HỌC (PKI IDENTITY CHAIN)

Hệ thống PKI nội bộ tạo thành chuỗi tin cậy không thể làm giả:

### Root Certificate Authority

```
Subject : /C=VN/ST=Hanoi/L=Hanoi/O=Axioledger Foundation
          /OU=Core Settlement Hub/CN=Axioledger Root CA
Serial  : 4E9AF158A110D804F7BD69E32E0FAF1EB4DBDB6A
SHA-256 : 01:5D:37:79:B6:33:AC:2B:19:CF:49:22:42:22:AD:B9:
          A8:74:1E:CA:04:57:3D:4F:A6:F1:B1:E0:FF:95:9A:F9
Validity: 2026-08-31 → 2036-08-28 (10 năm)
Algorithm: RSA-4096 (self-signed)
```

### 5 Intermediate CAs (Ký bởi Root CA)

| Pillar | CN | Serial | SHA-256 Fingerprint |
|--------|-----|--------|---------------------|
| AXQ | Axq Hub Intermediate CA | `166B1D3A` | `88:AD:EA:0D:…:C0:AB` |
| VPX | Valiprecision Intermediate CA | `166B1D3B` | `FC:DF:EA:02:…:A8:48` |
| SQX | Sequentichain Intermediate CA | `166B1D3C` | `89:FA:65:81:…:DB:C5` |
| KPX | Kinetoprotocol Intermediate CA | `166B1D3D` | `7F:B4:00:2F:…:F1:B1` |
| VRQ | Veraciphers Intermediate CA | `166B1D3E` | `75:4F:2E:EB:…:E3:F2` |

*(Chi tiết đầy đủ tại [`identity-declaration.json`](./identity-declaration.json))*

### GPG Code Signing Key

```
Key ID   : B1EE6B2116DA203D
Fingerprint: D19C5C5D 42834783 A67EB8E1 B1EE6B21 16DA203D
UID      : Axioledger Core (Axioledger Core Protocol Inc.)
           <core@axqprotocol.axq>
Algorithm: ed25519
Created  : 2026-08-28
```

### Chữ ký số tệp tuyên bố / Document Digital Signature

Tệp `identity-declaration.json` đã được ký bằng **RSA-SHA256** với khóa bí mật Root CA (RSA-4096):

```bash
# Xác minh chữ ký / Verify signature:
openssl dgst -sha256 \
  -verify <(openssl x509 -in ssl/pki/ca/axioledger-root-ca.crt -pubkey -noout) \
  -signature <(python3 -c "import json,base64,sys; \
    d=json.load(open('identity-declaration.json')); \
    sys.stdout.buffer.write(base64.b64decode(d['_proof']['signature_base64']))") \
  <(python3 -c "import json; d=json.load(open('identity-declaration.json')); \
    del d['_proof']; print(json.dumps(d,indent=2,ensure_ascii=False),end='')")
# Output: Verified OK
```

---

## ĐIỀU 3 — CẤP PHÉP MÃ NGUỒN (LICENSING MATRIX)

| Lớp | Giấy phép | Phạm vi |
|-----|-----------|---------|
| Core Protocol (`smart-contracts/`, `core-nodes/`) | **BSL-1.1** | Mã nguồn mở có điều kiện — yêu cầu giấy phép thương mại cho sản phẩm thương mại |
| Public SDKs (`packages/axq-sdk`, `packages/ans-resolver`) | **MIT** | Tự do sử dụng, kể cả thương mại |
| Public Libraries (`packages/evm-interop`, `packages/zkp-crypto-lib`) | **Apache-2.0** | Tự do sử dụng với ghi nhận tác giả |
| Applications (`apps/`) | **AGPL-3.0** | Mã nguồn mở, yêu cầu công khai mã nguồn fork |

**BSL Change Date:** 4 năm sau mỗi phiên bản phát hành → chuyển sang Apache-2.0.

---

## ĐIỀU 4 — CAM KẾT KỸ THUẬT PHÒNG SẠCH (CLEAN-ROOM ENGINEERING)

- **Không sao chép:** Tuyệt đối không sao chép mã nguồn vi phạm bản quyền từ các dự án độc quyền.
- **Phụ thuộc mã nguồn mở:** Mọi thư viện bên thứ ba đều có giấy phép tương thích (MIT/Apache/BSD).
- **Supply Chain Security:** Mọi gói NPM đi qua `npm audit` + TruffleHog scan trước khi triển khai.
- **GPG Commit Signing:** Mọi commit tạo nên 500,000 LOC phải được ký xác thực bằng GPG key `B1EE6B2116DA203D`.

---

## ĐIỀU 5 — TRIỂN KHAI TRÊN MẠNG CÔNG KHAI (DEPLOYED EVIDENCE)

| Hợp đồng | Mạng | Trạng thái |
|----------|------|-----------|
| `VRQPasskeyValidator` (Veraciphers) | Sepolia Testnet | ✅ LIVE |
| `KPXRouterGateway` (Kinetoprotocol) | Sepolia Testnet | ✅ LIVE |
| `VPXOracleFeed` (Valiprecision) | Sepolia Testnet | ✅ LIVE |
| `AXQToken` (500B supply) | Mainnet (Phase 7) | ⏳ Pending |
| `AXQGovernance` (DAO) | Mainnet (Phase 7) | ⏳ Pending |
| `ANSRegistry` (.axq/.vpx/…) | Mainnet (Phase 7) | ⏳ Pending |

Địa chỉ triển khai Sepolia được lưu tại [`core/contracts/kpx/broadcast/`](../core/contracts/kpx/broadcast/) và [`core/contracts/vrq/broadcast/`](../core/contracts/vrq/broadcast/).

---

## ĐIỀU 6 — TOKENOMICS & QUẢN TRỊ

**Tổng cung cố định:** 500,000,000,000 $AXQ (500 tỷ, không thể mint thêm sau Genesis)

| Quỹ | % | Số lượng $AXQ | Mục đích |
|-----|---|---------------|---------|
| VPX Validator Subsidy | 25% | 125,000,000,000 | Trả thưởng Validator |
| R&D & Protocol Treasury | 30% | 150,000,000,000 | Phát triển giao thức |
| RWA Backing Reserve | 15% | 75,000,000,000 | Tài sản thực bảo chứng |
| Core Team (4-yr vest) | 12% | 60,000,000,000 | Đội ngũ sáng lập |
| Strategic Partners | 13% | 65,000,000,000 | Đối tác chiến lược |
| TGE / Public Liquidity | 5% | 25,000,000,000 | Phát hành công khai |

**DAO Governance:** Quadratic Voting (phiếu = √token) + Guardian Council (5 ghế, 4/5 veto) + Time-Lock 7 ngày.

---

## ĐIỀU 7 — TUYÊN BỐ PHÁP LÝ (LEGAL DECLARATION)

> Bản tuyên bố này là văn kiện pháp lý ràng buộc, xác lập quyền sở hữu trí tuệ toàn vẹn của hệ sinh thái AXIOLEDGER. Các dấu vân tay mật mã học (cryptographic fingerprints) trong văn kiện này là bằng chứng chống giả mạo về quyền tác giả theo luật sở hữu trí tuệ quốc tế, bao gồm Công ước Berne, Thỏa thuận TRIPS và các quy định WIPO.
>
> Mọi hành vi sử dụng thương mại trái phép đối với các thành phần được cấp phép BSL-1.1 đều bị nghiêm cấm và có thể bị xử lý theo pháp luật. Để biết thông tin về cấp phép thương mại, liên hệ: **legal@axqprotocol.axq**

---

*Văn kiện này được tạo và ký bởi: Axioledger Core Maintainer `<core@axqprotocol.axq>` | GPG: `D19C5C5D42834783A67EB8E1B1EE6B2116DA203D`*  
*Tệp máy đọc được: [`identity-declaration.json`](./identity-declaration.json)*
