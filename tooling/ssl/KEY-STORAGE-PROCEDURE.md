# SSL/TLS Key Storage Procedure — AXIOLEDGER

**Classification:** INTERNAL — RESTRICTED  
**Owner:** AXIOLEDGER Core Engineering  
**Last reviewed:** 2026-09-03  
**Next review:** 2027-03-03

---

## 1. Scope

This document covers the storage, rotation, and access control procedures for all SSL/TLS private keys and certificates used across the AXIOLEDGER infrastructure, including:

- Protocol endpoints (`axqchain.axq`, `axqprotocol.axq`, `kpxprotocol.kpx`, etc.)
- GitHub Actions deployment secrets
- SWIFT gateway mTLS keypairs
- PKI/identity declaration signing keys

---

## 2. Key Storage Locations

| Key type | Storage location | Access |
|---|---|---|
| Server TLS private keys | `/root/ssl/pki/` | root-only (chmod 600) |
| GPIA trust anchors | `/root/ssl/gpia/` | root-only (chmod 644) |
| Identity declaration | `/root/ssl/pki/export/identity-declaration.json` | root-only |
| GitHub Actions secrets | GitHub Org → Settings → Secrets | CI/CD only |
| SWIFT gateway keypairs | `/root/core/banking/swift-gateway/src/main/resources/` (encrypted) | JVM keystore |

---

## 3. File Permissions

All private key material MUST be stored with the following permissions:

```bash
# Private keys
chmod 600 /root/ssl/pki/*.key
chmod 600 /root/ssl/pki/**/*.key

# Certificate bundles (public)
chmod 644 /root/ssl/pki/*.crt
chmod 644 /root/ssl/gpia/*.pem

# Directory permissions
chmod 700 /root/ssl/pki/
chmod 755 /root/ssl/gpia/
```

---

## 4. Key Rotation Schedule

| Key / Certificate | Rotation frequency | Responsible |
|---|---|---|
| Server TLS (Let's Encrypt) | 90 days (automated via `setup-letsencrypt.sh`) | DevOps |
| SWIFT gateway mTLS | 12 months | Core Engineering |
| PKI identity signing key | 24 months or on personnel change | Security Lead |
| GitHub Deploy keys | 12 months or on team change | DevOps |

Rotation is tracked in the GitHub Audit log (see `core/github/w7-audit.sh`).

---

## 5. Emergency Key Revocation

In the event of a suspected key compromise:

1. **Immediately** revoke the key at the CA / GitHub / SWIFT provider.
2. Generate a new keypair: `openssl genrsa -out new.key 4096`
3. Submit a new CSR to the appropriate CA.
4. Update all consuming services and restart.
5. File an incident report in the `AUDIT-REPORT.md` and notify the Cố vấn Đặc biệt.
6. Rotate any GitHub Actions secrets that may have been exposed.

---

## 6. Backup & Recovery

- Private keys are **never** committed to git.
- Keys are backed up to an encrypted offline vault (Bitwarden Business or equivalent) immediately after generation.
- Recovery requires dual approval from Core Engineering Lead + Security Lead.
- Backup integrity is verified every 6 months using `core/scripts/integrity-check.js`.

---

## 7. Identity Declaration

The file `identity-declaration.json` at `/root/axioledger-monorepo/ssl/pki/export/identity-declaration.json` is the canonical copy.  
The root-level copy at `/root/axioledger-monorepo/identity-declaration.json` should be a symlink:

```bash
cd /root/axioledger-monorepo
ln -sf ssl/pki/export/identity-declaration.json identity-declaration.json
```

---

## 8. Compliance

This procedure satisfies:
- ISO 27001 A.10.1 (Cryptographic controls)
- SOC 2 CC6.7 (Restriction of Encryption Keys)
- Internal AXIOLEDGER Security Policy v1.2

---

*AXIOLEDGER Core Engineering — security@axioledger.io*
