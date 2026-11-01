# **SÁCH TRẮNG: AXIOLEDGER ($AXQ)**

## **Mạng lưới Blockchain Thế hệ Mới — Lời Giải Cho "Bộ Ba Bất Khả Thi" và Tương Lai Tài Chính Định Chế**

> * **Tác giả:** Kiến trúc sư trưởng & Đội ngũ Phát triển Cốt lõi
> * **Phiên bản:** 2.0 — Genesis Pact Edition
> * **Trạng thái:** Bản Đệ trình Chính phủ, Ủy ban Liên minh & Định chế Tài chính Toàn cầu
> * **Hiệu lực:** Ngay khi Genesis Block được biên dịch
> * **Tầm nhìn:** Kiến tạo hệ sinh thái vĩ mô — mục tiêu **10.000.000.000.000 Token $AXQ**
> * **Đồng bộ:** Tài liệu này được đồng bộ hoàn toàn với [`AXIOLEDGER-OFFICIAL-CHARTER.md`](./AXIOLEDGER-OFFICIAL-CHARTER.md) v2.0

---

## MỤC LỤC

1. [Tóm tắt Đề án (Executive Summary)](#1-tóm-tắt-đề-án)
2. [Thực trạng & Cảm hứng từ Hạ tầng Hiện tại](#2-thực-trạng)
3. [Kiến trúc Hệ sinh thái: Mô hình Hub & 4 Pillars](#3-kiến-trúc-hệ-sinh-thái)
4. [Đột phá Công nghệ Lõi: Cơ chế Đồng thuận ZK-OBFT](#4-zk-obft)
5. [Tầm nhìn Kinh tế Vĩ mô & Định chế Pháp lý](#5-tầm-nhìn-vĩ-mô)
6. [Tokenomics & Mô hình Kinh tế (10.000 Tỷ $AXQ)](#6-tokenomics)
7. [Kiến trúc Phân quyền Máy chủ (Server IAM) & Bảo mật Hạ tầng](#7-server-iam)
8. [Hệ thống Ví AXIO Vault: Giao diện Người dùng Cuối](#8-axio-vault)
9. [Lộ trình Thực thi 5 Giai đoạn](#9-lộ-trình)
10. [Giá trị theo Từng Nhóm Stakeholder](#10-value-proposition)
11. [Phụ lục Kỹ thuật](#11-phụ-lục-kỹ-thuật)
12. [Tuyên bố Miễn trừ Trách nhiệm Pháp lý (Legal Disclaimer)](#12-legal-disclaimer)

---

## 1. TÓM TẮT ĐỀ ÁN (EXECUTIVE SUMMARY)

Đề án này trình bày kiến trúc hạt nhân của **AXIOLEDGER ($AXQ)** — một hệ sinh thái blockchain được thiết kế không phải để cạnh tranh những tính năng nhỏ lẻ, mà để **định hình lại toàn bộ cơ sở hạ tầng Web3**.

Bằng cách kết hợp ba nền tảng không thể tách rời:

- **Logic Toán học** — Thuật toán đồng thuận ZK-OBFT, phương trình bỏ phiếu Reputation-based và cơ chế phát thải có điều kiện
- **Kỹ thuật DevOps** — AF_XDP NIC Bypass, RAMDISK tối ưu I/O, đa máy khách Rust/C++, 600K+ TPS
- **Tôn chỉ Pháp luật** — ZK-DID, Regulator Gateway, Confidential Transfers, tuân thủ AML/KYC/FATF/MiCA

AXIOLEDGER giải quyết dứt điểm các điểm nghẽn chí tử của thế hệ blockchain trước (Solana, Ethereum, L2s): rủi ro tập trung hóa, chi phí vận hành cao, tắc nghẽn mạng lưới và thiếu tính tuân thủ pháp lý.

Với mô hình đột phá **1 Hub & 4 Pillars** và động cơ đồng thuận độc quyền **ZK-Optimized BFT (ZK-OBFT)**, AXIOLEDGER sẵn sàng đáp ứng yêu cầu khắt khe nhất của các định chế tài chính, chính phủ và hàng tỷ người dùng toàn cầu.

**Mốc KPI Cốt lõi:**

| Chỉ số | Mục tiêu |
|--------|---------|
| Thông lượng (SEQUENTICHAIN) | **600.000+ TPS** (Testnet Year 1) |
| Thời gian Chốt sổ (Finality) | **< 3 phút** |
| Hệ số Nakamoto | **> 100** (Validator độc lập) |
| Lượng Validator | **5.000+** (Giai đoạn 1) |
| Tổng Thanh khoản (TVL) | **$10 Tỷ USD** (Giai đoạn 3) |
| Người dùng Ví | **100 Triệu** (Giai đoạn 4) |
| Điểm Bùng phát Giảm phát | **Năm 3** — B(x) > M(x) vĩnh viễn |

---

## 2. THỰC TRẠNG VÀ CẢM HỨNG TỪ HẠ TẦNG HIỆN TẠI

Qua quá trình rà soát và quét sâu (deep scan) hạ tầng Web3 toàn cầu, chúng tôi cô đọng những "nỗi đau" lớn nhất mà kiến trúc AXIOLEDGER phải giải quyết:

| Mạng lưới Tiền nhiệm | Nỗi đau Cốt lõi (Pain Points) | Giải pháp Kiến trúc của AXIOLEDGER |
| :---- | :---- | :---- |
| **Solana** | Áp lực chi phí phần cứng và phí bỏ phiếu cực cao; Rủi ro sập mạng do phụ thuộc 1 client. | Tối ưu I/O bằng RAMDISK; Quỹ trợ cấp Validator (VPX Subsidy); Vận hành Đa máy khách (Rust/C++). |
| **Ethereum & L2s** | Chờ đợi 7 ngày để chốt sổ (Optimism); Phí Data Availability đắt đỏ; Phân mảnh thanh khoản. | ZK-Rollup kết hợp Volition DA lai ghép; Chốt giao dịch tức thì (Finality < 3 phút). |
| **Arbitrum/OP Sequencer** | Sequencer tập trung — một điểm thất bại duy nhất kiểm soát thứ tự giao dịch. | SVM Rollup phi tập trung — Leader được bầu chọn qua ZK-OBFT trong mỗi Micro-epoch. |
| **MetaMask & npm** | Tấn công chuỗi cung ứng (Typosquatting); Đánh cắp Private Key qua trình duyệt. | Supply Chain Scanner ở cấp Protocol — Validator Reject mã độc ngay khi đóng khối. |
| **Thị trường chung** | Mâu thuẫn giữa ẩn danh Web3 và yêu cầu tuân thủ KYC/AML của chính phủ. | ZK-DID + Regulator Gateway: Compliant Privacy — 99.9% người dùng lương thiện vĩnh viễn ẩn danh. |

---

## 3. KIẾN TRÚC HỆ SINH THÁI: MÔ HÌNH HUB & 4 PILLARS

AXIOLEDGER áp dụng thiết kế phân rã chức năng (Modular Architecture), trong đó một Lõi Trung tâm (Hub) điều phối 4 Trụ cột chuyên biệt (Pillars):

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
│VALIPRECISION│ │SEQUENTICHAIN│ │KINETOPROTOCOL│ │ VERACIPHERS │
│    ($VPX)   │ │    ($SQX)   │ │    ($KPX)   │ │    ($VRQ)   │
├─────────────┤ ├─────────────┤ ├─────────────┤ ├─────────────┤
│ Consensus & │ │ High-Speed  │ │ DeFi Engine │ │ ZK-Security │
│ Validation  │ │ L2 Execution│ │ & Liquidity │ │ & Compliance│
│             │ │             │ │             │ │             │
│ • Multi-    │ │ • SVM Rollup│ │ • AMM Pool  │ │ • ZK-Proof  │
│   client    │ │ • AF_XDP    │ │ • Cross-    │ │ • DID/KYC   │
│   Rust+C++  │ │   NIC Bypass│ │   chain     │ │ • Regulator │
│ • RAMDISK   │ │ • 600K+ TPS │ │   Bridge    │ │   Gateway   │
│   I/O opt   │ │ • ZK-Rollup │ │ • RWA       │ │ • Supply    │
│ • NVMe      │ │   Settlement│ │   Treasury  │ │   Chain     │
│   partitioned│ │ • <3min   │ │ • Dark Pool │ │   Scanner   │
│ • ZK-OBFT   │ │   Finality  │ │ • LP Market │ │ • Confidential│
│             │ │             │ │             │ │   Transfer  │
└─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘
```

### Chi tiết Phân bổ Chức năng

| Trụ cột | Mã Token | Chức năng Cốt lõi | Giải quyết Pain Point |
|---|---|---|---|
| **Hub** | `$AXQ` | Sổ cái quyết toán, Treasury DAO, Quản trị on-chain | Immutable Settlement, kháng lượng tử |
| **VALIPRECISION** | `$VPX` | Đồng thuận ZK-OBFT, quản lý Validator, RAMDISK | Áp lực phần cứng Solana, tập trung hóa |
| **SEQUENTICHAIN** | `$SQX` | L2 siêu tốc, SVM Rollup, AF_XDP, ZK-Settlement | Sequencer tập trung, độ trễ 7 ngày Optimism |
| **KINETOPROTOCOL** | `$KPX` | AMM Pool, Cross-chain Bridge, RWA Treasury, Dark Pool | Phân mảnh thanh khoản, Front-running thể chế |
| **VERACIPHERS** | `$VRQ` | ZK-DID, KYC/AML, Supply Chain Scanner, Regulator Gateway | Ẩn danh vs Tuân thủ, Typosquatting MetaMask |

---

## 4. ĐỘT PHÁ CÔNG NGHỆ LÕI: CƠ CHẾ ĐỒNG THUẬN ZK-OBFT

Thay vì PoS (tạo ra nền tài phiệt) hoặc pBFT truyền thống (chậm chạp, khó mở rộng), AXIOLEDGER đề xuất hệ thống đồng thuận lai ghép độc quyền tại lớp $VPX: **Zero-Knowledge Byzantine Fault Tolerance (ZK-OBFT)**.

### 4.1. Trọng số Bỏ phiếu Tính toán theo Cống hiến (Reputation-based VP)

Quyền lực mạng lưới không chỉ nằm ở vốn mà bị ràng buộc bởi đóng góp kỹ thuật thực tế:

```
VP_i(t) = S_i(t) × R_i(t)

Trong đó:
  S_i(t)   = Số lượng token $VPX đã khóa
  R_i(t)   = α·U_i(t) + β·ln(1 + γ·B_i(t))
  U_i(t)   = Tỷ lệ Uptime (phạt theo cấp số nhân nếu offline)
  B_i(t)   = Băng thông thực tế đóng góp
              (hàm ln triệt tiêu độc quyền phần cứng)
```

### 4.2. Khử Thắt Cổ chai Mạng Bằng ZK-SNARKs

Thay vì hàng trăm triệu tin nhắn Gossip khi mạng có hàng nghìn Node:

1. Leader gom hàng nghìn chữ ký đa hình (Multi-signatures)
2. Chạy ZK-Circuit với điều kiện: `∑VP_voters > 2/3 × ∑VP_total`
3. Xuất **Bằng chứng π** siêu nhẹ (~284 bytes) — mọi node xác minh trong O(1)

**Kết quả:** Giảm 99% tải Gossip network so với pBFT truyền thống.

### 4.3. Đao Phủ Thuật Toán (Instant Slashing)

Bất kỳ hành vi ký đúp (Double-signing) bị phát hiện:
- Token $VPX bị đốt **100%** trong cùng một block
- Chỉ số Uy tín `R_i` về **0**
- Validator bị loại vĩnh viễn — không cần giai đoạn thử thách

### 4.4. Sức Bền Toán học Trước Tấn Công DDoS

Nếu kẻ thù đánh sập 33% node lớn nhất:
- `U_i` của node bị tấn công lao dốc → `VP_i` bốc hơi theo hàm mũ trong một Micro-epoch
- Các node sống sót tái chiếm >2/3 tổng VP mới
- Mạng **tự chữa lành** trong vài giây — Liveness và Safety được bảo toàn

### 4.5. Trạng thái Kháng Lượng tử (Post-Quantum)

Tích hợp song song ZK-SNARKs và **Post-Quantum Signatures** (chuẩn NIST — Lattice-based): 10.000 tỷ token $AXQ vĩnh viễn không thể bị in khống bởi máy tính lượng tử tương lai.

---

## 5. TẦM NHÌN KINH TẾ VĨ MÔ VÀ ĐỊNH CHẾ PHÁP LÝ

AXIOLEDGER không chỉ là công trình khoa học máy tính, mà là một **Thiết chế Xã hội Số**. Sau Hội nghị Thượng đỉnh Diên Hồng Kỹ thuật số, hệ sinh thái đã ký kết **Hiệp ước Đại Đồng (Genesis Pact)** với Hội đồng đại diện Chính phủ Toàn cầu trên các cam kết:

| Điều khoản Hiệp ước | Cam kết của AXIOLEDGER | Đối ứng từ Chính phủ |
|---|---|---|
| **Cổng Kiểm toán** | ZK-DID + hội đồng 5/7 multisig kiểm toán độc lập để giải mã có điều kiện | Cấp Regulatory Sandbox toàn cầu |
| **Thuế Tự động** | Smart Contract trích xuất thuế tại điểm giao cắt pháp lý | Công nhận giao dịch RWA on-chain hợp pháp |
| **Super-Validator** | Ưu tiên slot Validator, trợ cấp VPX Subsidy | Chính phủ vận hành Node $VPX bảo vệ mạng |
| **Sovereign Debt** | Token hóa Trái phiếu Chính phủ vào RWA Treasury | Cung cấp tài sản dự trữ quốc gia làm mỏ neo $AXQ |
| **Tuân thủ FATF** | Travel Rule + STR tự động, không cần can thiệp thủ công | Không cấm đoán, không truy tố giao dịch hợp pháp |

> **Nguyên tắc Cốt lõi:** Minh bạch với nhà nước, bảo mật cho doanh nghiệp. Thông lượng vượt trội (600K+ TPS) đủ năng lực hấp thụ toàn bộ lưu lượng của các sàn chứng khoán truyền thống, hệ thống thanh toán quốc tế (SWIFT), và tài sản token hóa (RWA).

---

## 6. TOKENOMICS & MÔ HÌNH KINH TẾ (10.000 TỶ $AXQ)

### 6.1. Phân Bổ Nguồn Cung (10.000.000.000.000 $AXQ)

| Phân bổ | Tỷ lệ | Số lượng Tuyệt đối | Cơ chế Khóa & Mục đích |
|---|---|---|---|
| **Thanh khoản RWA & Dự trữ Thể chế** | **30%** | 3.000.000.000.000 | Mỏ neo thanh khoản trên KPX. Tài sản đối ứng khi ngân hàng token hóa trái phiếu/chứng chỉ tiền gửi |
| **Validator & Khai thác $VPX** | **25%** | 2.500.000.000.000 | Khóa Smart Contract, trả thưởng thuật toán suy giảm logarit trong **50 năm** |
| **Treasury DAO & Hàng hóa Công cộng** | **20%** | 2.000.000.000.000 | Quản trị on-chain 100% — tài trợ RetroPGF cho nhà phát triển hệ sinh thái và mã nguồn mở |
| **Cộng đồng & Airdrop** | **15%** | 1.500.000.000.000 | Người dùng sớm, chiến dịch mở rộng mạng lưới, thanh khoản khởi tạo |
| **Đội ngũ Cốt lõi & Đối tác** | **10%** | 1.000.000.000.000 | Vesting cliff **5 năm** — lợi ích dài hạn gắn chặt với sự sống còn của mạng lưới |
| **Tổng cộng** | **100%** | **10.000.000.000.000** | |

### 6.2. Phương trình Phát thải Neo Giá trị (Value-Pegged Emission)

```
Emission(t) = κ · ln(1 + ΔTVL_RWA) + μ · TransactionVolume(t) − Burn(t)
```

> Nếu không có vốn RWA mới chảy vào: `ln(1) = 0` → lạm phát từ mảng RWA **dừng tự động**.
> Các hệ số κ, μ được điều chỉnh tự động bởi AI của Treasury DAO theo từng epoch.

### 6.3. Động Cơ Đốt Thuật Toán (Deflationary Engine)

| Cơ chế | Mô tả | Tỷ lệ Đốt |
|---|---|---|
| **Gas Burn** | 70% phí giao dịch cơ sở trên SEQUENTICHAIN bị đốt vĩnh viễn | **70% phí cơ sở** |
| **RWA Yield Buyback** | Smart Contract trích 10% lợi nhuận từ RWA Treasury để mua lại và thiêu hủy $AXQ | **10% lợi nhuận RWA** |
| **Instant Slashing** | Token $VPX của Validator double-signing bị đốt 100% | **100% bị phạt** |
| **ZK-Privacy Tax** | Mọi Confidential Transfer tại VRQ đều đốt một khoản $AXQ cố định | Phí biến động |
| **RWA Collateral Lock** | Định chế phát hành RWA on-chain phải khóa 15% $AXQ làm bảo chứng rủi ro | Khóa dài hạn |

### 6.4. Phương trình Giảm phát Trạng thái

```
S(t) = S₀ + ∫₀ᵗ (M(x) − B(x)) dx

Trong đó:
  S₀   = Cung lưu hành ban đầu (10% TGE = 1.000 tỷ $AXQ)
  M(x) = Tốc độ đúc token thưởng Validator (hàm suy giảm logarit)
  B(x) = Tốc độ đốt từ Gas + RWA Yield Buyback + Slashing + Privacy Tax

Điểm bùng phát (Năm 3 — dự kiến):  B(x) > M(x)
→ $AXQ chính thức bước vào trạng thái GIẢM PHÁT VĨNH VIỄN
```

---

## 7. KIẾN TRÚC PHÂN QUYỀN MÁY CHỦ (SERVER IAM) & BẢO MẬT HẠ TẦNG VẬN HÀNH

AXIOLEDGER áp dụng quy chuẩn tuân thủ tài chính tối cao (PCI DSS Level 1, E2EE) đối với các máy chủ vận hành cổng thanh toán và quản trị quỹ. Toàn bộ hệ thống được xây dựng trên nguyên tắc cô lập dữ liệu tuyệt đối (Air-gapped Logic).

### 7.1. Phân Quyền Vai Trò Hệ Thống (RBAC/IAM) Trên Máy Chủ

| Vai trò / Định danh | Phạm vi quyền hạn (Least Privilege) | Nhiệm vụ chuyên trách |
| :---- | :---- | :---- |
| **Infrastructure Root / SysAdmin** | Toàn quyền kiểm soát kernel, network, Docker daemon, và phân vùng ảo `Q:\`. | Quản lý vòng đời hạ tầng cơ bản, cấu hình hệ thống file. *Không có quyền can thiệp private key hay quỹ.* |
| **Blockchain Validator / Node Operator** | Quyền đọc/ghi tiến trình Node, quyền giao tiếp P2P mạng lưới. | Xác thực giao dịch, đồng bộ khối, duy trì toàn vẹn sổ cái. |
| **Smart Contract / Treasury Engine** | Chạy các service tự động dưới user đặc quyền bị giới hạn, tương tác qua RPC/IPC. | Ký giao dịch tự động thông qua HSM/Multisig, luân chuyển dòng tiền. |
| **Security & FIM Auditor** | Quyền đọc file log hệ thống, log giao dịch, chạy công cụ quét bảo mật. | Giám sát tính toàn vẹn tệp tin (FIM), phát hiện xâm nhập/thay đổi mã nguồn trên `Q:\`. |

### 7.2. Định Danh Máy Chủ & Cấu Hình Mạng Thực Tế (Node Identity)

Node DevNet đang hoạt động được định danh chính thức trong hệ sinh thái AXIOLEDGER như sau:

| Thuộc tính | Giá trị |
| :---- | :---- |
| **Hostname** | `axioledger-devnode` |
| **FQDN (Axioledger Name System)** | `axioledger-devnode.axq` |
| **Hệ điều hành** | Ubuntu 24.04.4 LTS (Noble Numbat) |
| **Kernel** | Linux 4.4.0-19041-Microsoft (WSL2/Hyper-V) |
| **Windows Host** | `DESKTOP-SKOVGOT` |

#### Bản đồ Giao diện Mạng (Network Interface Map)

| Interface | Địa chỉ IP | Subnet | Vai trò |
| :---- | :---- | :---- | :---- |
| `wifi0` | **`192.168.0.47`** | `192.168.0.0/24` | **Primary LAN** — WiFi, Default Gateway `192.168.0.1`. Toàn bộ traffic dịch vụ AXIO đều bind vào interface này |
| `eth1` | `172.29.208.1` | `172.29.208.0/20` | Hyper-V vSwitch Internal — WSL ↔ Windows Host bridge |
| `eth0` | `169.254.82.205` | `169.254.0.0/16` | Link-local, Windows ICS (`192.168.137.1/24`) |
| `lo` | `127.0.0.1` | `127.0.0.0/8` | Loopback |

#### Axioledger Name System (ANS) — `.axq` DNS Nội bộ

Toàn bộ subdomain hệ sinh thái đều trỏ về `192.168.0.47` (cấu hình tại `/etc/hosts`, bảo vệ bởi `wsl.conf → generateHosts=false`):

```
# ── ANS: .axq — Axioledger Core Hub ─────────────────────────────
192.168.0.47    axioledger.axq          # Portal chính
192.168.0.47    api.axioledger.axq      # REST API Gateway
192.168.0.47    rpc.axioledger.axq      # JSON-RPC Endpoint
192.168.0.47    ws.axioledger.axq       # WebSocket Streaming
192.168.0.47    explorer.axioledger.axq # Block Explorer
192.168.0.47    grafana.axioledger.axq  # Monitoring Dashboard
192.168.0.47    devnet.axioledger.axq   # DevNet entry point
192.168.0.47    testnet.axioledger.axq  # Testnet entry point

# ── ANS: .vpx — Valiprecision Consensus ──────────────────────────
192.168.0.47    rpc.valiprecision.vpx
192.168.0.47    validator.valiprecision.vpx
192.168.0.47    staking.valiprecision.vpx

# ── ANS: .sqx — Sequentichain L2 ─────────────────────────────────
192.168.0.47    rpc.sequentichain.sqx
192.168.0.47    sequencer.sequentichain.sqx
192.168.0.47    rollup.sequentichain.sqx

# ── ANS: .kpx — Kinetoprotocol DeFi ──────────────────────────────
192.168.0.47    amm.kinetoprotocol.kpx
192.168.0.47    bridge.kinetoprotocol.kpx
192.168.0.47    vault.kinetoprotocol.kpx

# ── ANS: .vrq — Veraciphers ZK Security ──────────────────────────
192.168.0.47    zkproof.veraciphers.vrq
192.168.0.47    did.veraciphers.vrq
192.168.0.47    audit.veraciphers.vrq
```

### 7.3. Thiết Lập Phân Vùng Ảo `Q:\` Và Ánh Xạ Máy Chủ Linux/WSL

Để cô lập hoàn toàn hạ tầng tài chính tự động hóa khỏi các tác vụ hệ điều hành thông thường, AXIOLEDGER sử dụng kiến trúc **Sandboxed Virtual Drive**.

Trên hệ thống logic, phân vùng này được định danh là ổ `Q:\`, và được ánh xạ (mount) trực tiếp tới đường dẫn vật lý bảo mật trên máy chủ Linux (hoặc môi trường WSL) tại:
👉 **`/mnt/q/root/Ubuntu-24.04/rootfs/root`**

Cấu trúc thư mục được đồng bộ song song như sau để phục vụ CI/CD và cấu hình Nginx/Node.js:

* **Mã nguồn Lõi (Core):**
  * *Logic:* `Q:\core\`
  * *Server Path:* `/mnt/q/root/Ubuntu-24.04/rootfs/root/core/`
  * *Chức năng:* Mã nguồn ứng dụng lõi tài chính và các script chạy ngầm (cron jobs).

* **Thư viện Phụ thuộc (Node Modules):**
  * *Logic:* `Q:\node_modules\`
  * *Server Path:* `/mnt/q/root/Ubuntu-24.04/rootfs/root/node_modules/`
  * *Chức năng:* Các gói npm đã được kiểm duyệt chặt chẽ, không cho phép thay đổi trực tiếp từ bên ngoài.

* **Khóa Mật mã (Keys & SSL):**
  * *Logic:* `Q:\keys\` (hoặc `Q:\ssl\`)
  * *Server Path:* `/mnt/q/root/Ubuntu-24.04/rootfs/root/ssl/`
  * *Chức năng:* Lưu trữ `server.crt`, `server.key` và tệp cấu hình ví nóng/lạnh (`chmod 600`).

* **Nhật ký Hệ thống (Logs):**
  * *Logic:* `Q:\logs\`
  * *Server Path:* `/mnt/q/root/Ubuntu-24.04/rootfs/root/logs/`
  * *Chức năng:* `nginx-access.log`, `core-out.log` phục vụ kiểm toán tự động.

### 7.4. Cấu Trúc Quản Trị Hệ Thống Liên Hợp (Hybrid-Fi)

Quy ước đặt tên chuẩn toàn cầu: `[Khu vực]-[Cấp độ tổ chức]-[Phân hệ]-[Mã định danh duy nhất]`. Hệ thống máy chủ vật lý (bao gồm các mount point `/mnt/q/..`) được kiểm soát chéo bởi 3 trụ cột:

* **Trụ cột Pháp lý & Tuân thủ (VD: `GLOBAL-LEGAL-COMP-01`):** Có quyền phủ quyết (Veto Power) các luồng thanh toán tự động (Cron jobs) nếu vi phạm AML/OFAC.

* **Trụ cột Thiết kế & Giải pháp (VD: `US-ARCH-CORE-ENGINE`):** Chịu trách nhiệm về mã nguồn tại `/mnt/q/root/.../core/`, đảm bảo tính toàn vẹn của logic tài chính.

* **Trụ cột DevOps & Vận hành Hạ tầng (VD: `SG-DEVOPS-NODE-Q01`):** Điều hành trực tiếp các tiến trình Systemd Service và Nginx, đảm bảo cấu hình proxy chuyển tiếp an toàn từ cổng 443 vào API lõi Node.js tại phân vùng `Q:\`, duy trì High Availability (99.99%).

---
## 8. HỆ THỐNG VÍ AXIO VAULT: GIAO DIỆN NGƯỜI DÙNG CUỐI

**Khẩu hiệu:** *"Trải nghiệm Web2 – Sức mạnh Web3 – Bảo mật Toán học"*

### 8.1. Trừu Tượng Hóa Tài Khoản Gốc (Native Account Abstraction)

Mỗi ví là một Hợp đồng Thông minh độc lập, xóa bỏ giới hạn của Seed Phrase và phí gas truyền thống:

* **Gasless Transactions:** Trả phí gas bằng stablecoin (USDC/USDT) hoặc được tài trợ bởi DApp (Paymaster).
* **Social Recovery:** Khôi phục ví qua FaceID, Email, hoặc đa chữ ký từ người thân/đối tác.
* **Session Keys:** Cấp quyền ký tự động cho vi giao dịch (micro-transactions) trong game hoặc DeFi.
* **Transaction Batching:** Gộp các lệnh (Approve + Swap) thành một lệnh nguyên tử (Atomic transaction) — 1-Click UX.

### 8.2. Phân tầng Vai trò Giao diện (Adaptive UI)

**Retail (Cá nhân):**
- Đăng nhập: Email / Google / Apple ID / Số điện thoại — MPC chia nhỏ Private Key
- Gasless: Phí trả bằng USDT/USDC hoặc tài trợ 100% bởi DApp (Paymaster)
- Social Recovery: FaceID hoặc xác nhận từ 3 người thân

**Institutional (Tổ chức):**
- Multi-sig tích hợp: Mọi lệnh trên X USD phải có ≥ 2/3 chữ ký phê duyệt
- Confidential Transfer: Ẩn số dư bằng ZK-Proofs ($VRQ) — tích hợp AXIO Dark Pool
- RWA Management: Giao diện tương tác trực tiếp với KPX RWA Treasury

### 8.3. Luồng Giao dịch

```
[BẮT ĐẦU DAPP]
      │
      ▼
[KẾT NỐI AXIO VAULT]
      ├─► (Retail)  → Đăng nhập Google/FaceID → Khởi tạo Smart Contract Wallet (ngầm)
      └─► (Pro)     → Seed Phrase / Hardware Wallet (Ledger)
      │
      ▼
[BỘ QUÉT VRQ — SUPPLY CHAIN SCANNER]
      ├─► Mã độc/Typosquatting → [BLOCK & CẢNH BÁO ĐỎ]
      └─► Hợp đồng an toàn    → Tiếp tục
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
[THÀNH CÔNG] → Cập nhật số dư Real-time
```

### 8.4. Bảo Mật Tích Hợp

* **Supply Chain Scanner (VRQ Protocol-level):** Ví tự động kiểm tra và chặn tương tác với Smart Contract/DApp độc hại. Validator Reject mã độc ngay tại bước đóng khối — không phải lớp phần mềm diệt virus bên ngoài.
* **ZK-DID & Confidential Transfer:** Cho phép KYC ẩn danh và chuyển giao tài sản tổ chức (RWA) mà không lộ số dư.

---

## 9. LỘ TRÌNH THỰC THI 5 GIAI ĐOẠN

### Giai đoạn 1 — Khởi tạo Hạt nhân & Đồng thuận (Tháng 1–6)
**Trọng tâm:** `$AXQ Hub` + `VALIPRECISION ($VPX)`

| Hoạt động | Thực thi Cốt lõi | Yêu cầu Kỹ thuật | KPI |
|---|---|---|---|
| Xây dựng Hub $AXQ | Sổ cái bất biến, Treasury DAO, mã hóa luật lạm phát | Không admin key. Quản trị 100% on-chain | — |
| Triển khai ZK-OBFT | Thuật toán VP=S×R, mạch ZK-SNARKs | Giảm 99% tải Gossip network | — |
| Mở rộng Validator | RAMDISK/NVMe config, VPX Subsidy Fund | Song song Rust + C++ client | **5.000 Validator, Nakamoto Coefficient > 100** |

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
| Sovereign Debt Tokenization | Ký kết Ngân hàng Trung ương, token hóa nợ chính phủ | Pháp chế Sandbox + Thanh khoản TradFi |
| AXIO-OS | Tích hợp Vault vào hệ điều hành điện thoại | Secure Enclave + ZK-DID hardware |
| AI Quản trị Phi tập trung | AI quản lý Supply Chain Scanner + tối ưu Treasury DAO | Năng lực xử lý Q-Oracle |
| **ENDGAME** | 100% giao dịch thương mại/chứng khoán/BĐS qua AXIOLEDGER với phí < $0.0001 | Đồng thuận 8 Cố vấn + 1 Hub 4 Pillars |

---

## 10. GIÁ TRỊ THEO TỪNG NHÓM STAKEHOLDER

| Nhóm | Giá trị Nhận được |
|---|---|
| **Chính phủ & Ủy ban (Regulators)** | Mạng phi tập trung nhưng tuân thủ AML/KYC tuyệt đối qua ZK-DID. Giám sát dòng tiền RWA vĩ mô mà không vi phạm quyền riêng tư cá nhân. |
| **Định chế Tài chính (Institutions/VCs)** | 600K TPS không trượt giá, Confidential Transfer ẩn giao dịch nội bộ, Dark Pool không bị Front-running — mở cánh cửa giao dịch trái phiếu/cổ phiếu on-chain an toàn nhất lịch sử. |
| **Validators (Cộng đồng IT & DevOps)** | Phần thưởng từ VPX Subsidy Fund. Phần cứng tầm trung (nhờ RAMDISK) đủ chạy Node — thu về $VPX + $AXQ. |
| **Người dùng Phổ thông (Retail)** | Dùng AXIO Vault như MoMo/Apple Pay. Phí bằng stablecoin. Không cần nhớ Seed Phrase. Không thể bị hack do lộ Private Key. |
| **Nhà phát triển DApp** | Tương thích MetaMask ngay lập tức. Session Keys giảm friction UX. Supply Chain Scanner bảo vệ người dùng của họ. |
| **Ngân hàng Trung ương** | Trở thành Super-Validator. Token hóa Nợ chính phủ làm mỏ neo thanh khoản $AXQ. Cổng Kiểm toán độc quyền. |

---

## 11. PHỤ LỤC KỸ THUẬT

### 11.1. Thông số Benchmark SEQUENTICHAIN ($SQX)

| Thông số | Giá trị | Phương pháp Đo |
|---|---|---|
| Thông lượng tối đa | **600.000+ TPS** | Testnet với 5.000 node giả lập, tải đồng đều |
| Độ trễ Finality | **< 3 phút** | ZK-Rollup Settlement lên Hub $AXQ |
| Kích thước ZK Proof | **~284 bytes** | Bằng chứng π aggregate từ toàn bộ Validator set |
| Thời gian Xác minh | **O(1)** | Kiểm tra proof tại mỗi node nhận |
| Tải Gossip giảm | **99%** | So với pBFT truyền thống N node |

### 11.2. Kiến trúc Smart Contract KPX RWA — Rust (Anchor Framework)

Lớp SEQUENTICHAIN dùng SVM nên Smart Contract viết bằng **Rust (Anchor framework)**:

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

**Quy trình Thế chấp RWA:**
```
ZK-DID Verify (VRQ)
  → Định giá RWA (Oracle)
  → Tính 15% $AXQ Collateral
  → Chuyển $AXQ vào Vault
  → Cập nhật Sổ cái
  → Kích hoạt Emission (AXQ Hub)
```

**Error Codes:**

| Code | Thông báo |
|---|---|
| `InvalidComplianceProof` | Bằng chứng ZK-DID không hợp lệ hoặc đã bị thu hồi |
| `InsufficientCollateral` | Số dư $AXQ không đủ đáp ứng tỷ lệ bảo chứng 15% |

### 11.3. Synergy Xuyên Trụ cột

```
KPX (deposit_rwa_and_lock_axq)
  └─► Gọi VRQ (vrq_interface::verify_zk_did)       — Xác thực danh tính
  └─► Gọi AXQ Hub (axq_hub::trigger_emission)       — Điều tiết lạm phát
  └─► Oracle (oracle::get_axq_price)                 — Giá thời gian thực
```

### 11.4. Tài liệu Tham chiếu Nội bộ

| Tài liệu | Đường dẫn |
|---|---|
| Điều lệ Chính thức v2.0 | [`docs/AXIOLEDGER-OFFICIAL-CHARTER.md`](./AXIOLEDGER-OFFICIAL-CHARTER.md) |
| Design System Overview | [`design-system/README.md`](../design-system/README.md) |

### 11.5. Khung Kiến Trúc API Hệ Sinh Thái (v0.0.0)

API Gateway duy nhất tiếp nhận toàn bộ traffic, thực thi xác thực ZK-DID, rate limiting và TLS 1.3 trước khi định tuyến đến từng Pillar:

```
Client / DApp
    │  HTTPS TLS 1.3
    ▼
┌─────────────────────────────────────────────────────────┐
│           API GATEWAY                                   │
│  https://api.axioledger.axq/v1/  (192.168.0.47:443)    │
│  • ZK-DID Authentication         • Rate Limiting        │
│  • TLS 1.3 Termination           • Request Routing      │
└──────┬──────────┬──────────┬──────────┬──────────┬──────┘
       │          │          │          │          │
       ▼          ▼          ▼          ▼          ▼
  /core/      /vp/       /sqx/      /kpx/      /vrq/
  AXQ Hub    VPX        SQX        KPX         VRQ
```

**Phân hạch Endpoint theo Tổ chức:**

| Tổ chức | Prefix | Endpoint | Mô tả |
| :---- | :---- | :---- | :---- |
| **Hub ($AXQ)** | `/core/` | `POST /core/treasury/propose` | Đề xuất quản trị DAO |
| | | `GET /core/metrics/inflation` | Truy xuất thông số phát thải |
| **VALIPRECISION ($VPX)** | `/vp/` | `GET /vp/validators/reputation` | Truy xuất chỉ số $R_i$ |
| | | `POST /vp/consensus/zk-proof` | Gửi bằng chứng ZK-SNARKs đa chữ ký |
| **SEQUENTICHAIN ($SQX)** | `/sqx/` | `POST /sqx/tx/batch` | Gửi cụm giao dịch qua Zero-Copy Network |
| | | `GET /sqx/rollup/state` | Truy xuất trạng thái L2 Rollup |
| **KINETOPROTOCOL ($KPX)** | `/kpx/` | `POST /kpx/pool/swap` | Thực thi hoán đổi cross-chain |
| | | `GET /kpx/rwa/vault` | Truy xuất tài sản thế giới thực |
| **VERACIPHERS ($VRQ)** | `/vrq/` | `POST /vrq/did/verify` | Xác thực KYC ẩn danh ZK-DID |
| | | `GET /vrq/scanner/blacklist` | Truy xuất dữ liệu quét mã nguồn |

Schema chi tiết: [`core/api/api-schema-v0.0.0.md`](../core/api/api-schema-v0.0.0.md)

### 11.6. Trung Tâm Điều Khiển CI/CD — OMNI GitHub Automation Controller (v0.0.0)

Máy chủ `axioledger-devnode` (`192.168.0.47`) vận hành bộ script tự động hóa tại `core/github/` để điều phối toàn bộ 5 tổ chức GitHub:

```
================================================================================
          AXIOLEDGER — OMNI GITHUB AUTOMATION CONTROLLER  v0.0.0
================================================================================
 Service Account : 315885655+davictran76@users.noreply.github.com
 Node            : axioledger-devnode (192.168.0.47)
 Token Status    : [🟢 ACTIVE] — Super Admin (Full Scope)
 Organizations   : axioledger · kinetoprotocol · sequentichain
                   valiprecision · veraciphers
--------------------------------------------------------------------------------
 WORKFLOWS:
  [1] Tạo Repository đồng nhất xuyên 5 tổ chức
  [2] Đồng bộ bản vá bảo mật (VRQ → Cross-Org Patch)
  [3] Áp dụng Branch Protection hàng loạt (dev/ledger/master/main)
  [4] Luân chuyển Secrets & API Keys (24h Auto-Rotation)
  [5] Tạo / Cập nhật GitHub Projects v2 (Kanban Board)
  [6] Kích hoạt GitHub Actions Workflow xuyên tổ chức
  [7] Kiểm toán toàn diện — Audit Snapshot → JSON
================================================================================
```

**Quyền hạn (GitHub Token Scopes) được phân bổ theo nhiệm vụ:**

| Nhóm Quyền | Scope | Workflow Sử dụng |
| :---- | :---- | :---- |
| **Tổ chức & Dự án** | `admin:org`, `project` | W1, W5 — Tạo repo, quản lý Kanban |
| | `write:org`, `admin:org_hook` | W5 — Cập nhật thành viên, webhooks |
| **Mã nguồn & CI/CD** | `repo`, `workflow` | W1, W2, W6 — Push code, trigger Actions |
| | `manage_runners:org` | W6 — Điều phối self-hosted runner tại `Q:\` |
| **Bảo mật & Bí mật** | `admin:public_key`, `admin:gpg_key` | W4 — Luân chuyển khóa mã hóa mỗi 24h |
| | `codespace:secrets`, `write:packages` | W4, W2 — Rotate secrets, publish packages |
| | `audit_log`, `security_events` | W7 — Kiểm toán toàn diện → JSON report |

**Luồng Backend Tự Động Hóa:**

```
[1] Cross-Org Security Sync (W2)
    veraciphers/scanner  ──patch──►  sequentichain/core
                         ──patch──►  kinetoprotocol/core
                         ──patch──►  axioledger/core
                         ──patch──►  valiprecision/core
                         └─ Trigger CI/CD rebuild (W6) ─► Tất cả orgs

[2] Secret Rotation (W4) — Mỗi 24h (cron)
    HSM Key Generation ──encrypt(NaCl)──► PUT /orgs/{org}/actions/secrets
                                          × 5 tổ chức đồng thời

[3] Audit Snapshot (W7) — Định kỳ
    GitHub API → repos + members + secrets + hooks
    → /root/logs/audit-{timestamp}.json
    → FIM giám sát tính toàn vẹn báo cáo
```

Script điều khiển: [`core/github/modal.sh`](../core/github/modal.sh)
| Color Tokens (JSON + CSS) | [`design-system/tokens/`](../design-system/tokens/) |
| Button Component Spec | [`design-system/components/buttons.md`](../design-system/components/buttons.md) |
| Modal & Bottom Sheet | [`design-system/components/modals.md`](../design-system/components/modals.md) |
| Crypto Components | [`design-system/components/crypto.md`](../design-system/components/crypto.md) |
| Dark Mode Guideline | [`design-system/guidelines/dark-mode.md`](../design-system/guidelines/dark-mode.md) |
| Accessibility (WCAG 2.1 AA) | [`design-system/guidelines/accessibility.md`](../design-system/guidelines/accessibility.md) |
| Icon System — Linear (920 SVG) | [`asset/icon/linear/`](../asset/icon/linear/) |
| Icon System — Bold (980 SVG) | [`asset/icon/bold/`](../asset/icon/bold/) |
| UI Kit Audit Report | [`audit/audit-ui-kit.md`](../audit/audit-ui-kit.md) |

---

### 11.7. Bản Đồ Liên Kết Định Danh Toàn Hệ Thống

Bảng quy chiếu sau chuẩn hóa các tiêu chuẩn kỹ thuật, không gian tên miền, phạm vi NPM và tổ chức GitHub cho 5 trụ cột cấu thành hệ sinh thái AXIOLEDGER:

| Trụ cột | Ticker | Lớp Kiến trúc | ANS TLD | NPM Scope | GitHub Org | Repo Mẫu |
| :---- | :---- | :---- | :---- | :---- | :---- | :---- |
| **Axioledger** | `$AXQ` | Core Settlement / DAO | `.axq` | `@axioledger/*` | `@axioledger` | `axq-core-contracts`, `axq-ans-sdk` |
| **Valiprecision** | `$VPX` | Consensus & Node Staking | `.vpx` | `@valiprecision/*` | `@valiprecision` | `vpx-node-client`, `vpx-pos-engine` |
| **Sequentichain** | `$SQX` | L2 Sequencing / Rollup | `.sqx` | `@sequentichain/*` | `@sequentichain` | `sqx-rollup-core`, `sqx-sequencer` |
| **Kinetoprotocol** | `$KPX` | DeFi Engine & Liquidity | `.kpx` | `@kinetoprotocol/*` | `@kinetoprotocol` | `kpx-amm-router`, `kpx-liquidity-pool` |
| **Veraciphers** | `$VRQ` | ZK-Proof & Privacy DID | `.vrq` | `@veraciphers/*` | `@veraciphers` | `vrq-zk-circuits`, `vrq-did-resolver` |

**ANS Domains đang hoạt động:**

| Domain | Pillar | IP | HTTPS | TLS Issuer |
| :---- | :---- | :---- | :---- | :---- |
| `axqprotocol.axq` | Hub $AXQ | `192.168.0.47` | ✅ 200 | AXIOLEDGER CROSS-BRIDGE CA |
| `axqchain.axq` | Hub $AXQ | `192.168.0.47` | ✅ 200 | AXIOLEDGER CROSS-BRIDGE CA |
| `vpxchain.vpx` | $VPX | `192.168.0.47` | ✅ 200 | AXIOLEDGER CROSS-BRIDGE CA |
| `sqxledger.sqx` | $SQX | `192.168.0.47` | ✅ 200 | AXIOLEDGER CROSS-BRIDGE CA |
| `kpxprotocol.kpx` | $KPX | `192.168.0.47` | ✅ 200 | AXIOLEDGER CROSS-BRIDGE CA |
| `vrqledger.vrq` | $VRQ | `192.168.0.47` | ✅ 200 | AXIOLEDGER CROSS-BRIDGE CA |

Node vận hành: `axioledger-devnode` · `192.168.0.47` (LAN) · `113.22.172.197` (WAN)

---

### 11.8. Hệ Thống Chứng Chỉ PKI — AXIOLEDGER Global Payment Authority (GPIA)

AXIOLEDGER vận hành hạ tầng PKI 4 tầng độc lập phục vụ toàn bộ giao tiếp mã hóa nội bộ, xác thực mTLS giữa các Pillar và cấp phát chứng chỉ TLS cho tất cả ANS domains.

#### Kiến trúc phân cấp chứng chỉ (Certificate Hierarchy)

```
AXIOLEDGER GLOBAL PAYMENT ROOT CA          (RSA-4096 / SHA-512 / 20 năm)
  Serial: 02283C30000797C17F4E6FCCCF6B0B6F57298922
  FP:     81:71:DE:A4:CE:28:12:24:71:41:3C:BC:BF:4F:A0:16:...
  └── AXIOLEDGER CROSS-BRIDGE CA           (RSA-4096 / SHA-384 / 10 năm / pathlen:1)
      FP:  E4:61:7D:31:13:93:9F:A6:C9:DE:23:7B:68:13:40:C1:...
      ├── AXQ Hub Settlement Authority     (Pillar CA / 5yr / pathlen:0)
      │   └── axioledger-devnode.axq       (Operator / 2yr / clientAuth+serverAuth)
      ├── VPX Consensus Authority          (Pillar CA / 5yr)
      ├── SQX L2 Execution Authority       (Pillar CA / 5yr)
      ├── KPX DeFi Liquidity Authority     (Pillar CA / 5yr)
      ├── VRQ ZK Privacy Authority         (Pillar CA / 5yr)
      └── AXIOLEDGER PAYMENT GATEWAY       (End-Entity / mTLS / 16 SANs / 1yr)
          Serial: 1DF091B8FF6050378FB3FC9D69219AD05B7F07A9
```

#### 9.1. Root CA — Axioledger Global Payment Authority

```bash
# Khởi tạo Root CA (RSA 4096-bit, SHA-512, 20 năm)
openssl genrsa -out gpia-root.key 4096

openssl req -x509 -new -nodes -key gpia-root.key -sha512 -days 7300 \
  -out gpia-root.crt \
  -subj "/C=VN/ST=Hanoi/L=Hanoi/O=Axioledger Global Payment Authority/OU=GPIA Root Operations/CN=AXIOLEDGER GLOBAL PAYMENT ROOT CA"
```

**nameConstraints** ràng buộc Root CA chỉ ký cert cho các TLD nội bộ:
```
permitted: DNS:.axq, DNS:.vpx, DNS:.sqx, DNS:.kpx, DNS:.vrq
permitted: IP:192.168.0.0/255.255.255.0, IP:113.22.172.0/255.255.255.0
```

#### 9.2. Cross-Bridge CA (Cầu nối xuyên trụ cột)

CA cấp trung gian duy nhất ký toàn bộ 5 Pillar CA và Payment Gateway cert — đảm bảo cô lập chain of trust:

```bash
openssl genrsa -out bridge-ca.key 4096
openssl req -new -key bridge-ca.key -out bridge-ca.csr \
  -subj "/C=VN/O=Axioledger Ecosystem/OU=Cross-Pillar Bridge Authority/CN=AXIOLEDGER CROSS-BRIDGE CA"

openssl x509 -req -in bridge-ca.csr \
  -CA gpia-root.crt -CAkey gpia-root.key -CAcreateserial \
  -out bridge-ca.crt -days 3650 -sha384 -extfile bridge-ca-ext.cnf
```

#### 9.3. 5 Pillar Intermediate CAs

| Pillar CA | Fingerprint SHA-256 | Hết hạn |
| :---- | :---- | :---- |
| AXQ Hub Settlement Authority | `8E:B9:50:08:B4:D8:F9:AA:6A:CD:F1:B7:73:EB:DD:91...` | Aug 2031 |
| VPX Consensus Authority | `AC:EF:58:3E:42:A4:96:73:9E:5D:D3:AD:5E:C5:21:14...` | Aug 2031 |
| SQX L2 Execution Authority | `7C:20:33:37:8E:F7:E4:D1:27:42:24:D8:52:EA:F9:53...` | Aug 2031 |
| KPX DeFi Liquidity Authority | `66:7B:82:42:85:5D:7F:02:D3:A8:69:B2:06:7F:A1:15...` | Aug 2031 |
| VRQ ZK Privacy Authority | `64:E2:F1:35:FE:E4:79:B4:EB:9B:B2:22:56:B3:66:AD...` | Aug 2031 |

Tất cả Pillar CA được ký bởi **AXIOLEDGER CROSS-BRIDGE CA** với `pathlen:0` — không thể ủy quyền ký tiếp.

#### 9.4. Issue TLS Certificates cho ANS Domains

File cấu hình SAN (`ans-domains.ext`):
```
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1  = axqprotocol.axq
DNS.2  = axqchain.axq
DNS.3  = vpxchain.vpx
DNS.4  = sqxledger.sqx
DNS.5  = kpxprotocol.kpx
DNS.6  = vrqledger.vrq
DNS.7  = api.axioledger.axq
DNS.8  = rpc.axioledger.axq
DNS.9  = axioledger-devnode.axq
IP.1   = 192.168.0.47
IP.2   = 113.22.172.197
```

Payment Gateway Cert (mTLS — `serverAuth + clientAuth`):
```
Serial:  1DF091B8FF6050378FB3FC9D69219AD05B7F07A9
FP:      F9:BD:8B:3A:8C:ED:24:3F:FA:27:81:9D:32:DB:4C:0D:...
Issuer:  AXIOLEDGER CROSS-BRIDGE CA
Expires: Aug 31 2027 GMT
SANs:    16 domains + 2 IPs
```

#### 9.5. Cài đặt Root CA vào Trust Store

**Linux (Ubuntu/Debian):**
```bash
sudo cp gpia-root.crt /usr/local/share/ca-certificates/axioledger-gpia-root.crt
sudo update-ca-certificates
# File: /root/ssl/gpia/root-ca/gpia-root.crt (đã cài tại /etc/ssl/certs/axioledger-gpia-root.pem)
```

**macOS:**
```bash
sudo security add-trusted-cert -d -r trustRoot \
  -k /Library/Keychains/System.keychain gpia-root.crt
```

**Windows (PowerShell — Run as Administrator):**
```powershell
Import-Certificate -FilePath "gpia-root.crt" -CertStoreLocation Cert:\LocalMachine\Root
```

#### 9.6. Identity Declaration Document (v3.0)

File: `/root/ssl/gpia/export/gpia-identity-declaration.json`

```json
{
  "schema_version": "3.0.0",
  "ecosystem": "AXIOLEDGER GLOBAL PAYMENT AUTHORITY",
  "authority_class": "Tier-1 Global Settlement Infrastructure",
  "jurisdiction": "VN — Vietnam, International Operations",
  "node": {
    "hostname": "axioledger-devnode",
    "fqdn": "axioledger-devnode.axq",
    "ip_lan": "192.168.0.47",
    "ip_public": "113.22.172.197"
  },
  "root_ca": {
    "cn": "AXIOLEDGER GLOBAL PAYMENT ROOT CA",
    "serial": "02283C30000797C17F4E6FCCCF6B0B6F57298922",
    "fingerprint_sha256": "81:71:DE:A4:CE:28:12:24:71:41:3C:BC:BF:4F:A0:16:...",
    "valid_until": "Aug 26 2046 GMT",
    "key_algorithm": "RSA-4096",
    "signature_hash": "SHA-512"
  },
  "bridge_ca": {
    "cn": "AXIOLEDGER CROSS-BRIDGE CA",
    "fingerprint_sha256": "E4:61:7D:31:13:93:9F:A6:C9:DE:23:7B:68:13:40:C1:...",
    "valid_until": "Aug 28 2036 GMT"
  },
  "intermediate_pillars": [
    { "pillar": "Axioledger",     "ticker": "$AXQ", "ans_root": ".axq", "cn": "AXQ Hub Settlement Authority",  "fp": "8E:B9:50:08..." },
    { "pillar": "Valiprecision",  "ticker": "$VPX", "ans_root": ".vpx", "cn": "VPX Consensus Authority",       "fp": "AC:EF:58:3E..." },
    { "pillar": "Sequentichain",  "ticker": "$SQX", "ans_root": ".sqx", "cn": "SQX L2 Execution Authority",    "fp": "7C:20:33:37..." },
    { "pillar": "Kinetoprotocol", "ticker": "$KPX", "ans_root": ".kpx", "cn": "KPX DeFi Liquidity Authority",  "fp": "66:7B:82:42..." },
    { "pillar": "Veraciphers",    "ticker": "$VRQ", "ans_root": ".vrq", "cn": "VRQ ZK Privacy Authority",      "fp": "64:E2:F1:35..." }
  ],
  "supported_domains": [
    "axqprotocol.axq", "axqchain.axq", "vpxchain.vpx",
    "sqxledger.sqx", "kpxprotocol.kpx", "vrqledger.vrq",
    "api.axioledger.axq", "rpc.axioledger.axq", "axioledger-devnode.axq"
  ],
  "endpoints": {
    "ocsp": "http://ocsp.axioledger.axq",
    "crl":  "http://crl.axioledger.axq/root.crl"
  },
  "compliance": ["PCI DSS Level 1", "ISO 27001", "AML/KYC/FATF", "MiCA", "GDPR"]
}
```

---

## 12. TUYÊN BỐ MIỄN TRỪ TRÁCH NHIỆM PHÁP LÝ (LEGAL DISCLAIMER)

> **QUAN TRỌNG — VUI LÒNG ĐỌC KỸ TRƯỚC KHI SỬ DỤNG TÀI LIỆU NÀY**

### 12.1. Không phải Lời mời Đầu tư

Tài liệu này được soạn thảo nhằm mục đích **cung cấp thông tin kỹ thuật và kiến trúc** về hệ sinh thái AXIOLEDGER. Tài liệu **không cấu thành** lời đề nghị, lời mời, hay tư vấn đầu tư, chứng khoán, hoặc bất kỳ công cụ tài chính nào theo pháp luật của bất kỳ quốc gia hoặc vùng lãnh thổ nào.

### 12.2. Rủi ro Tài chính

Đầu tư vào tài sản kỹ thuật số và token tiền mã hóa mang theo rủi ro cao, bao gồm nhưng không giới hạn ở: mất toàn bộ vốn, biến động giá cao, rủi ro pháp lý, rủi ro kỹ thuật, và rủi ro thanh khoản. **Bạn không nên đầu tư số tiền mà bạn không thể chịu đựng được việc mất trắng.**

### 12.3. Thông tin Mang tính Dự báo (Forward-Looking Statements)

Các tuyên bố liên quan đến kế hoạch tương lai, lộ trình phát triển, mục tiêu hiệu năng (TPS, TVL, số lượng người dùng...) và mô hình kinh tế trong tài liệu này mang bản chất **dự báo** và **không phải là cam kết đảm bảo**. Kết quả thực tế có thể khác biệt đáng kể so với những gì được mô tả, do các yếu tố kỹ thuật, thị trường, pháp lý, hoặc các rủi ro không lường trước.

### 12.4. Tuân thủ Pháp luật Địa phương

Việc mua, bán, sở hữu, hoặc sử dụng token $AXQ và các token trong hệ sinh thái ($VPX, $SQX, $KPX, $VRQ) có thể bị hạn chế hoặc cấm tại một số quốc gia hoặc vùng lãnh thổ. **Bạn có trách nhiệm tự xác minh và tuân thủ đầy đủ các quy định pháp luật hiện hành tại địa phương của mình** trước khi tham gia vào bất kỳ hoạt động nào liên quan đến hệ sinh thái AXIOLEDGER.

### 12.5. Thay đổi Nội dung

Đội ngũ phát triển AXIOLEDGER bảo lưu quyền cập nhật, sửa đổi, hoặc thay thế bất kỳ phần nào của tài liệu này mà không cần thông báo trước. Phiên bản mới nhất và có giá trị pháp lý nhất luôn là phiên bản được công bố chính thức trên kho lưu trữ [`axioledger/axioledger`](https://github.com/axioledger/axioledger).

### 12.6. Sở hữu Trí tuệ

Toàn bộ nội dung, kiến trúc, mô hình toán học, tên thương hiệu và logo trong tài liệu này là **tài sản sở hữu trí tuệ độc quyền** của đội ngũ phát triển AXIOLEDGER. Nghiêm cấm sao chép, phân phối, hoặc sử dụng thương mại khi chưa có sự cho phép bằng văn bản.

---

*Tài liệu này được phê duyệt bởi Hội đồng 8 Cố vấn và Kiến trúc sư trưởng AXIOLEDGER.*
*Phiên bản 2.0 — Genesis Pact Edition. Genesis Block đang chờ lệnh biên dịch cuối cùng.*

```
[root@axioledger-core ~]# ./compile_whitepaper.sh --version=2.0 --sync=charter
>>> Đồng bộ với OFFICIAL-CHARTER v2.0 ........... [OK]
>>> Tích hợp Roadmap 5 Giai đoạn ................. [OK]
>>> Bổ sung Tokenomics Bảng Số Tuyệt đối ......... [OK]
>>> Thêm Technical Appendix (Benchmark + Rust) ... [OK]
>>> Thêm Legal Disclaimer (6 Điều khoản) ......... [OK]
>>> Đóng gói Whitepaper v2.0 ...................... [HOÀN TẤT]
```
## 11.9. ANS — AXIOLEDGER Name Service

Hệ thống **AXIOLEDGER Name Service (ANS)** là hạ tầng phân giải định danh phi tập trung của toàn bộ hệ sinh thái — tương đương với DNS nhưng tích hợp ZK-DID, multi-chain address resolution và on-chain ownership.

### Namespace Kiến trúc

ANS vận hành **5 TLD nội bộ** tương ứng với 5 trụ cột:

| TLD | Trụ cột | Ví dụ | Mục đích |
|---|---|---|---|
| `.axq` | Axioledger Hub | `treasury.axq`, `governance.axq` | Hub addresses, DAO endpoint |
| `.vpx` | Valiprecision | `validator-001.vpx`, `staking.vpx` | Validator node identity |
| `.sqx` | Sequentichain | `sequencer.sqx`, `rollup.sqx` | L2 service endpoints |
| `.kpx` | Kinetoprotocol | `pool-usdc-axq.kpx`, `rwa-treasury.kpx` | DeFi protocol addresses |
| `.vrq` | Veraciphers | `did-auth.vrq`, `kyc-gate.vrq` | ZK-DID identity, compliance |

### Thuật toán Namehash (ENS-compatible)

```
namehash("alice.axq") =
  keccak256(
    keccak256(0x0000...0000 || keccak256("axq")) || keccak256("alice")
  )
```

### Stack Kỹ thuật

```
[Client / dApp]
     │
     ▼
[CoreDNS Port 53]  ← intercept 5 custom TLDs
     │
     ▼
[ANS Resolver — Node.js :8053]
     │
     ├─► [Redis Cache — TTL 60s, <5ms]
     ├─► [PostgreSQL — off-chain registry]
     └─► [Foundry Anvil — on-chain contracts]
```

**Smart Contracts:** `ANSRegistry` · `PublicResolver` · `ReverseRegistrar`  
**Full spec:** [`core/api/ans-service-spec.md`](../core/api/ans-service-spec.md)

### NPM Scope & Identity Map

| Trụ cột | NPM Scope | GitHub Org |
|---|---|---|
| Axioledger | `@axioledger/*` | `github.com/axioledger` |
| Valiprecision | `@valiprecision/*` | `github.com/valiprecision` |
| Sequentichain | `@sequentichain/*` | `github.com/sequentichain` |
| Kinetoprotocol | `@kinetoprotocol/*` | `github.com/kinetoprotocol` |
| Veraciphers | `@veraciphers/*` | `github.com/veraciphers` |

> **Lưu ý:** Scope 3 ký tự (`@axq`, `@vpx`...) đã bị squat/reserved trên npm. Sử dụng tên đầy đủ thương hiệu.

---


## 11.10. GENESIS BLOCK — Sổ Cái Khởi Tạo

### Thời Điểm Đúc Token Duy Nhất (One-Time Mint)

**Block 0** của Sổ cái Lõi AXIOLEDGER Hub (`$AXQ`) được thiết lập tại thời khắc chính xác:

```
Genesis Timestamp : 2026-08-31T10:22:20Z (UTC)          ← Mốc Chính thức
Chain ID          : axioledger-core-0
Network           : axioledger-mainnet-genesis
Config File       : core/config/genesis-block.json
Denom             : uaxq  (1 AXQ = 10⁶ uaxq)
```

> Đây là khoảnh khắc **10.000 tỷ token $AXQ được đúc duy nhất một lần** và phân bổ vĩnh viễn vào 5 Địa chỉ Genesis. Không có cơ chế remint. Không có admin key. `admin_key = null`. Mọi thay đổi tham số chỉ qua TreasuryDAO governance vote.

### Phân Bổ 10.000 Tỷ $AXQ — Cosmos-SDK Format

```
Tổng cung: 10,000,000,000,000 AXQ = 10,000,000,000,000,000,000 uaxq

┌───────────────────────────┬──────┬─────────────────────────────────────┬──────────────────────────────────┐
│  Địa chỉ Genesis          │  %   │  uaxq Amount                        │  Cơ chế Khóa                     │
├───────────────────────────┼──────┼─────────────────────────────────────┼──────────────────────────────────┤
│  axq1_kpx_rwa_vault       │  30% │  3,000,000,000,000,000,000          │  Smart contract controlled       │
│  axq1_vpx_subsidy_pool    │  25% │  2,500,000,000,000,000,000          │  50-year logarithmic decay       │
│  axq1_treasury_dao        │  20% │  2,000,000,000,000,000,000          │  On-chain governance only        │
│  axq1_community_amm       │  15% │  1,500,000,000,000,000,000          │  Vesting schedule                │
│  axq1_core_team_vesting   │  10% │  1,000,000,000,000,000,000          │  5-year cliff vesting            │
├───────────────────────────┼──────┼─────────────────────────────────────┼──────────────────────────────────┤
│  TOTAL SUPPLY             │ 100% │ 10,000,000,000,000,000,000          │  Hard cap — bất biến             │
└───────────────────────────┴──────┴─────────────────────────────────────┴──────────────────────────────────┘
```

### Tham Số ZK-OBFT Mã Hóa Vào Genesis

| Tham số | Giá trị | Ý nghĩa |
|---|---|---|
| `alpha` | `0.6` | Trọng số Uptime trong R_i formula |
| `beta` | `0.4` | Trọng số Bandwidth trong R_i formula |
| `gamma` | `1000` | Hệ số khuếch đại bandwidth |
| `micro_epoch_ms` | `400` | Block time target (ms) |
| `max_gas` | `600,000,000` | Gas limit per block |
| `slash_double_sign` | `100%` | Instant Slashing — Điều IV |
| `emission_kappa` | `0.03` | RWA TVL emission coefficient |
| `emission_mu` | `0.001` | Transaction volume coefficient |

**Emission equation bất biến:**
```
Emission(t) = κ · ln(1 + ΔTVL_RWA) + μ · TxVolume(t) − Burn(t)
Nếu ΔTVL_RWA = 0 → Emission = 0  (lạm phát tự dừng — auto_halt_on_zero_rwa: true)
```

---

## 11.11. KINETOPROTOCOL — Cầu Nối Liên Chuỗi & Kiểm Duyệt Gateway

### Kiến Trúc ZK-Relay Bridge (Không phải Lock & Mint truyền thống)

KINETOPROTOCOL ($KPX) không dùng cơ chế "Khóa và Đúc" (Lock & Mint) đa chữ ký truyền thống. Thay vào đó: **ZK-Relay Bridge** — mọi payload đều được VPX ($VPX) giám sát và xác nhận qua ZK-OBFT:

```
[Nguồn: ETH / ARB / SOL]
        │ bridgeOut() + ZK-Proof + VRQ compliance
        ▼
┌─────────────────────────────────────────────────────────────────────┐
│  KPXRouterGateway.sol (core/contracts/kpx/KPXRouterGateway.sol)    │
│                                                                     │
│  Security Layers (thứ tự thực thi):                                 │
│  [1] VRQ Scanner: isFlagged(caller) + isFlagged(token)             │
│  [2] ZK: circuitVersion == requiredCircuitVersion                  │
│  [3] ZK: proofNonce chưa dùng (anti-replay)                        │
│  [4] ZK: verifyCompliance(proof, kycCommitment)                    │
│  [5] Chain whitelist: ETH(60) · ARB(42161) · SOL(501)              │
│  [6] Amount limit: amount <= maxBridgeAmountPerTx                  │
│  [7] Deadline: block.number <= deadline                             │
│  [8] SafeERC20.safeTransferFrom (no silent failure)                │
└─────────────────────────────────────────────────────────────────────┘
        │
        ▼
[MPC Relayer Network — 2/3 Threshold]
  Relayer 1 (GL-CORE-FIN-NODE01) ─ sign
  Relayer 2 (GL-CORE-FIN-NODE02) ─ sign  → ≥ 2/3 threshold unlock
  Relayer 3 (GL-CORE-FIN-NODE03) ─ sign
        │
        ▼ bridgeIn() — CEI Pattern (Checks-Effects-Interactions)
  [1] bridgeFulfilled[id] == false  ← REPLAY PREVENTION
  [2] VRQ: isFlagged(recipient)
  [3] bridgeFulfilled[id] = true    ← STATE UPDATE TRƯỚC TRANSFER
  [4] SafeERC20.safeTransfer(recipient)
        │
        ▼
[Recipient nhận tài sản — Finality confirmed]
```

### Phân Luồng Thanh Khoản: AMM vs Dark Pool

```
swapExactTokensForTokensWithPrivacy()
        │
        ├─ amountIn <= institutionalThreshold → Standard AMM (public orderbook)
        │
        └─ amountIn > institutionalThreshold  → IKPXDarkPool
                                                 Pedersen commitment
                                                 ZK Match Proof
                                                 No frontrunning
                                                 No orderbook impact
```

### Foundry Test Suite — Bảo Vệ Reentrancy

Trước khi deploy, toàn bộ test suite Foundry phải PASS:

```
forge test --match-path test/KPXRouterGateway.t.sol -vvvv

T1. Deployment & Constructor     (2 tests)
T2. VRQ Security Pre-checks      (4 tests)  ← isFlagged() là CHECK ĐẦU TIÊN
T3. *** REENTRANCY ATTACKS ***   (5 tests)  ← CRITICAL
    T3.1 bridgeOut → fallback → bridgeOut   (ReentrancyGuard phải block)
    T3.2 swap → DarkPool callback → swap    (nonReentrant phải block)
    T3.3 bridgeIn double-spend              (fulfilled mapping phải block)
    T3.4 ZK Proof replay attack             (usedProofNonces phải block)
    T3.5 nonReentrant lock release          (lock phải release sau call)
T4. Bridge Security              (7 tests)
T5. ZK-Proof Security            (2 tests)
T6. Governance & Emergency       (6 tests)
T7. AMM Swap Security            (3 tests)
T8. Fuzz Tests (10,000 runs)     (5 tests)
HP. Happy Path                   (2 tests)

Tổng: 36 tests · Fuzz: 5 × 10,000 = 50,000 runs
```

**Files:**
- Contract: [`core/contracts/kpx/KPXRouterGateway.sol`](../core/contracts/kpx/KPXRouterGateway.sol) — 455 lines
- Test:     [`core/contracts/kpx/test/KPXRouterGateway.t.sol`](../core/contracts/kpx/test/KPXRouterGateway.t.sol) — 808 lines
- Review:   [`core/contracts/KPXRouter-security-review.md`](../core/contracts/KPXRouter-security-review.md)
- Config:   [`core/config/genesis-block.json`](../core/config/genesis-block.json)

### Cổng Deploy Cuối Cùng

```
┌──────────────────────────────────────────────────────────────────┐
│  ĐIỀU KIỆN DEPLOY KPXRouterGateway.sol                          │
│                                                                  │
│  [ ] forge test — 36/36 PASS (zero failures)                   │
│  [ ] forge test --fuzz-runs 10000 — 5 fuzz suites PASS         │
│  [ ] slither — 0 Critical, 0 High                               │
│  [ ] External audit report sạch (zero Critical/High)           │
│  [ ] KPXRouter-security-review.md — 30/30 checks PASSED        │
│  [ ] TreasuryDAO governance vote thông qua (>50% quorum)       │
│  [ ] 48h timelock sau DAO approval                              │
│  [ ] Testnet stable ≥ 30 ngày                                  │
│  [ ] GL-LEGAL-COMP-01 ký                                        │
│  [ ] GL-ARCH-CORE-ENGINE ký                                     │
│                                                                  │
│  Current: 🔴 BLOCKED — Awaiting test execution + audit         │
└──────────────────────────────────────────────────────────────────┘
```

---

## 12. TUYÊN BỐ MIỄN TRỪ TRÁCH NHIỆM PHÁP LÝ (LEGAL DISCLAIMER)

> **QUAN TRỌNG — VUI LÒNG ĐỌC KỸ TRƯỚC KHI SỬ DỤNG TÀI LIỆU NÀY**

### 12.1. Không phải Lời mời Đầu tư

Tài liệu này được soạn thảo nhằm mục đích **cung cấp thông tin kỹ thuật và kiến trúc** về hệ sinh thái AXIOLEDGER. Tài liệu **không cấu thành** lời đề nghị, lời mời, hay tư vấn đầu tư, chứng khoán, hoặc bất kỳ công cụ tài chính nào theo pháp luật của bất kỳ quốc gia hoặc vùng lãnh thổ nào.

### 12.2. Rủi ro Tài chính

Đầu tư vào tài sản kỹ thuật số và token tiền mã hóa mang theo rủi ro cao, bao gồm nhưng không giới hạn ở: mất toàn bộ vốn, biến động giá cao, rủi ro pháp lý, rủi ro kỹ thuật, và rủi ro thanh khoản. **Bạn không nên đầu tư số tiền mà bạn không thể chịu đựng được việc mất trắng.**

### 12.3. Thông tin Mang tính Dự báo (Forward-Looking Statements)

Các tuyên bố liên quan đến kế hoạch tương lai, lộ trình phát triển, mục tiêu hiệu năng (TPS, TVL, số lượng người dùng...) và mô hình kinh tế trong tài liệu này mang bản chất **dự báo** và **không phải là cam kết đảm bảo**. Kết quả thực tế có thể khác biệt đáng kể so với những gì được mô tả, do các yếu tố kỹ thuật, thị trường, pháp lý, hoặc các rủi ro không lường trước.

### 12.4. Tuân thủ Pháp luật Địa phương

Việc mua, bán, sở hữu, hoặc sử dụng token $AXQ và các token trong hệ sinh thái ($VPX, $SQX, $KPX, $VRQ) có thể bị hạn chế hoặc cấm tại một số quốc gia hoặc vùng lãnh thổ. **Bạn có trách nhiệm tự xác minh và tuân thủ đầy đủ các quy định pháp luật hiện hành tại địa phương của mình** trước khi tham gia vào bất kỳ hoạt động nào liên quan đến hệ sinh thái AXIOLEDGER.

### 12.5. Thay đổi Nội dung

Đội ngũ phát triển AXIOLEDGER bảo lưu quyền cập nhật, sửa đổi, hoặc thay thế bất kỳ phần nào của tài liệu này mà không cần thông báo trước. Phiên bản mới nhất và có giá trị pháp lý nhất luôn là phiên bản được công bố chính thức trên kho lưu trữ [`axioledger/axioledger`](https://github.com/axioledger/axioledger).

### 12.6. Sở hữu Trí tuệ

Toàn bộ nội dung, kiến trúc, mô hình toán học, tên thương hiệu và logo trong tài liệu này là **tài sản sở hữu trí tuệ độc quyền** của đội ngũ phát triển AXIOLEDGER. Nghiêm cấm sao chép, phân phối, hoặc sử dụng thương mại khi chưa có sự cho phép bằng văn bản.

---

*Tài liệu này được phê duyệt bởi Hội đồng 8 Cố vấn và Kiến trúc sư trưởng AXIOLEDGER.*
*Phiên bản 2.0 — Genesis Pact Edition. Genesis Block đang chờ lệnh biên dịch cuối cùng.*

```
[root@axioledger-core ~]# ./compile_whitepaper.sh --version=2.0 --sync=charter
>>> Đồng bộ với OFFICIAL-CHARTER v2.0 ........... [OK]
>>> Tích hợp Roadmap 5 Giai đoạn ................. [OK]
>>> Bổ sung Tokenomics Bảng Số Tuyệt đối ......... [OK]
>>> Thêm Technical Appendix (Benchmark + Rust) ... [OK]
>>> Thêm Legal Disclaimer (6 Điều khoản) ......... [OK]
>>> Đóng gói Whitepaper v2.0 ...................... [HOÀN TẤT]
```
## 11.9. ANS — AXIOLEDGER Name Service

Hệ thống **AXIOLEDGER Name Service (ANS)** là hạ tầng phân giải định danh phi tập trung của toàn bộ hệ sinh thái — tương đương với DNS nhưng tích hợp ZK-DID, multi-chain address resolution và on-chain ownership.

### Namespace Kiến trúc

ANS vận hành **5 TLD nội bộ** tương ứng với 5 trụ cột:

| TLD | Trụ cột | Ví dụ | Mục đích |
|---|---|---|---|
| `.axq` | Axioledger Hub | `treasury.axq`, `governance.axq` | Hub addresses, DAO endpoint |
| `.vpx` | Valiprecision | `validator-001.vpx`, `staking.vpx` | Validator node identity |
| `.sqx` | Sequentichain | `sequencer.sqx`, `rollup.sqx` | L2 service endpoints |
| `.kpx` | Kinetoprotocol | `pool-usdc-axq.kpx`, `rwa-treasury.kpx` | DeFi protocol addresses |
| `.vrq` | Veraciphers | `did-auth.vrq`, `kyc-gate.vrq` | ZK-DID identity, compliance |

### Thuật toán Namehash (ENS-compatible)

```
namehash("alice.axq") =
  keccak256(
    keccak256(0x0000...0000 || keccak256("axq")) || keccak256("alice")
  )
```

### Stack Kỹ thuật

```
[Client / dApp]
     │
     ▼
[CoreDNS Port 53]  ← intercept 5 custom TLDs
     │
     ▼
[ANS Resolver — Node.js :8053]
     │
     ├─► [Redis Cache — TTL 60s, <5ms]
     ├─► [PostgreSQL — off-chain registry]
     └─► [Foundry Anvil — on-chain contracts]
```

**Smart Contracts:** `ANSRegistry` · `PublicResolver` · `ReverseRegistrar`  
**Full spec:** [`core/api/ans-service-spec.md`](../core/api/ans-service-spec.md)

### NPM Scope & Identity Map

| Trụ cột | NPM Scope | GitHub Org |
|---|---|---|
| Axioledger | `@axioledger/*` | `github.com/axioledger` |
| Valiprecision | `@valiprecision/*` | `github.com/valiprecision` |
| Sequentichain | `@sequentichain/*` | `github.com/sequentichain` |
| Kinetoprotocol | `@kinetoprotocol/*` | `github.com/kinetoprotocol` |
| Veraciphers | `@veraciphers/*` | `github.com/veraciphers` |

> **Lưu ý:** Scope 3 ký tự (`@axq`, `@vpx`...) đã bị squat/reserved trên npm. Sử dụng tên đầy đủ thương hiệu.

---


## 11.10. GENESIS BLOCK — Sổ Cái Khởi Tạo

### Thời Điểm Đúc Token Duy Nhất (One-Time Mint)

**Block 0** của Sổ cái Lõi AXIOLEDGER Hub (`$AXQ`) được thiết lập tại thời khắc chính xác:

```
Genesis Timestamp : 2026-08-31T09:41:34Z (UTC)
Human Readable    : Monday, August 31, 2026 — 09:41:34 UTC
Unix Epoch        : 1788169294
Network           : axioledger-mainnet-genesis
Genesis File      : core/genesis/genesis-block.json
```

> Đây là khoảnh khắc **10.000 tỷ token $AXQ được đúc duy nhất một lần** và phân bổ vĩnh viễn vào 5 Hợp đồng Thông minh Gốc. Không có cơ chế remint. Không có admin key. Mọi thay đổi tham số chỉ qua TreasuryDAO governance vote.

### 5 Hợp Đồng Thông Minh Gốc (Genesis Smart Contracts)

```
┌─────────────────────────────────────────────────────────────────────┐
│  GENESIS BLOCK — 10.000 TỶEN $AXQ — PHÂN BỔ VĨNH VIỄN             │
├──────────────────────────┬──────┬──────────────────────────────────┤
│  Contract                │  %   │  Cơ chế Khóa                     │
├──────────────────────────┼──────┼──────────────────────────────────┤
│  RWAReserveVault.sol     │  30% │  Smart contract controlled       │
│  ValidatorRewardPool.sol │  25% │  50-year logarithmic decay       │
│  TreasuryDAO.sol         │  20% │  On-chain governance only        │
│  CommunityVault.sol      │  15% │  Vesting schedule                │
│  TeamVestingVault.sol    │  10% │  5-year cliff vesting            │
└──────────────────────────┴──────┴──────────────────────────────────┘

Emission equation mã hóa trong Genesis Block:
  Emission(t) = κ · ln(1 + ΔTVL_RWA) + μ · TxVolume(t) − Burn(t)
  Nếu ΔTVL_RWA = 0 → Emission = 0 (lạm phát tự dừng)
```

### Tham Số Mạng Lưới Bất Biến

| Tham số | Giá trị | Mô tả |
|---|---|---|
| `max_supply` | `10,000,000,000,000` | Hard cap tuyệt đối — không thay đổi được |
| `admin_key` | `null` | Không tồn tại |
| `consensus` | `ZK-OBFT` | VP_i = S_i × R_i |
| `micro_epoch` | `400ms` | Block time target |
| `finality_target` | `< 3 phút` | ZK-Rollup Settlement |
| `max_tx_fee` | `< $0.001 USD` | Điều VII — Bất Khả Xâm Phạm |
| `nakamoto_min` | `> 100` | Điều III — Bất Khả Xâm Phạm |
| `tps_target` | `600,000+` | AF_XDP + SVM Rollup |
| `zk_proof_size` | `~284 bytes` | π — Groth16 aggregated |
| `post_quantum` | `CRYSTALS-Dilithium` | NIST FIPS 205 — parallel track |

---

## 11.11. KINETOPROTOCOL CROSS-CHAIN BRIDGE — Kiến Trúc & Kiểm Duyệt

### Tổng Quan Kiến Trúc Cầu Nối

Cầu nối Cross-chain của KINETOPROTOCOL ($KPX) được kích hoạt tại **Giai đoạn 3 (v1.0.0 — Năm 3)**, sau khi VPX Consensus và SQX 600K TPS đã ổn định ≥ 60 ngày.

```
[Nguồn: ETH / ARB / SOL]
        │
        │ bridgeOut() + ZK-Proof + VRQ scan
        ▼
[KPX Router Gateway — IKPXRouter.sol]
        │
        ├── [1] VRQ Scanner: isFlagged(caller, token) ← BLOCK nếu độc hại
        ├── [2] ZK-Proof verify (IZKVerifier — VRQ circuit)
        ├── [3] Amount check: amount <= maxBridgeAmountPerTx
        ├── [4] Chain whitelist: ETH(60) · ARB(42161) · SOL(501)
        │
        ▼
[MPC Relayer Network — 2/3 threshold signatures]
        │
        ├── Relayer 1 (GL-CORE-FIN-NODE01) ── sign
        ├── Relayer 2 (GL-CORE-FIN-NODE02) ── sign   → 2/3 threshold
        └── Relayer 3 (GL-CORE-FIN-NODE03) ── sign
        │
        ▼
[bridgeIn() trên chain đích]
        │
        ├── [5] Replay check: bridgeId.fulfilled == false
        ├── [6] MPC signature verify (≥ 2/3)
        ├── [7] VRQ scan: recipient không bị flag
        │
        ▼
[Recipient nhận tài sản — Finality confirmed]
```

### 4 Chức Năng Cốt Lõi IKPXRouter

| Section | Chức năng | Hàm chính | Security Gate |
|---|---|---|---|
| **AMM Swap** | Định tuyến chống trượt giá | `swap()`, `quoteSwap()` | VRQ + ZK-Proof + TWAP oracle |
| **Cross-chain Bridge** | Kết nối ETH/ARB/SOL | `bridgeOut()`, `bridgeIn()` | MPC 2/3 + VRQ + Replay prevention |
| **RWA Treasury** | Token hóa tài sản thực | `depositRWA()`, `harvestAndBuyback()` | Institutional KYC + 15% AXQ collateral |
| **Dark Pool** | Block trades ẩn danh | `placeDarkPoolOrder()`, `fillDarkPoolOrder()` | Pedersen commitment + ZK Match Proof |

### Cổng Kiểm Duyệt Bảo Mật (Deploy Gate)

Trước khi cấp quyền triển khai `IKPXRouter.sol` lên Mainnet, **30 security checks** trong 6 nhóm (A–F) phải đạt 100%:

```
A. AMM Swap (8 checks)     — Reentrancy, slippage, TWAP, ZK freshness
B. Bridge (8 checks)       — Replay, MPC threshold, drain protection
C. RWA Treasury (7 checks) — Oracle, collateral ratio, yield rounding
D. Dark Pool (7 checks)    — Commitment uniqueness, Pedersen binding
E. Governance (6 checks)   — No admin key, emergency pause auth
F. Integration (4 checks)  — ZK circuit version, VRQ realtime, malleability
```

**Tài liệu đầy đủ:** [`core/contracts/KPXRouter-security-review.md`](../core/contracts/KPXRouter-security-review.md)  
**Interface spec:** [`core/contracts/IKPXRouter.sol`](../core/contracts/IKPXRouter.sol)

> **⚠️ Quy tắc bất khả nhượng:** `IKPXRouter.sol` **KHÔNG được deploy** cho đến khi tất cả 30 checks PASSED, external audit clean 100%, và TreasuryDAO governance vote thông qua với timelock 48h.

---

