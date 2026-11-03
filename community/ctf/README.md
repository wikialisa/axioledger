# CTF Framework — Security Learning Platform

> **Học bảo mật smart contract từ lỗi thật trong audit DeFi & SWIFT-bridge**

Thư mục này chứa 5 challenge tái hiện lỗ hổng logic thực tế,
được thiết kế cho sinh viên, nhà phát triển và security researcher.

---

## Danh sách Challenge

| # | Tên | Lỗ hổng | Độ khó | Tổn thất thực tế |
|---|-----|---------|--------|-----------------|
| 01 | [Reentrancy](./challenges/reentrancy/) | External call trước state update | ⭐⭐ | TheDAO $60M, Cream $130M |
| 02 | [Oracle Manipulation](./challenges/oracle-manipulation/) | Spot price từ AMM bị flash-loan | ⭐⭐⭐ | Mango $114M, Beanstalk $181M |
| 03 | [Access Control Bypass](./challenges/access-control-bypass/) | Missing `Signer` constraint | ⭐⭐ | Wormhole $320M |
| 04 | [Flash Loan + Overflow](./challenges/flash-loan-attack/) | Integer overflow trong fee calc | ⭐⭐⭐ | Euler $197M, Safemoon |
| 05 | [Signature Replay](./challenges/signature-replay/) | Missing nonce/expiry | ⭐⭐ | ERC-2612, SWIFT double-payment |

---

## Cách chạy challenges

```bash
# Cài Rust + Anchor toolchain
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
cargo install --git https://github.com/coral-xyz/anchor anchor-cli

# Build tất cả challenges
cd community/ctf
cargo build --workspace

# Chạy tests cho một challenge cụ thể
cargo test -p ctf-reentrancy -- --nocapture
cargo test -p ctf-oracle-manipulation -- --nocapture
cargo test -p ctf-access-control-bypass -- --nocapture
cargo test -p ctf-flash-loan-attack -- --nocapture
cargo test -p ctf-signature-replay -- --nocapture
```

---

## Cấu trúc một Challenge

```
challenges/<name>/
├── Cargo.toml          ← package metadata
└── src/
    └── lib.rs          ← vulnerable + fixed implementation
                          + quiz questions + exploitation hints
```

Mỗi file `lib.rs` có:
- **`*_vulnerable`** — hàm lỗi để phân tích
- **`*_fixed`** — hàm đã sửa với pattern đúng
- **CTF Notes** — quiz questions và bonus challenges

---

## Luồng học tập đề xuất

```
1. Đọc lib.rs, tìm hàm *_vulnerable
           │
           ▼
2. Phân tích tại sao bị khai thác
           │
           ▼
3. Chạy axio-run (VM) để trace execution
   axio-run --bytecode <compiled_hex> --trace
           │
           ▼
4. Viết test chứng minh exploit
           │
           ▼
5. Đọc *_fixed, hiểu pattern sửa
           │
           ▼
6. Dùng axio-verify để hash-check artifact
   axio-verify --artifact build/<program>.so
```

---

## Kết nối với codebase thực tế

| Challenge | Liên hệ tới |
|-----------|-------------|
| Reentrancy | `programs/p2p-escrow` — withdraw flow |
| Oracle Manipulation | `programs/amm-swap` — price oracle, `programs/treasury-rbs` — RBS bounds |
| Access Control | `packages/contracts/modules/ROLES/` — on-chain role system |
| Flash Loan | `programs/amm-swap` — liquidity pool, `packages/contracts/policies/RangeBound.sol` |
| Signature Replay | `programs/swift-bridge` — UETR nonce, `packages/swift-adapter` — LAU auth |

---

## Đóng góp Challenge mới

1. Tạo thư mục `challenges/<name>/`
2. Thêm `Cargo.toml` + `src/lib.rs` theo template
3. Thêm vào `ctf/Cargo.toml` workspace members
4. Cập nhật bảng trên và mở Pull Request

> **Lưu ý:** Không đưa exploit code thật vào. Chỉ mô tả pattern lỗ hổng
> và yêu cầu người học tự viết exploit trong môi trường sandbox.
