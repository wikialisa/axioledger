## Mô tả thay đổi
<!-- Mô tả ngắn gọn những gì PR này thay đổi -->

## Loại thay đổi
- [ ] Feature — Swift Bridge (B1–B5)
- [ ] Bugfix
- [ ] Security patch
- [ ] Config / Infrastructure (DP-4)
- [ ] Solidity contract (`axioledger-system` / `kpx-liquidity` / `vrq-circuits`)
- [ ] ZK Circuit (`vrq-circuits`, `zkp-crypto-lib`)
- [ ] CI/CD (`.github/workflows/`)
- [ ] Documentation

## Checklist bảo mật (bắt buộc mọi PR)
- [ ] **KHÔNG** commit `config-swift-mgw.yaml` cleartext — chạy `encrypt.sh` trước
- [ ] **KHÔNG** commit `*.jks`, `*.p12`, `*.pem`, `*.key` (keystore/private key)
- [ ] **KHÔNG** commit credentials, API keys, passwords trong bất kỳ file nào
- [ ] PII từ SWIFT xử lý **off-chain** qua `SwiftVrqAmlChecker` → VRQ ZK-Proof trước khi on-chain (DP-3)
- [ ] Đã chạy soft tests cục bộ — tất cả xanh
- [ ] Đã review `CODEOWNERS` — đúng reviewer được chỉ định

## Checklist CI (tự động — KHÔNG merge nếu đỏ)
- [ ] `🔐 Swift Security Gate` — TruffleHog + cleartext config check ✅
- [ ] `☕ Swift Bridge — Build & Soft Tests` ✅
- [ ] `🔒 DP-3 PII Audit` ✅ (nếu thay đổi `vrq/` hoặc `gpi/model/`)
- [ ] `🔷 Solidity Contracts` ✅ (nếu thay đổi `smart-contracts/`)

## Reviewer cần thiết (theo CODEOWNERS)
- [ ] @davictran76 — Lead Engineer (bắt buộc mọi PR)
- [ ] @security-lead — bắt buộc nếu thay đổi `vrq/`, `keys/`, `config/`, `.github/workflows/`
- [ ] @contract-auditor — bắt buộc nếu thay đổi `smart-contracts/`
- [ ] @sysadmin-lead — bắt buộc nếu thay đổi `swift-server/`

## Liên quan đến Giai đoạn (Roadmap)
- [ ] **Giai đoạn A** — Hạ tầng (đang triển khai 🟢)
- [ ] **Giai đoạn B** — Swift Bridge development (Tuần 3–5 🟢)
- [ ] **Giai đoạn C** — Testing (Tuần 6–7 🟢)
- [ ] **Giai đoạn D** — Production Rollout (🔒 KHÓA — chỉ sau TGE + DP-5)

## Testing
<!-- Mô tả cách test PR này -->
- [ ] Đã chạy: `mvn test -Dtest="**/soft/**Test"` → ✅
- [ ] Đã chạy: `forge test -vvv` (nếu contracts thay đổi) → ✅
- [ ] Đã test thủ công (nếu có) — mô tả:

## Notes cho reviewer
<!-- Bất kỳ thông tin bổ sung nào -->
