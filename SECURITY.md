# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| Latest `main` | ✅ |
| Previous minor | ✅ (90 days) |
| Older | ❌ |

## Reporting a Vulnerability

**Do NOT open a public GitHub issue for security vulnerabilities.**

Report privately via:
- **Email:** security@axqprotocol.axq
- **GPG Key:** `0xAXIOLEDGER_SECURITY_KEY` (available at keybase.io/axioledger)
- **Response SLA:** 24 hours acknowledgment, 7 days triage, 30 days patch

## Scope

In scope:
- Smart contracts (`smart-contracts/`)
- Cryptographic libraries (`packages/zkp-crypto-lib/`)
- ZK circuits (`smart-contracts/vrq-circuits/`)
- Key management in `core-nodes/`

Out of scope:
- Frontend UI/UX cosmetic issues
- Theoretical attacks with no practical impact
- Issues in dependencies — report upstream first

## Disclosure Policy

We follow coordinated disclosure. Researchers are credited in release notes unless they prefer anonymity. Bug bounties are awarded in $AXQ for qualifying critical vulnerabilities.
