---

# BẢN MÔ TẢ ĐẶC TÍNH KỸ THUẬT PHẦN MỀM
# SOFTWARE TECHNICAL SPECIFICATION DECLARATION

**Dùng cho mục đích:** Đăng ký bản quyền tác giả phần mềm tại Cục Sở hữu Trí tuệ Việt Nam  
*(Pursuant to: Luật Sở hữu trí tuệ Việt Nam 2005, sửa đổi 2009, 2019, 2022 — Điều 22, 23)*

---

## PHẦN I: THÔNG TIN TÁC GIẢ / AUTHOR INFORMATION

| Mục | Thông tin |
|-----|-----------|
| **Tên tác giả / Author name** | TRẦN ĐỨC NHÂN |
| **Quốc tịch / Nationality** | Việt Nam |
| **Địa chỉ / Address** | 16A/11/20 Nguyễn Tuyển, Bình Trưng Tây, TP. Thủ Đức, TP.HCM |
| **Số CCCD** | *(điền tay khi ký trước công chứng)* |
| **Email liên hệ kỹ thuật** | core@axqprotocol.axq |

**Tư cách pháp nhân / Legal capacity:** Tác giả đồng thời là chủ sở hữu quyền tác giả (tự sáng tác, không theo hợp đồng thuê viết).

---

## PHẦN II: MÔ TẢ PHẦN MỀM / SOFTWARE DESCRIPTION

### 2.1 Tên phần mềm

| Ngôn ngữ | Tên |
|---------|-----|
| Tiếng Việt | **Hệ sinh thái Giao thức Sổ cái AXIOLEDGER** |
| Tiếng Anh | **AXIOLEDGER Protocol Ecosystem** |
| Tên thương mại | AXIOLEDGER (`$AXQ`) |

### 2.2 Phiên bản đăng ký / Version

- **Phiên bản:** 2.0.0  
- **Ngày hoàn thành phiên bản:** 2026-09-02  
- **Ngôn ngữ lập trình chính:** Solidity (^0.8.28), TypeScript, JavaScript (Node.js), Rust (dự kiến Phase 5)  
- **Quy mô:** 500.000 dòng mã (Lines of Code — LOC), phân bố trên 14 workspace

### 2.3 Loại phần mềm / Software type

Phần mềm máy tính thuộc loại **Giao thức tài chính phi tập trung và hệ thống sổ cái phân tán** (Decentralized Finance Protocol & Distributed Ledger System), bao gồm:

- Hợp đồng thông minh (Smart Contracts) trên nền tảng EVM-compatible blockchain
- Daemon thu thập và xác thực dữ liệu giá (Oracle Price Feed Node)
- Thư viện SDK TypeScript dành cho nhà phát triển
- Giao diện người dùng Web3 (DEX Frontend, Governance UI, Passkey Wallet)
- Mạch chứng minh không tiết lộ thông tin (ZK-Proof Circuits) — Phase 5

---

## PHẦN III: KIẾN TRÚC KỸ THUẬT / TECHNICAL ARCHITECTURE

### 3.1 Mô hình "1 Hub & 4 Pillars"

```
AXIOLEDGER ECOSYSTEM (500.000 LOC)
│
├── HUB: Axioledger ($AXQ) — ~50.000 LOC
│   ├── AXQToken.sol          — ERC-20, 500 tỷ $AXQ, genesis allocation
│   ├── AXQGovernance.sol     — DAO Quadratic Voting + Guardian Council
│   └── ANSRegistry.sol       — Đăng ký tên miền .axq/.vpx/.sqx/.kpx/.vrq
│
├── PILLAR 1: Valiprecision ($VPX) — ~120.000 LOC
│   ├── oracle-node.js        — Daemon cron 60 giây
│   ├── price-feed.js         — Tổng hợp giá median từ 3 nguồn CEX
│   ├── on-chain-pusher.js    — Đẩy giá lên chuỗi, retry, heartbeat
│   └── VPXOracleFeed.sol     — Hợp đồng nhận và lưu trữ giá on-chain
│
├── PILLAR 2: Sequentichain ($SQX) — ~150.000 LOC
│   └── [Phase 5 — đang đóng băng]
│
├── PILLAR 3: Kinetoprotocol ($KPX) — ~80.000 LOC
│   ├── KPXRouterGateway.sol  — AMM Router với gasless swap
│   ├── IVRQVerifier.sol      — Interface xác thực ZK-Proof
│   └── IKPXDarkPool.sol      — Interface Dark Pool tổ chức
│
└── PILLAR 4: Veraciphers ($VRQ) — ~100.000 LOC
    ├── VRQPasskeyValidator.sol — ERC-7579 Passkey validator
    ├── axio-design-system/   — Thư viện UI WCAG AA (npm package)
    └── [ZK-Circuits — Phase 5]
```

### 3.2 Các thuật toán và phương pháp kỹ thuật độc đáo

#### a) Quadratic Voting (Bỏ phiếu Bậc hai)
Số phiếu bầu = √(số token sở hữu). Chống thao túng bởi "cá voi" (whale). Được cài đặt trong `AXQGovernance.sol`, hàm `castVote()`, sử dụng thuật toán Babylonian integer square root.

#### b) Median Price Aggregation (Tổng hợp giá theo Trung vị)
Thu thập giá từ 3 nguồn độc lập (Binance, CoinGecko, Kraken), tính trung vị (median) thay vì trung bình (mean). Kẻ tấn công phải kiểm soát >50% nguồn mới có thể thao túng giá. Ngưỡng sai lệch tối đa: 2%.

#### c) ANS Namespace System (Hệ thống Tên miền phi tập trung)
5 TLD độc quyền (`.axq`, `.vpx`, `.sqx`, `.kpx`, `.vrq`) được đăng ký trên hợp đồng `ANSRegistry.sol`. Tên miền = Smart Account Address, hỗ trợ Account Abstraction (ERC-4337).

#### d) PKI Internal Chain of Trust (Chuỗi tin cậy PKI nội bộ)
Root CA RSA-4096 ký 5 Intermediate CA tương ứng 5 trụ cột, cấp phát chứng chỉ TLS cho các tên miền ANS. Chuỗi tin cậy độc lập, không phụ thuộc CA công khai.

#### e) Gasless Swap via EIP-2771 Meta-Transaction
`KPXRouterGateway.sol` hỗ trợ giao dịch hoán đổi token không cần ETH (gasless) thông qua cơ chế Relayer và EIP-2771 trusted forwarder.

### 3.3 Hệ thống kiểm soát phiên bản và bằng chứng xuất xứ

| Bằng chứng | Mô tả |
|-----------|-------|
| **Git Repository** | github.com/axioledger/axioledger (public, timestamp bất biến) |
| **Genesis Commit** | 2026-08-31T09:41:34Z — khối đầu tiên của monorepo |
| **PKI Root CA** | SHA-256: `01:5D:37:79:B6:33:AC:2B:…:95:9A:F9` (xem Phụ lục A) |
| **GPG Signing Key** | `D19C5C5D42834783A67EB8E1B1EE6B2116DA203D` |
| **identity-declaration.json** | Chữ ký RSA-SHA256 xác minh: `Verified OK` |

---

## PHẦN IV: TUYÊN BỐ TÍNH NGUYÊN GỐC / ORIGINALITY STATEMENT

Tôi, **TRẦN ĐỨC NHÂN**, tuyên bố rằng:

1. Toàn bộ mã nguồn của Hệ sinh thái AXIOLEDGER được sáng tác **độc lập**, không sao chép từ bất kỳ phần mềm độc quyền nào.
2. Các thư viện mã nguồn mở được sử dụng (OpenZeppelin, ethers.js, Next.js, v.v.) đều có giấy phép tương thích (MIT/Apache-2.0) và được ghi nhận đầy đủ.
3. Kiến trúc "1 Hub & 4 Pillars", hệ thống ANS 5-TLD, và mô hình Tokenomics 500 tỷ $AXQ là **sáng kiến độc bản** của tác giả.
4. Định giá IP lõi ước tính: **10.000.000.000.000 VNĐ** (mười nghìn tỷ đồng).

---

## PHỤ LỤC A: DẤU VÂN TAY MẬT MÃ HỌC

*(Đính kèm file `identity-declaration.json` đã ký số từ repository)*

| Thành phần | SHA-256 Fingerprint |
|-----------|---------------------|
| Root CA | `01:5D:37:79:B6:33:AC:2B:19:CF:49:22:42:22:AD:B9:A8:74:1E:CA:04:57:3D:4F:A6:F1:B1:E0:FF:95:9A:F9` |
| AXQ Intermediate CA | `88:AD:EA:0D:64:0D:35:11:60:E1:76:FE:81:AE:75:3E:95:AD:42:1A:1C:EB:48:BA:27:C0:BF:AC:5F:26:C0:AB` |
| VPX Intermediate CA | `FC:DF:EA:02:0C:3B:80:F2:70:35:DF:8C:79:0F:F4:41:5F:3D:45:95:77:3D:AF:DA:C5:F5:23:EF:29:1F:A8:48` |
| SQX Intermediate CA | `89:FA:65:81:E7:27:14:B3:2C:53:B6:84:E8:85:72:E0:BE:85:CF:68:65:C3:02:EE:C6:00:EB:71:41:C2:DB:C5` |
| KPX Intermediate CA | `7F:B4:00:2F:2B:FE:17:37:98:25:26:55:BA:92:8B:0E:68:68:D5:A8:66:90:8D:06:66:67:C0:0A:BA:B4:F1:B1` |
| VRQ Intermediate CA | `75:4F:2E:EB:F9:32:CA:BF:62:87:EF:F0:96:7F:3A:EB:F3:A2:A1:E7:20:B0:EB:F7:0C:48:FA:81:2B:A7:E3:F2` |

---

*Tài liệu này được soạn thảo để sử dụng làm phụ lục kỹ thuật trong hồ sơ đăng ký bản quyền phần mềm. Cần có chữ ký tươi của tác giả và công chứng viên khi nộp cho cơ quan nhà nước.*
