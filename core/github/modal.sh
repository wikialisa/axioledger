#!/usr/bin/env bash
# AXIOLEDGER — OMNI GITHUB AUTOMATION CONTROLLER v0.0.0
# "Hệ thần kinh trung ương" — điều phối toàn bộ 7 workflows
# Usage: ./modal.sh

source "$(dirname "$0")/bootstrap.sh"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

header() {
cat <<'HDR'

════════════════════════════════════════════════════════════════════════════════
           AXIOLEDGER — OMNI GITHUB AUTOMATION CONTROLLER  v0.0.0
════════════════════════════════════════════════════════════════════════════════
 Service Account : 315885655+davictran76@users.noreply.github.com
 Node            : axioledger-devnode · 192.168.0.47 (wifi0, LAN Primary)
 Token Status    : [🟢 ACTIVE] — Super Admin (Full Scope)
 Organizations   : axioledger · kinetoprotocol · sequentichain
                   valiprecision · veraciphers
────────────────────────────────────────────────────────────────────────────────
 API GATEWAY     : https://api.axioledger.axq/v1/
   /core/  → Hub $AXQ       /vp/  → VALIPRECISION $VPX
   /sqx/   → SEQUENTICHAIN  /kpx/ → KINETOPROTOCOL $KPX
   /vrq/   → VERACIPHERS
 Schema          : core/api/api-schema-v0.0.0.md
────────────────────────────────────────────────────────────────────────────────
 CHỌN WORKFLOW:

  [1]  Tạo Repository đồng nhất xuyên 5 tổ chức
  [2]  Đồng bộ bản vá bảo mật (VRQ → Cross-Org Patch)
  [3]  Áp dụng Branch Protection hàng loạt (dev/ledger/master/main)
  [4]  Luân chuyển Secrets & API Keys (24h Auto-Rotation)
  [5]  Tạo / Cập nhật GitHub Projects v2 (Kanban Board)
  [6]  Kích hoạt GitHub Actions Workflow xuyên tổ chức
  [7]  Kiểm toán toàn diện — Audit Snapshot → JSON

  [0]  Thoát

────────────────────────────────────────────────────────────────────────────────
HDR
}

while true; do
  clear
  header
  read -rp "  Lựa chọn [0-7]: " CHOICE

  case "$CHOICE" in
    1)
      read -rp  "  Tên repo        : " R
      read -rp  "  Mô tả           : " D
      read -rp  "  Visibility [public/private]: " V
      bash "$SCRIPT_DIR/w1-create-repo.sh" "$R" "$D" "${V:-public}"
      ;;
    2)
      read -rp  "  Tên repo đích   : " R
      read -rp  "  Đường dẫn file  : " F
      read -rp  "  Commit message  : " M
      bash "$SCRIPT_DIR/w2-security-patch.sh" "$R" "$F" "${M:-"fix(security): auto-patch"}"
      ;;
    3)
      read -rp  "  Tên repo        : " R
      bash "$SCRIPT_DIR/w3-branch-protection.sh" "$R"
      ;;
    4)
      read -rp  "  Tên secret      : " S
      read -rsp "  Giá trị (ẩn)   : " V; echo
      bash "$SCRIPT_DIR/w4-rotate-secrets.sh" "$S" "$V"
      ;;
    5)
      read -rp  "  Tên project     : " T
      bash "$SCRIPT_DIR/w5-projects.sh" "${T:-"AXIOLEDGER Roadmap v0.0.0"}"
      ;;
    6)
      read -rp  "  Tên repo        : " R
      read -rp  "  Workflow file   : " W
      read -rp  "  Branch [main]   : " B
      bash "$SCRIPT_DIR/w6-trigger-actions.sh" "$R" "${W:-deploy.yml}" "${B:-main}"
      ;;
    7)
      bash "$SCRIPT_DIR/w7-audit.sh"
      ;;
    0)
      echo ""; echo "  Genesis Pact — Always Running. Thoát."
      exit 0
      ;;
    *)
      echo "  [!] Không hợp lệ — chọn 0–7"
      ;;
  esac

  echo ""; read -rp "  Nhấn Enter để quay lại menu..." _
done
