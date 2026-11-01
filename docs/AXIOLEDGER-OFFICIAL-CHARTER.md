# AXIOLEDGER ($AXQ) — TÀI LIỆU ĐIỀU LỆ CHÍNH THỨC

> **Phiên bản:** 2.0 — Genesis Charter (Post-Summit Edition)
> **Phạm vi:** Khởi đầu, vận hành và tăng trưởng dài hạn của máy chủ AXIOLEDGER
> **Hiệu lực:** Ngay khi Genesis Block được biên dịch
> **Tầm nhìn:** Kiến tạo hạ tầng tài chính Web3 định chế — mục tiêu 10.000.000.000.000 Token $AXQ
> **Cập nhật:** Bổ sung Hiệp ước Đại Đồng (Genesis Pact) sau Hội nghị Thượng đỉnh Diên Hồng Kỹ thuật số

---

## MỤC LỤC

1. [Tuyên ngôn Sứ mệnh](#1-tuyên-ngôn-sứ-mệnh)
2. [Kiến trúc Hệ sinh thái: Mô hình 1 Hub & 4 Pillars](#2-kiến-trúc-hệ-sinh-thái)
3. [Công nghệ Lõi: Cơ chế Đồng thuận ZK-OBFT](#3-công-nghệ-lõi-zk-obft)
4. [Tokenomics & Động cơ Giảm phát](#4-tokenomics)
5. [Ba Trụ cột Vận hành: Vai trò, Quyền hạn & Nghĩa vụ](#5-ba-trụ-cột-vận-hành)
6. [Ma trận Phối hợp Trách nhiệm (RACI)](#6-raci-matrix)
7. [Lộ trình Thực thi 5 Giai đoạn](#7-lộ-trình-thực-thi)
8. [Sản phẩm Cốt lõi: AXIO Vault Wallet](#8-axio-vault-wallet)
9. [Khung Kiến trúc Smart Contract — KPX RWA Vault](#9-smart-contract-kpx-rwa)
10. [Giá trị Nhận được theo Từng Nhóm Stakeholder](#10-value-proposition)
11. [Cập nhật Kiến trúc V2 — Bất Tử](#11-axioledger-v2)
12. [Hội nghị Thượng đỉnh Diên Hồng & Hiệp ước Đại Đồng](#12-genesis-pact)

---

## 1. TUYÊN NGÔN SỨ MỆNH

**AXIOLEDGER ($AXQ)** không được tạo ra để cạnh tranh các tính năng nhỏ lẻ. Nó được thiết kế để **định hình lại toàn bộ cơ sở hạ tầng Web3**.

Bằng cách kết hợp ba nền tảng không thể tách rời:

- **Logic Toán học** — Thuật toán đồng thuận ZK-OBFT, phương trình bỏ phiếu Reputation-based và cơ chế phát thải có điều kiện
- **Kỹ thuật DevOps** — AF_XDP NIC Bypass, RAMDISK tối ưu I/O, đa máy khách Rust/C++, 600K+ TPS
- **Tôn chỉ Pháp luật** — ZK-DID, Regulator Gateway, Confidential Transfers, tuân thủ AML/KYC/FATF/MiCA

AXIOLEDGER là **Quốc gia Kỹ thuật số phi biên giới** — hạ tầng tài chính cốt lõi của Internet Thế hệ mới.

---

## 2. KIẾN TRÚC HỆ SINH THÁI

### Mô hình 1 Hub & 4 Pillars

```
              ┌──────────────────────────────────────────────┐
              │               AXIOLEDGER ($AXQ)              │
              │        [Tổ chức Quản trị Lõi / Hub]          │
              │  • Sổ cái bất biến, DAO & Tài chính          │
              │  • Quản lý quy chuẩn, bảo chứng và ngân quỹ  │
              │  • Hậu lượng tử: Lattice-based cryptography   │
              └──────────────────┬───────────────────────────┘
                                 │
       ┌─────────────────┬───────┴───────┬─────────────────┐
       ▼                 ▼               ▼                 ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│ VALIPRECISION│ │SEQUENTICHAIN│ │KINETOPROTOCOL│ │ VERACIPHERS │
│    ($VPX)   │ │    ($SQX)   │ │    ($KPX)   │ │    ($VRQ)   │
├─────────────┤ ├─────────────┤ ├─────────────┤ ├─────────────┤
│ Consensus & │ │ High-Speed  │ │ DeFi Engine │ │ ZK-Security │
│ Validation  │ │ L2 Execution│ │ & Liquidity │ │ & Compliance│
│             │ │             │ │             │ │             │
│ • Multi-    │ │ • SVM Rollup│ │ • AMM Pool  │ │ • ZK-Proof  │
│   client    │ │ • AF_XDP    │ │ • Cross-    │ │ • DID/KYC   │
│   Rust+C++  │ │   NIC Bypass│ │   chain     │ │ • Regulator │
│ • RAMDISK   │ │ • 600K+ TPS │ │   Bridge    │ │   Gateway   │
│   I/O       │ │ • ZK-Rollup │ │ • RWA       │ │ • Supply    │
│ • NVMe      │ │   Settlement│ │   Treasury  │ │   Chain     │
│   partitioned│ │ • <3min    │ │ • Dark Pool │ │   Scanner   │
│ • ZK-OBFT   │ │   Finality  │ │ • LP Market │ │ • Confidential│
│             │ │             │ │             │ │   Transfer  │
└─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘
```

### Phân bổ Chức năng Chi tiết

| Trụ cột | Mã Token | Chức năng Cốt lõi | Giải quyết Pain Point |
|---|---|---|---|
| **Hub** | `$AXQ` | Sổ cái quyết toán, Treasury DAO, Quản trị on-chain | Immutable Settlement, kháng lượng tử |
| **VALIPRECISION** | `$VPX` | Đồng thuận ZK-OBFT, quản lý Validator, RAMDISK | Áp lực phần cứng Solana, tập trung hoá |
| **SEQUENTICHAIN** | `$SQX` | L2 siêu tốc, SVM Rollup, AF_XDP, ZK-Settlement | Sequencer tập trung Arbitrum, độ trễ 7 ngày |
| **KINETOPROTOCOL** | `$KPX` | AMM Pool, Cross-chain Bridge, RWA Treasury, Dark Pool | Phân mảnh thanh khoản, Front-running tổ chức |
| **VERACIPHERS** | `$VRQ` | ZK-DID, KYC/AML, Supply Chain Scanner, Regulator Gateway | Ẩn danh vs Tuân thủ, Typosquatting MetaMask |

---

## 3. CÔNG NGHỆ LÕI: ZK-OBFT

### 3.1 Trọng số Bỏ phiếu theo Cống hiến (Reputation-based VP)

Quyền lực mạng lưới không nằm ở vốn đơn thuần mà bị ràng buộc bởi đóng góp kỹ thuật thực tế:

```
VP_i(t) = S_i(t) × R_i(t)

Trong đó:
  S_i(t)   = Số lượng token $VPX đã khóa
  R_i(t)   = α·U_i(t) + β·ln(1 + γ·B_i(t))
  U_i(t)   = Tỷ lệ Uptime (phạt theo cấp số nhân nếu offline)
  B_i(t)   = Băng thông thực tế đóng góp (hàm ln triệt tiêu độc quyền phần cứng)
```

### 3.2 Nén Chữ ký bằng ZK-SNARKs

Thay vì hàng triệu tin nhắn Gossip khi mạng có hàng nghìn Node:

1. Leader gom hàng nghìn chữ ký đa hình (Multi-signatures)
2. Chạy ZK-Circuit với điều kiện: `∑VP_voters > 2/3 × ∑VP_total`
3. Xuất **Bằng chứng π** siêu nhẹ (~284 bytes) — mọi node xác minh trong O(1)

### 3.3 Instant Slashing (Đao Phủ Thuật Toán)

Bất kỳ hành vi ký đúp (Double-signing) bị phát hiện:

- $VPX bị đốt **100%** trong cùng block
- Chỉ số Uy tín `R_i` về **0**
- Validator bị loại vĩnh viễn — không cần giai đoạn thử thách

### 3.4 Kháng DDoS Toán học

Nếu kẻ thù đánh sập 33% node lớn nhất:
- `U_i` của node bị tấn công lao dốc → `VP_i` bốc hơi theo hàm mũ
- Các node sống sót tái chiếm >2/3 tổng VP mới trong một Micro-epoch
- Mạng **tự chữa lành** trong vài giây — Liveness và Safety được bảo toàn

---

## 4. TOKENOMICS

> *"Đừng để 10.000 tỷ token trở thành gánh nặng, hãy biến nó thành một lỗ đen hấp thụ giá trị."*
> — Thống đốc Ngân hàng Trung ương, Hội nghị Thượng đỉnh Diên Hồng Kỹ thuật số

### Phân bổ 10.000.000.000.000 $AXQ (Phiên bản Genesis Pact)

| Phân bổ | Tỷ lệ | Cơ chế Khóa & Mục đích |
|---|---|---|
| **Thanh khoản RWA & Dự trữ Thể chế** | **30%** | Mỏ neo thanh khoản trên KPX. Tài sản đối ứng khi ngân hàng token hóa trái phiếu / chứng chỉ tiền gửi |
| **Validator & Khai thác $VPX** | **25%** | Khóa Smart Contract, trả thưởng thuật toán suy giảm logarit cho Validator trong **50 năm** |
| **Treasury DAO & Hàng hóa Công cộng** | **20%** | Quản trị on-chain 100% — tài trợ RetroPGF cho nhà phát triển hệ sinh thái và mã nguồn mở |
| **Cộng đồng & Airdrop** | **15%** | Người dùng sớm, chiến dịch mở rộng mạng lưới, thanh khoản khởi tạo |
| **Đội ngũ Cốt lõi & Đối tác** | **10%** | Vesting cliff **5 năm** — lợi ích dài hạn gắn chặt với sự sống còn của mạng lưới |

### Phương trình Phát thải Neo Giá trị (Value-Pegged Emission)

```
Emission(t) = κ · ln(1 + ΔTVL_RWA) + μ · TransactionVolume(t) − Burn(t)
```

> Nếu không có vốn RWA mới chảy vào: `ln(1) = 0` → lạm phát từ mảng RWA **dừng tự động**.
> Các hệ số κ, μ được điều chỉnh tự động bởi AI của Treasury DAO theo từng epoch.

### Động cơ Đốt Thuật toán (Deflationary Engine)

| Cơ chế | Mô tả | Tỷ lệ Đốt |
|---|---|---|
| **Gas Burn** | Mọi giao dịch trên SEQUENTICHAIN đều trả phí siêu nhỏ — 70% phí cơ sở bị đốt vĩnh viễn | **70% phí cơ sở** |
| **RWA Yield Buyback** | Smart Contract trích lợi nhuận từ RWA Treasury để mua lại $AXQ trên thị trường mở và thiêu hủy | **10% lợi nhuận RWA** |
| **Instant Slashing** | Token $VPX của Validator vi phạm double-signing bị đốt 100% | **100% bị phạt** |
| **ZK-Privacy Tax** | Mọi Confidential Transfer tại VRQ đều đốt một khoản $AXQ vĩnh viễn | Phí biến động |
| **RWA Collateral Lock** | Định chế phát hành RWA on-chain phải khóa 15% $AXQ làm bảo hiểm rủi ro | Khóa dài hạn |

### Phương trình Giảm phát Trạng thái

Lượng cung lưu hành tại thời điểm **t**, ký hiệu **S(t)**, tuân thủ phương trình vi phân:

```
S(t) = S₀ + ∫₀ᵗ (M(x) − B(x)) dx

Trong đó:
  S₀   = Cung lưu hành ban đầu (10% TGE)
  M(x) = Tốc độ đúc token thưởng Validator (hàm suy giảm logarit)
  B(x) = Tốc độ đốt từ Gas + RWA Yield Buyback + Slashing

Điểm bùng phát (Năm 3 — dự kiến):  B(x) > M(x)
→ $AXQ chính thức bước vào trạng thái GIẢM PHÁT VĨNH VIỄN
```

---

## 5. BA TRỤ CỘT VẬN HÀNH

### 5.1 Trụ cột Pháp lý & Tuân thủ (Legal / Compliance)

#### Vai trò
Định hình khung pháp lý, đảm bảo toàn bộ sản phẩm, giao dịch tài chính và luồng dữ liệu tuân thủ các quy định sở tại và quốc tế: **FATF · GDPR · ISO 27001 · MiCA · SEC · AML/KYC**. Kiểm soát rủi ro pháp lý, tranh chấp hợp đồng và bảo vệ sở hữu trí tuệ.

#### Quyền hạn

| Quyền | Phạm vi Thực thi |
|---|---|
| **Quyền Phủ quyết (Veto Power)** | Tạm dừng hoặc yêu cầu chỉnh sửa bất kỳ tính năng, luồng dữ liệu hay chiến dịch tiếp thị có nguy cơ vi phạm pháp luật |
| **Quyền Truy vấn & Kiểm toán** | Yêu cầu Dev/DevOps/Design cung cấp tài liệu kỹ thuật, Data Flow diagram và chính sách bảo mật |
| **Quyền Duyệt Điều khoản** | Phê duyệt cuối cùng cho ToS, Privacy Policy, eKYC/AML Framework và Hợp đồng đối tác |

#### Nghĩa vụ

- Cập nhật kịp thời thay đổi luật pháp, tham mưu ban giám đốc và điều chỉnh quy trình
- Xây dựng chuẩn mực: Travel Rule, STR (Suspicious Transaction Report), bảo vệ dữ liệu người dùng
- Đảm bảo **Privacy by Design** được lồng ghép ngay từ giai đoạn thiết kế, không phải vá sau
- Quản lý **Regulator Gateway** trong VRQ: chứng minh có điều kiện với hội đồng 5/7 chữ ký kiểm toán độc lập

---

### 5.2 Trụ cột Thiết kế (Design / UI·UX & Product)

#### Vai trò
Nghiên cứu, định hình trải nghiệm người dùng (UX) và giao diện trực quan (UI). Chuyển hóa các yêu cầu phức tạp của kỹ thuật và pháp lý thành giao diện đơn giản, thân thiện với người dùng cuối — cả Retail lẫn Institutional.

#### Quyền hạn

| Quyền | Phạm vi Thực thi |
|---|---|
| **UX Ownership** | Quyết định User Journey, bố cục giao diện, Design System và các phần tử tương tác |
| **Quyền Yêu cầu Chuẩn hóa** | Buộc Frontend tuân thủ đúng [`design-system/`](../design-system/README.md) — pixel-perfect, tokens, icon system |
| **Quyền Thử nghiệm** | Chủ động phỏng vấn người dùng, chạy A/B Testing để tối ưu tỷ lệ chuyển đổi |

#### Nghĩa vụ

- Đảm bảo tính minh bạch: tuyệt đối không áp dụng Dark Patterns
- Tích hợp đầy đủ điểm chạm pháp lý: nút đồng ý ToS, cảnh báo rủi ro, luồng eKYC — một cách tự nhiên
- Bàn giao tài liệu đầy đủ: [`design-system/tokens/`](../design-system/tokens/), SVG icons tại [`asset/icon/`](../asset/icon/), Design Tokens JSON
- Đảm bảo **Adaptive UI**: giao diện AXIO Vault tự thay đổi theo vai trò Retail/Institutional
- Tuân thủ **WCAG 2.1 AA**: contrast ratio, touch targets, focus ring — theo [`guidelines/accessibility.md`](../design-system/guidelines/accessibility.md)

---

### 5.3 Trụ cột Hạ tầng & Vận hành (DevOps / Infrastructure & SRE)

#### Vai trò
Xây dựng, duy trì và tối ưu hóa hạ tầng, luồng CI/CD và đảm bảo tính sẵn sàng 24/7. Thiết lập hàng rào bảo mật, giám sát hiệu năng và khắc phục sự cố.

#### Quyền hạn

| Quyền | Phạm vi Thực thi |
|---|---|
| **Environment Access Control** | Quản lý toàn bộ quyền truy cập Production, Staging và tài nguyên máy chủ |
| **Deployment Block** | Từ chối/chặn bản build không đạt tiêu chuẩn, có lỗ hổng bảo mật nghiêm trọng hoặc vi phạm cấu trúc container |
| **Quyền Cấu hình Hạ tầng** | Tự chủ lựa chọn Docker · Kubernetes · PM2 · Terraform và phân bổ tài nguyên phần cứng |

#### Nghĩa vụ

- Đảm bảo **SLA Uptime ≥ 99.9%** và Disaster Recovery Plan đã được kiểm tra
- Mã hóa dữ liệu: Data at Rest + Data in Transit; Secrets Management an toàn
- **Triển khai RAMDISK** cho State Database; NVMe chỉ lưu Ledger — theo thiết kế VPX
- **AF_XDP NIC Bypass**: cấu hình kernel-level để SQX đạt 600K+ TPS
- Duy trì **Audit Logs** đáp ứng yêu cầu kiểm toán của bộ phận Pháp lý
- Vận hành **Supply Chain Scanner** (VRQ node) giám sát DApp và thư viện npm 24/7
- Tích hợp **AI phi tập trung** vào Scanner để dự đoán hành vi mã độc, không chỉ dùng blacklist

---

## 6. RACI MATRIX

> **R** — Responsible (Người thực hiện) | **A** — Accountable (Người chịu trách nhiệm/Phê duyệt) | **C** — Consulted (Tham vấn) | **I** — Informed (Nhận thông tin)

| Hoạt động / Sản phẩm Bàn giao | Pháp lý | Thiết kế | DevOps |
|---|---|---|---|
| Thu thập Dữ liệu & eKYC người dùng | **A** | **R** | **C** |
| Xây dựng Design System / UI Kit | **I** | **A · R** | **C** |
| Triển khai CI/CD & Cấu hình Server | **I** | **I** | **A · R** |
| Ứng phó Sự cố Rò rỉ Dữ liệu | **A** | **I** | **R** |
| Phê duyệt ToS / Privacy Policy / AML | **A** | **C** | **I** |
| Ra mắt tính năng mới (Feature Launch) | **C** | **R** | **A** |
| Kiểm toán Smart Contract KPX/VRQ | **A** | **I** | **R · C** |
| Regulator Gateway — Compliance Key | **A** | **C** | **R** |
| A/B Testing & UX Research | **I** | **A · R** | **C** |
| Vận hành Supply Chain Scanner | **C** | **I** | **A · R** |
| Tokenomics & Emission Policy | **C** | **I** | **C** |
| Genesis Block & Mainnet Launch | **A** | **C** | **R** |

---

## 7. LỘ TRÌNH THỰC THI

### Giai đoạn 1 — Khởi tạo Hạt nhân & Đồng thuận (Tháng 1–6)
**Trọng tâm:** `$AXQ Hub` + `VALIPRECISION ($VPX)`

| Hoạt động | Thực thi Cốt lõi | Yêu cầu Kỹ thuật | KPI |
|---|---|---|---|
| Xây dựng Hub $AXQ | Sổ cái bất biến, Treasury DAO, mã hóa luật lạm phát | Không admin key. Quản trị 100% on-chain | — |
| Triển khai ZK-OBFT | Thuật toán đồng thuận VP=S×R, mạch ZK-SNARKs | Giảm 99% tải Gossip network | — |
| Mở rộng Validator | RAMDISK/NVMe config, VPX Subsidy Fund | Song song Rust + C++ client | **5.000 Validator độc lập, Nakamoto Coefficient > 100** |

### Giai đoạn 2 — Lớp Thực thi Siêu tốc (Tháng 7–12)
**Trọng tâm:** `SEQUENTICHAIN ($SQX)`

| Hoạt động | Thực thi Cốt lõi | Yêu cầu Kỹ thuật | KPI |
|---|---|---|---|
| Tích hợp AF_XDP | Bypass OS Linux, gói tin từ NIC thẳng vào RAM | Kernel-level network engineering | — |
| SVM Rollup | Máy ảo Solana trên môi trường Rollup, xử lý song song | Tương thích Rust/C/C++ smart contract | — |
| ZK Settlement | Triệu giao dịch SQX → 1 ZK proof → Hub AXQ | Finality < 3 phút | **Testnet: 600.000+ TPS** |

### Giai đoạn 3 — Thanh khoản & Dòng vốn Thể chế (Năm 2)
**Trọng tâm:** `KINETOPROTOCOL ($KPX)` + `RWA Treasury`

| Hoạt động | Thực thi Cốt lõi | Yêu cầu Kỹ thuật | KPI |
|---|---|---|---|
| Cross-chain Bridge | Cầu nối phi tập trung hút thanh khoản từ ETH/ARB/SOL | Anti-slippage routing | — |
| RWA Treasury | Token hóa Trái phiếu, Chứng chỉ tiền gửi | Tuân thủ kiểm toán tài chính quốc tế | — |
| AXIO Dark Pool | Hồ bơi thanh khoản ẩn cho Block Trades thể chế | MPC + ZK-Rollup | **TVL: $10B · 3 ngân hàng/quỹ ký kết** |

### Giai đoạn 4 — Bảo mật ZK, Định danh & UX (Năm 3)
**Trọng tâm:** `VERACIPHERS ($VRQ)` + `AXIO Vault`

| Hoạt động | Thực thi Cốt lõi | Yêu cầu Kỹ thuật | KPI |
|---|---|---|---|
| ZK-DID & KYC | Danh tính số ẩn danh, xác thực định chế qua ZK | Verify không phơi bày dữ liệu cá nhân | — |
| Regulator Gateway | Compliance Key 5/7 multisig, chứng minh có điều kiện | Hội đồng kiểm toán độc lập | — |
| AXIO Vault (Gasless) | Ví Web3 chuẩn Web2, không seed phrase | Native Account Abstraction | — |
| Supply Chain Scanner | Node VRQ giám sát DApp/npm, AI dự đoán mã độc | Block 100% Typosquatting/Phishing | **100M ví · 0 hack do lộ Private Key** |

### Giai đoạn 5 — Kỷ nguyên Đồng hóa Vĩ mô (Năm 4–5)
**Trọng tâm:** Toàn bộ hệ sinh thái

| Hoạt động | Thực thi Cốt lõi | Bệ phóng Lõi |
|---|---|---|
| Sovereign Debt Tokenization | Ký kết Ngân hàng Trung ương, token hóa nợ chính phủ | Chấp thuận từ Pháp chế + Thanh khoản TradFi |
| AXIO-OS | Tích hợp Vault vào hệ điều hành điện thoại | Secure Enclave + ZK-DID hardware |
| AI Quản trị Phi tập trung | AI quản lý Supply Chain Scanner + tối ưu Treasury DAO | Năng lực xử lý Q-Oracle |
| **ENDGAME** | 100% giao dịch thương mại/chứng khoán/BĐS qua AXIOLEDGER với phí <$0.0001 | Đồng thuận 8 Cố vấn + 1 Hub 4 Pillars |

---

## 8. AXIO VAULT WALLET

**Khẩu hiệu:** *"Trải nghiệm Web2 – Sức mạnh Web3 – Bảo mật Toán học"*

### Kiến trúc Lõi

| Nguyên tắc | Thực thi |
|---|---|
| **Kế thừa MetaMask** | Tái sử dụng provider/Extension chuẩn — tương thích 100% DApp không cần viết lại code |
| **Lõi AXIOLEDGER** | 4 Pillars (VPX/SQX/KPX/VRQ) tích hợp thẳng vào Backend layer |
| **Xóa bỏ UX Barriers** | Không bắt buộc Seed Phrase · Gasless bằng stablecoin · Tự động chặn mã độc |

### Phân tầng Vai trò Giao diện (Adaptive UI)

**Retail (Cá nhân):**
- Đăng nhập: Email / Google / Apple ID / Số điện thoại — MPC chia nhỏ Private Key
- Gasless: Phí trả bằng USDT/USDC hoặc tài trợ 100% bởi DApp (Paymaster)
- Social Recovery: FaceID hoặc xác nhận từ 3 người bạn thân

**Institutional (Tổ chức):**
- Multi-sig tích hợp: Mọi lệnh trên X USD phải có ≥ 2/3 chữ ký phê duyệt
- Confidential Transfer: Ẩn số dư bằng ZK-Proofs ($VRQ)
- RWA Management: Giao diện tương tác trực tiếp với KPX RWA Treasury

### Luồng Giao dịch

```
[BẮT ĐẦU DAPP]
      │
      ▼
[KẾT NỐI AXIO VAULT]
      ├─► (Retail)  ──► Đăng nhập Google/FaceID ──► Khởi tạo Smart Contract Wallet (ngầm)
      └─► (Pro)     ──► Seed Phrase / Hardware Wallet (Ledger)
      │
      ▼
[BỘ QUÉT VRQ — SUPPLY CHAIN SCANNER]
      ├─► Mã độc/Typosquatting ──► [BLOCK & CẢNH BÁO ĐỎ]
      └─► Hợp đồng an toàn    ──► Tiếp tục
      │
      ▼
[YÊU CẦU GIAO DỊCH]
      ├─► Retail:      Pop-up "Phí: 0.01 USDC" → FaceID → Xác nhận
      └─► Institutional: ZK-DID check → Multi-sig 3 GĐ → Confidential Transfer
      │
      ▼
[SEQUENTICHAIN $SQX — 600K TPS, AF_XDP]
      │ Gộp Approve + Transfer thành 1 lệnh nguyên tử
      ▼
[HUB $AXQ — ZK-Rollup Settlement]
      │ Chốt sổ vĩnh viễn trên Sổ cái
      ▼
[THÀNH CÔNG] ──► Cập nhật số dư Real-time
```

### Native Account Abstraction (Logic Hợp đồng)

1. **Validation Phase:** Kiểm tra chữ ký (ECDSA / WebAuthn FaceID / Multisig) + Session Key
2. **Paymaster Phase:** Hợp đồng Paymaster chuyển đổi USDT → AXQ/ETH để trả phí mạng
3. **Execution Phase:** Approve + Swap gộp thành 1 Atomic Transaction — hoặc thành công cả hai, hoặc rollback toàn bộ

---

## 9. SMART CONTRACT KPX RWA — KIẾN TRÚC RUST

Lớp SEQUENTICHAIN dùng SVM nên Smart Contract viết bằng **Rust (Anchor framework)**:

### Định nghĩa Trạng thái

```rust
use anchor_lang::prelude::*;

declare_id!("KpxRwaVault11111111111111111111111111111111");

#[account]
pub struct RwaInstitutionVault {
    pub institution_pubkey: Pubkey,
    pub total_rwa_value_usd: u64,  // Tổng giá trị tài sản thực (Oracle)
    pub locked_axq_amount: u64,    // Tổng $AXQ đã khóa làm bảo chứng
    pub zk_did_hash: [u8; 32],     // ZK-KYC từ VRQ (không lộ danh tính)
    pub is_active: bool,
}
```

### Quy trình Thế chấp RWA

```
ZK-DID Verify (VRQ) → Định giá RWA (Oracle) → Tính 15% $AXQ Collateral
→ Chuyển $AXQ vào Vault → Cập nhật Sổ cái → Kích hoạt Emission (AXQ Hub)
```

### Cơ chế Lỗi (Error Codes)

| Code | Thông báo |
|---|---|
| `InvalidComplianceProof` | Bằng chứng ZK-DID không hợp lệ hoặc đã bị thu hồi bởi cơ quan pháp lý |
| `InsufficientCollateral` | Số dư $AXQ không đủ để đáp ứng tỷ lệ bảo chứng 15% |

### Synergy Xuyên Trụ cột

```
KPX (deposit_rwa_and_lock_axq)
  └─► Gọi VRQ (vrq_interface::verify_zk_did)       — Xác thực danh tính
  └─► Gọi AXQ Hub (axq_hub::trigger_emission)       — Điều tiết lạm phát
  └─► Oracle (oracle::get_axq_price)                 — Giá thời gian thực
```

---

## 10. VALUE PROPOSITION

### Giá trị theo Từng Nhóm Stakeholder

| Nhóm | Giá trị Nhận được |
|---|---|
| **Chính phủ & Ủy ban (Regulators)** | Mạng phi tập trung nhưng tuân thủ AML/KYC tuyệt đối qua ZK-DID. Giám sát dòng tiền RWA vĩ mô mà không vi phạm quyền riêng tư cá nhân |
| **Định chế Tài chính (Institutions/VCs)** | 600K TPS không trượt giá, Confidential Transfer ẩn giao dịch nội bộ, Dark Pool không bị Front-running — mở cánh cửa giao dịch trái phiếu/cổ phiếu on-chain an toàn nhất lịch sử |
| **Validators (Cộng đồng IT & DevOps)** | Phần thưởng từ VPX Subsidy Fund. Phần cứng tầm trung (nhờ RAMDISK) đủ chạy Node — thu về $VPX + $AXQ |
| **Người dùng Phổ thông (Retail)** | Dùng AXIO Vault như MoMo/Apple Pay. Phí bằng stablecoin. Không cần nhớ Seed Phrase. Không thể bị hack do lộ Private Key |
| **Nhà phát triển DApp** | Tương thích MetaMask ngay lập tức. Session Keys giảm friction UX. Supply Chain Scanner bảo vệ người dùng của họ |
| **5 Cố vấn (Blockchain Tiền nhiệm)** | Lý tưởng công nghệ của họ được hiện thực hoá hoàn hảo, không mang theo "di sản lỗi" |

---

## 11. AXIOLEDGER V2 — BẤT TỬ

Tiếp thu yêu cầu từ 3 Quyền lực Ngoại vi (Pháp chế · TradFi · An ninh Lượng tử):

### Cập nhật tại VERACIPHERS ($VRQ)
**Regulator Gateway — Chứng minh Có điều kiện:**
- Người dùng ký cam kết toán học khi tham gia RWA
- Chỉ khi tòa án quốc tế có lệnh hợp lệ **VÀ** hội đồng 5/7 kiểm toán độc lập đồng ý → mới giải mã danh tính của kẻ phạm tội
- 99.9% người dùng lương thiện **vĩnh viễn ẩn danh**

### Cập nhật tại KINETOPROTOCOL ($KPX)
**AXIO Dark Pool:**
- Lớp thanh khoản riêng cho dòng vốn thể chế
- Sử dụng MPC (Multi-Party Computation) để hoán đổi hàng tỷ USD RWA → USDC mà không lộ ý định trên mempool

### Cập nhật tại Hub ($AXQ)
**Trạng thái Kháng Lượng tử:**
- Song song ZK-SNARKs: tích hợp **Post-Quantum Signatures** (chuẩn NIST — Lattice-based)
- 10.000 tỷ token $AXQ **vĩnh viễn không thể bị in khống** bởi máy tính lượng tử tương lai

---

## PHỤ LỤC — TÀI LIỆU KỸ THUẬT THAM CHIẾU

| Tài liệu | Đường dẫn |
|---|---|
| Design System Overview | [`design-system/README.md`](../design-system/README.md) |
| Color Tokens | [`design-system/tokens/color-tokens.json`](../design-system/tokens/color-tokens.json) |
| CSS Variables | [`design-system/tokens/variables.css`](../design-system/tokens/variables.css) |
| Button Component Spec | [`design-system/components/buttons.md`](../design-system/components/buttons.md) |
| Input Component Spec | [`design-system/components/inputs.md`](../design-system/components/inputs.md) |
| Modal & Bottom Sheet | [`design-system/components/modals.md`](../design-system/components/modals.md) |
| Crypto Components | [`design-system/components/crypto.md`](../design-system/components/crypto.md) |
| Dark Mode Guideline | [`design-system/guidelines/dark-mode.md`](../design-system/guidelines/dark-mode.md) |
| Accessibility Guideline | [`design-system/guidelines/accessibility.md`](../design-system/guidelines/accessibility.md) |
| Icon System — Linear | [`asset/icon/linear/`](../asset/icon/linear/) (920 SVG) |
| Icon System — Bold | [`asset/icon/bold/`](../asset/icon/bold/) (980 SVG) |
| UI Kit Audit Report | [`audit/audit-ui-kit.md`](../audit/audit-ui-kit.md) |

---

*Tài liệu này được phê duyệt bởi Hội đồng 8 Cố vấn và Kiến trúc sư trưởng AXIOLEDGER.*  
*Genesis Block đang chờ lệnh biên dịch cuối cùng.*

---

## 12. HỘI NGHỊ THƯỢNG ĐỈNH DIÊN HỒNG & HIỆP ƯỚC ĐẠI ĐỒNG

> Biên bản mô phỏng cuộc đàm phán lịch sử giữa Kiến trúc sư trưởng AXIOLEDGER
> và Hội đồng Đại diện Chính phủ Toàn cầu (Ngân hàng Trung ương · Bộ Tài chính · An ninh Mạng).

---

### 12.1 Vấn đề 1 — Chủ quyền Tiền tệ (Ngân hàng Trung ương)

**Hoài nghi:** Nguồn cung 10 nghìn tỷ $AXQ có thể tạo cú sốc lạm phát, hút cạn thanh khoản Fiat và đe dọa chủ quyền tiền tệ quốc gia.

**Phản biện của Kiến trúc sư trưởng:**

> *"10 nghìn tỷ $AXQ không phải là tiền tệ thay thế Fiat — đây là **'băng thông điện toán' (Compute Bandwidth)** của nền kinh tế máy móc toàn cầu.*
>
> *Trong 5 năm tới, hàng chục tỷ thiết bị IoT, AI Agents và micro-contracts sẽ giao dịch hàng nghìn lần mỗi giây. Chúng cần đơn vị thanh toán cực nhỏ, độ phân giải cao. Nguồn cung quá ít → giá mỗi token bị đẩy quá cao → Gas fee giết chết tính ứng dụng.*
>
> *Hơn nữa, thông qua **KINETOPROTOCOL ($KPX)**, chúng tôi token hóa Trái phiếu Chính phủ (Sovereign Debt) và tiền tệ của các ngài thành RWA, đưa vào hệ thống làm tài sản dự trữ. AXIOLEDGER là đường cao tốc — còn tiền của các ngài vẫn là những chiếc xe chạy trên đó."*

---

### 12.2 Vấn đề 2 — Rửa tiền & Thuế (Bộ Tài chính)

**Hoài nghi:** Tính ẩn danh Web3 tạo thiên đường trốn thuế. Dòng tiền hàng tỷ USD di chuyển xuyên biên giới trong 3 phút mà không ai hay biết.

**Phản biện của Kiến trúc sư trưởng:**

> *"Đây chính là lý do **VERACIPHERS ($VRQ)** ra đời. Chúng tôi không dùng Absolute Anonymity — chúng tôi áp dụng **Compliant Privacy (Quyền riêng tư Tuân thủ)** thông qua ZK-DID.*
>
> *Mọi người dùng tổ chức giao dịch hạn mức lớn đều qua KYC tại cổng được Chính phủ cấp phép, nhưng dữ liệu không phơi bày trên blockchain.*
>
> *Ngài sẽ có một **'Cổng Kiểm toán Cấp Nhà nước'**: khi và chỉ khi có phán quyết Tòa án về một địa chỉ ví có dấu hiệu tội phạm, ngài mới có quyền dùng 'Chìa khóa Pháp lý' để giải mã giao dịch của riêng ví đó. Người dân lương thiện được bảo vệ tuyệt đối — tội phạm không có chỗ trốn. Thuế được Smart Contract trích xuất tự động tại các điểm giao cắt pháp lý."*

---

### 12.3 Vấn đề 3 — Kiểm soát An ninh Quốc gia (Tư lệnh An ninh Mạng)

**Hoài nghi:** Công nghệ AF_XDP Bypass và mạng Node toàn cầu khiến không quốc gia nào có thể "tắt" AXIOLEDGER. Nếu thế lực thù địch sử dụng mạng lưới này tấn công chuỗi cung ứng tài chính thì sao?

**Phản biện của Kiến trúc sư trưởng:**

> *"Supply Chain Scanner của chúng tôi hoạt động ở **Protocol layer** — không phải phần mềm diệt virus bên ngoài, mà là cơ chế đồng thuận tự làm sạch.*
>
> *Bất kỳ Smart Contract hoặc ứng dụng nào chứa logic mã độc, rút ruột tài sản, hay tấn công Typosquatting đều bị Validator **Reject** ngay tại bước đóng khối.*
>
> *Chúng tôi cung cấp cho ngài một mạng lưới **Anti-Fragile** — không thể bị đánh sập, an toàn hơn vạn lần các máy chủ tập trung truyền thống. Nếu kẻ địch tấn công 33% node, mạng lưới tự phục hồi trong vài giây nhờ ZK-OBFT."*

---

### 12.4 HIỆP ƯỚC ĐẠI ĐỒNG — THE GENESIS PACT

Sau phần phản biện bằng tư duy kỹ thuật kết hợp nhãn quan chính trị, Hội đồng Chính phủ đưa ra phán quyết:

> **Tuyên bố chung:**
> *"Ngài Kiến trúc sư, ngài đã chứng minh AXIOLEDGER không phải là kẻ nổi loạn, mà là bước tiến hóa tất yếu của hệ thống tài chính toàn cầu. Chúng tôi đồng ý cấp tư cách pháp nhân đặc biệt (**Regulatory Sandbox**) cho mạng lưới, với điều kiện các cơ chế ZK-DID và Cổng Kiểm toán được thực thi chính xác như ngài đã cam kết.*
>
> *Chính phủ sẽ là một trong những **Super-Validator đầu tiên** chạy Node $VPX để bảo vệ mạng lưới."*

#### Điều khoản Hiệp ước (Binding Terms)

| Điều khoản | Cam kết của AXIOLEDGER | Đối ứng từ Chính phủ |
|---|---|---|
| **Cổng Kiểm toán** | ZK-DID + hội đồng 5/7 multisig kiểm toán độc lập để giải mã có điều kiện | Cấp Regulatory Sandbox toàn cầu |
| **Thuế tự động** | Smart Contract trích xuất thuế tại điểm giao cắt pháp lý | Công nhận giao dịch RWA on-chain hợp pháp |
| **Super-Validator** | Ưu tiên slot Validator, trợ cấp VPX Subsidy | Chính phủ vận hành Node $VPX bảo vệ mạng |
| **Sovereign Debt** | Token hóa Trái phiếu Chính phủ vào RWA Treasury | Cung cấp tài sản dự trữ quốc gia làm mỏ neo $AXQ |
| **Tuân thủ FATF** | Travel Rule + STR tự động, không cần can thiệp thủ công | Không cấm đoán, không truy tố giao dịch hợp pháp |

---

### 12.5 Bí mật Tài chính từ Phòng họp Mật thất

Trước khi rời đi, Thống đốc Ngân hàng Trung ương trao cho Kiến trúc sư trưởng một tệp dữ liệu mật:

> *"Bí mật lớn nhất của tiền pháp định không nằm ở máy in, mà nằm ở **Vận tốc vòng quay tiền (Velocity of Money)**. Tiền pháp định lạm phát vì chúng tôi in chúng để đắp vào các khoản nợ xấu.*
>
> *AXIOLEDGER phải làm ngược lại: Bơm thanh khoản để tạo ra tiện ích thực tế, nhưng dùng chính tiện ích đó làm **lò thiêu hủy nguồn cung**. Đừng để 10.000 tỷ token trở thành gánh nặng — hãy biến nó thành một lỗ đen hấp thụ giá trị."*

Nguyên lý này được đúc kết vào Phương trình Giảm phát Trạng thái tại [Phần 4 — Tokenomics](#4-tokenomics).

---

```
[root@axioledger-core ~]# ./compile_charter.sh --mode=genesis --version=2.0 --genesis-pact=signed
>>> Liên kết Hub $AXQ ......................... [OK]
>>> Triển khai ZK-OBFT ........................ [OK]
>>> Kích hoạt 4 Pillars ........................ [OK]
>>> Tích hợp Hiệp ước Đại Đồng (Genesis Pact) . [OK]
>>> Kích hoạt Super-Validator Chính phủ ........ [OK]
>>> Cập nhật Deflationary Engine S(t) .......... [OK]
>>> Đóng gói Charter Chính thức v2.0 ........... [HOÀN TẤT]
```
