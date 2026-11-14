"use client";
export const dynamic = 'force-dynamic';
/**
 * /admin/users — User Management
 * Search, filter by status/KYC, lock/unlock/suspend accounts
 */
import React, { useState } from "react";
import {
  DataTable, Button, Text, Badge, Input, Modal,
  type DataTableColumn,
  Search, Lock, CheckCircle, AlertCircle,
} from "ui-kit";

interface UserRow {
  userId:        string;
  fullName:      string;
  phone:         string;
  kycStatus:     string;
  kycTier:       number;
  accountStatus: "ACTIVE" | "LOCKED" | "SUSPENDED";
  createdAt:     string;
  totalVolume:   string;
}

const MOCK_USERS: UserRow[] = [
  { userId: "u001", fullName: "Nguyễn Văn A", phone: "0901234567", kycStatus: "VERIFIED",   kycTier: 2, accountStatus: "ACTIVE",    createdAt: "15/01/2024", totalVolume: "50.000.000đ" },
  { userId: "u002", fullName: "Trần Thị B",   phone: "0912345678", kycStatus: "PENDING",    kycTier: 1, accountStatus: "ACTIVE",    createdAt: "10/02/2024", totalVolume: "5.000.000đ"  },
  { userId: "u003", fullName: "Lê Minh C",    phone: "0923456789", kycStatus: "VERIFIED",   kycTier: 2, accountStatus: "LOCKED",    createdAt: "05/03/2024", totalVolume: "0đ"           },
  { userId: "u004", fullName: "Phạm Quốc D",  phone: "0934567890", kycStatus: "REJECTED",   kycTier: 1, accountStatus: "SUSPENDED", createdAt: "20/03/2024", totalVolume: "800.000đ"    },
  { userId: "u005", fullName: "Hoàng Thị E",  phone: "0945678901", kycStatus: "VERIFIED",   kycTier: 2, accountStatus: "ACTIVE",    createdAt: "01/04/2024", totalVolume: "12.000.000đ" },
];

const STATUS_COLOR: Record<string, "success" | "error" | "warning"> = { ACTIVE: "success", LOCKED: "error", SUSPENDED: "warning" };
const KYC_COLOR:    Record<string, "success" | "warning" | "error" | "info"> = { VERIFIED: "success", PENDING: "warning", REJECTED: "error", SUSPENDED: "info" };

export default function AdminUsersPage() {
  const [users,       setUsers]       = useState<UserRow[]>(MOCK_USERS);
  const [search,      setSearch]      = useState("");
  const [actionModal, setActionModal] = useState<{ user: UserRow; action: "LOCKED" | "ACTIVE" | "SUSPENDED" } | null>(null);
  const [loading,     setLoading]     = useState(false);

  const filtered = users.filter(u =>
    u.fullName.toLowerCase().includes(search.toLowerCase()) ||
    u.phone.includes(search) ||
    u.userId.includes(search)
  );

  const handleStatusChange = async () => {
    if (!actionModal) return;
    setLoading(true);
    await new Promise(r => setTimeout(r, 800));
    setUsers(prev => prev.map(u => u.userId === actionModal.user.userId ? { ...u, accountStatus: actionModal.action } : u));
    setLoading(false);
    setActionModal(null);
  };

  const columns: DataTableColumn[] = [
    { key: "fullName",      label: "Tên",         render: (_, row) => <Text variant="body2" weight="semibold" color="#1A1F36">{(row as UserRow).fullName}</Text> },
    { key: "phone",         label: "SĐT",         render: (_, row) => <Text variant="caption" color="#4A5568">{(row as UserRow).phone}</Text> },
    { key: "kycStatus",     label: "KYC",         render: (_, row) => <Badge variant="label" color={KYC_COLOR[(row as UserRow).kycStatus] ?? "info"} label={(row as UserRow).kycStatus} /> },
    { key: "accountStatus", label: "Trạng thái",  render: (_, row) => <Badge variant="label" color={STATUS_COLOR[(row as UserRow).accountStatus]} label={(row as UserRow).accountStatus} /> },
    { key: "totalVolume",   label: "Volume",      render: (_, row) => <Text variant="caption" color="#1A1F36">{(row as UserRow).totalVolume}</Text> },
    { key: "createdAt",     label: "Ngày tạo",    render: (_, row) => <Text variant="caption" color="#A0AEC0">{(row as UserRow).createdAt}</Text> },
    {
      key: "actions", label: "Thao tác",
      render: (_, row) => (
        <div style={{ display: "flex", gap: 6 }}>
          {(row as UserRow).accountStatus === "ACTIVE"
            ? <Button variant="outlined" color="error"   size="sm" onClick={() => setActionModal({ user: v as UserRow, action: "LOCKED" })}>Khoá</Button>
            : <Button variant="outlined" color="success" size="sm" onClick={() => setActionModal({ user: v as UserRow, action: "ACTIVE" })}>Mở</Button>
          }
          {(row as UserRow).accountStatus !== "SUSPENDED" && (
            <Button variant="outlined" color="dark" size="sm" onClick={() => setActionModal({ user: v as UserRow, action: "SUSPENDED" })}>Đình chỉ</Button>
          )}
        </div>
      ),
    },
  ];

  return (
    <div style={{ padding: "24px 24px 40px" }}>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 20 }}>
        <div>
          <Text variant="h5" weight="semibold" color="#1A1F36">Quản lý người dùng</Text>
          <Text variant="caption" color="#A0AEC0">{users.length} tài khoản</Text>
        </div>
      </div>

      <div style={{ marginBottom: 16 }}>
        <Input placeholder="Tìm tên, SĐT, ID…" iconLeft={<Search size={16} />} value={search} onChange={e => setSearch(e.target.value)} />
      </div>

      <div style={{ background: "#fff", borderRadius: 16, overflow: "hidden", boxShadow: "0 1px 4px rgba(0,0,0,0.06)" }}>
        <DataTable columns={columns} data={filtered as unknown as Record<string, unknown>[]} />
      </div>

      {/* Action confirm modal */}
      <Modal
        open={!!actionModal}
        onClose={() => setActionModal(null)}
        variant="center"
        title={actionModal?.action === "LOCKED" ? "Khoá tài khoản?" : actionModal?.action === "SUSPENDED" ? "Đình chỉ tài khoản?" : "Mở tài khoản?"}
        subtitle={`${actionModal?.user.fullName} · ${actionModal?.user.phone}`}
        footer={
          <div style={{ display: "flex", gap: 10 }}>
            <Button variant="outlined" color="dark" size="lg" fullWidth onClick={() => setActionModal(null)}>Huỷ</Button>
            <Button
              variant="filled"
              color={actionModal?.action === "ACTIVE" ? "success" : "error"}
              size="lg" fullWidth loading={loading}
              onClick={handleStatusChange}
            >
              Xác nhận
            </Button>
          </div>
        }
      />
    </div>
  );
}
