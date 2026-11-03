# swift-server — SWIFT MGW Sandboxed Directory (DP-4)

> **PCI DSS Level 1 — Dedicated Server / Sandboxed Directory**
> Theo chỉ đạo DP-4: tách biệt hoàn toàn khỏi `sqx-rollup-core` và blockchain nodes.

## Cấu trúc thư mục

```
./swift-server/
  bin/          Scripts: start, stop, encrypt, decrypt, health-check
  config/       config-swift-mgw.enc + secret.ks (KHÔNG lưu .yaml)
  db/           H2 AES-encrypted database (mgwdb.mv.db)
  keys/         chmod 600 — JKS keystores (KHÔNG commit vào git)
  lib/          swift-mgw-2.0.17-1.jar + internal/swift-security-sdk jar
  log/          mgw.log (max 10MB, 7 ngày)
  oas/          OpenAPI specs + local-api-repository/
```

## RBAC (DP-4)

| Role | Quyền |
|---|---|
| Infrastructure Root / SysAdmin | ✅ Full |
| Security Engineer | ✅ `keys/` + `config/` only |
| Backend Engineer | ✅ Deploy/log (không root) |
| Legal Officer | ❌ Không có SSH access |
| Blockchain Validator / Node Operator | ❌ BLOCKED hoàn toàn |

## Setup

```bash
bash bin/setup.sh
```

## Khởi động

```bash
bash bin/start.sh
# Health check
bash bin/health-check.sh
```

## Bảo mật bắt buộc

- KHÔNG bao giờ lưu `config-swift-mgw.yaml` cleartext
- Chạy `bin/encrypt.sh` ngay sau khi điền config
- `keys/` — chmod 600, chỉ SysAdmin
- Port 9003: chỉ mở cho Bridge Layer (localhost), KHÔNG expose public
