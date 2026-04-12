"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { getUsers, createUser, updateUser, deleteUser } from "@/lib/api";
import { relativeTime } from "@/lib/utils";
import { toast } from "sonner";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetFooter,
} from "@/components/ui/sheet";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { MoreHorizontal, UserPlus, Download, MessageCircle, Car } from "lucide-react";

interface User {
  id: number;
  email: string;
  name: string | null;
  phone: string | null;
  role: string;
  isActive: boolean;
  createdAt: string;
  vehicleCount: number;
}

type Filter = "all" | "active" | "inactive";

function exportCSV(users: User[]) {
  const headers = ["ID", "Name", "Email", "Phone", "Role", "Status", "Vehicles", "Joined"];
  const rows = users.map((u) => [
    u.id,
    u.name ?? "",
    u.email,
    u.phone ?? "",
    u.role,
    u.isActive !== false ? "Active" : "Inactive",
    u.vehicleCount ?? 0,
    u.createdAt ? new Date(u.createdAt).toLocaleDateString() : "",
  ]);
  const csv = [headers, ...rows].map((r) => r.map(String).join(",")).join("\n");
  const blob = new Blob([csv], { type: "text/csv" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = `users-${new Date().toISOString().slice(0, 10)}.csv`;
  a.click();
  URL.revokeObjectURL(url);
}

export default function UsersPage() {
  const router = useRouter();
  const [users, setUsers] = useState<User[]>([]);
  const [search, setSearch] = useState("");
  const [filter, setFilter] = useState<Filter>("all");
  const [loading, setLoading] = useState(true);

  const [sheetOpen, setSheetOpen] = useState(false);
  const [editUser, setEditUser] = useState<User | null>(null);
  const [form, setForm] = useState({ email: "", password: "", name: "", phone: "", role: "user" });
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  function refresh() {
    return getUsers().then((r) => setUsers(r.data));
  }

  useEffect(() => {
    refresh().finally(() => setLoading(false));
  }, []);

  function openCreate() {
    setEditUser(null);
    setForm({ email: "", password: "", name: "", phone: "", role: "user" });
    setError("");
    setSheetOpen(true);
  }

  function openEdit(u: User) {
    setEditUser(u);
    setForm({ email: u.email, password: "", name: u.name ?? "", phone: u.phone ?? "", role: u.role });
    setError("");
    setSheetOpen(true);
  }

  async function handleSave() {
    setSaving(true);
    setError("");
    try {
      if (editUser) {
        const payload: Record<string, unknown> = { name: form.name, phone: form.phone, role: form.role };
        if (form.password) payload.password = form.password;
        await updateUser(editUser.id, payload);
        toast.success("User updated", { description: form.name || editUser.email });
      } else {
        await createUser({ email: form.email, password: form.password, name: form.name, phone: form.phone, role: form.role });
        toast.success("User created", { description: form.email });
      }
      await refresh();
      setSheetOpen(false);
    } catch (e: unknown) {
      const msg = (e as { response?: { data?: { message?: string | string[] } } })?.response?.data?.message;
      const text = Array.isArray(msg) ? msg.join(", ") : (msg ?? "An error occurred");
      setError(text);
      toast.error("Failed to save user", { description: text });
    } finally {
      setSaving(false);
    }
  }

  async function handleToggleActive(u: User) {
    try {
      await updateUser(u.id, { isActive: !u.isActive });
      await refresh();
      toast.success(u.isActive ? "User deactivated" : "User activated", { description: u.name || u.email });
    } catch {
      toast.error("Failed to update user");
    }
  }

  async function handleDelete(u: User) {
    if (!confirm(`Permanently deactivate ${u.email}?`)) return;
    try {
      await deleteUser(u.id);
      await refresh();
      toast.success("User deactivated", { description: u.email });
    } catch {
      toast.error("Failed to deactivate user");
    }
  }

  const counts = {
    all: users.length,
    active: users.filter((u) => u.isActive !== false).length,
    inactive: users.filter((u) => u.isActive === false).length,
  };

  const filtered = users.filter((u) => {
    const q = search.toLowerCase();
    const match =
      u.name?.toLowerCase().includes(q) ||
      u.email?.toLowerCase().includes(q) ||
      u.phone?.includes(search);
    if (!match) return false;
    if (filter === "active") return u.isActive !== false;
    if (filter === "inactive") return u.isActive === false;
    return true;
  });

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold">Users</h1>
        <div className="flex items-center gap-2">
          <Button variant="outline" size="sm" onClick={() => exportCSV(filtered)} className="gap-1.5">
            <Download className="h-3.5 w-3.5" />
            Export CSV
          </Button>
          <Button onClick={openCreate} size="sm">
            <UserPlus className="h-4 w-4 mr-2" />
            New User
          </Button>
        </div>
      </div>

      <div className="flex gap-2 mb-4">
        {(["all", "active", "inactive"] as Filter[]).map((f) => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            className={`px-3 py-1 rounded-full text-sm font-medium border transition-colors capitalize ${
              filter === f
                ? "bg-trackeo-primary text-white border-trackeo-primary"
                : "bg-card text-muted-foreground border-border hover:text-foreground"
            }`}
          >
            {f} ({counts[f]})
          </button>
        ))}
      </div>

      <div className="mb-4">
        <Input
          placeholder="Search by name, email or phone..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="max-w-sm"
        />
      </div>

      <div className="rounded-md border bg-card">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Name</TableHead>
              <TableHead>Email</TableHead>
              <TableHead>Phone</TableHead>
              <TableHead>Vehicles</TableHead>
              <TableHead>Role</TableHead>
              <TableHead>Status</TableHead>
              <TableHead>Joined</TableHead>
              <TableHead className="w-12"></TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {loading ? (
              Array.from({ length: 5 }).map((_, i) => (
                <TableRow key={i}>
                  {Array.from({ length: 8 }).map((_, j) => (
                    <TableCell key={j}><Skeleton className="h-4 w-full" /></TableCell>
                  ))}
                </TableRow>
              ))
            ) : filtered.length === 0 ? (
              <TableRow>
                <TableCell colSpan={8} className="py-12 text-center">
                  <p className="text-muted-foreground font-medium">No users found.</p>
                  {filter !== "all" && (
                    <button className="mt-1 text-xs text-primary underline" onClick={() => setFilter("all")}>
                      Show all users
                    </button>
                  )}
                </TableCell>
              </TableRow>
            ) : (
              filtered.map((u) => (
                <TableRow
                  key={u.id}
                  className="cursor-pointer hover:bg-muted/40"
                  onClick={() => router.push(`/users/${u.id}`)}
                >
                  <TableCell className="font-medium">
                    {u.name || <span className="text-muted-foreground">—</span>}
                  </TableCell>
                  <TableCell className="text-sm">{u.email}</TableCell>
                  <TableCell className="text-sm text-muted-foreground">
                    {u.phone ? (
                      <span className="flex items-center gap-1.5">
                        {u.phone}
                        <a
                          href={`https://wa.me/${u.phone.replace(/\D/g, "")}`}
                          target="_blank"
                          rel="noopener noreferrer"
                          onClick={(e) => e.stopPropagation()}
                          className="text-trackeo-online hover:text-trackeo-primary-dark"
                          title="WhatsApp"
                        >
                          <MessageCircle className="h-3.5 w-3.5" />
                        </a>
                      </span>
                    ) : "—"}
                  </TableCell>
                  <TableCell>
                    {(u.vehicleCount ?? 0) > 0 ? (
                      <span className="inline-flex items-center gap-1 text-sm font-medium">
                        <Car className="h-3.5 w-3.5 text-muted-foreground" />
                        {u.vehicleCount}
                      </span>
                    ) : (
                      <span className="text-muted-foreground text-sm">—</span>
                    )}
                  </TableCell>
                  <TableCell>
                    <Badge variant={u.role === "admin" ? "default" : "secondary"}>{u.role}</Badge>
                  </TableCell>
                  <TableCell>
                    <span className={`inline-flex items-center gap-1.5 text-xs font-medium ${u.isActive !== false ? "text-trackeo-online" : "text-muted-foreground"}`}>
                      <span className={`h-1.5 w-1.5 rounded-full ${u.isActive !== false ? "bg-trackeo-online" : "bg-trackeo-offline"}`} />
                      {u.isActive !== false ? "Active" : "Inactive"}
                    </span>
                  </TableCell>
                  <TableCell className="text-sm text-muted-foreground" title={u.createdAt ? new Date(u.createdAt).toLocaleString() : undefined}>
                    {relativeTime(u.createdAt)}
                  </TableCell>
                  <TableCell onClick={(e) => e.stopPropagation()}>
                    <DropdownMenu>
                      <DropdownMenuTrigger asChild>
                        <Button size="icon" variant="ghost" className="h-8 w-8">
                          <MoreHorizontal className="h-4 w-4" />
                        </Button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuItem onClick={() => router.push(`/users/${u.id}`)}>View detail</DropdownMenuItem>
                        <DropdownMenuItem onClick={() => openEdit(u)}>Edit</DropdownMenuItem>
                        {u.phone && (
                          <DropdownMenuItem asChild>
                            <a href={`https://wa.me/${u.phone.replace(/\D/g, "")}`} target="_blank" rel="noopener noreferrer">
                              WhatsApp
                            </a>
                          </DropdownMenuItem>
                        )}
                        <DropdownMenuItem onClick={() => handleToggleActive(u)}>
                          {u.isActive !== false ? "Deactivate" : "Activate"}
                        </DropdownMenuItem>
                        <DropdownMenuSeparator />
                        <DropdownMenuItem className="text-destructive" onClick={() => handleDelete(u)}>Delete</DropdownMenuItem>
                      </DropdownMenuContent>
                    </DropdownMenu>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </div>

      <Sheet open={sheetOpen} onOpenChange={setSheetOpen}>
        <SheetContent>
          <SheetHeader>
            <SheetTitle>{editUser ? `Edit ${editUser.name || editUser.email}` : "New User"}</SheetTitle>
          </SheetHeader>
          <div className="space-y-4 py-4">
            {!editUser && (
              <div className="space-y-1">
                <Label>Email *</Label>
                <Input type="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} placeholder="user@example.com" />
              </div>
            )}
            <div className="space-y-1">
              <Label>{editUser ? "New Password (leave blank to keep)" : "Password *"}</Label>
              <Input type="password" value={form.password} onChange={(e) => setForm({ ...form, password: e.target.value })} placeholder="••••••••" />
            </div>
            <div className="space-y-1">
              <Label>Name</Label>
              <Input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} placeholder="Full name" />
            </div>
            <div className="space-y-1">
              <Label>Phone</Label>
              <Input value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })} placeholder="+261 34 00 000 00" />
            </div>
            <div className="space-y-1">
              <Label>Role</Label>
              <select className="w-full border rounded-md px-3 py-2 text-sm bg-background" value={form.role} onChange={(e) => setForm({ ...form, role: e.target.value })}>
                <option value="user">User</option>
                <option value="admin">Admin</option>
              </select>
            </div>
            {error && <p className="text-sm text-destructive bg-destructive/10 rounded-md px-3 py-2">{error}</p>}
          </div>
          <SheetFooter>
            <Button variant="outline" onClick={() => setSheetOpen(false)}>Cancel</Button>
            <Button onClick={handleSave} disabled={saving}>
              {saving ? "Saving..." : editUser ? "Save Changes" : "Create User"}
            </Button>
          </SheetFooter>
        </SheetContent>
      </Sheet>
    </div>
  );
}
