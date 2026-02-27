"use client";

import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { getUserDetail, updateUser, assignDevice, getAdminVehicles, getUsers } from "@/lib/api";
import { relativeTime } from "@/lib/utils";
import { toast } from "sonner";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import {
  ArrowLeft,
  MessageCircle,
  Car,
  Bell,
  MapPin,
  CheckCircle2,
  XCircle,
  PlusCircle,
} from "lucide-react";

interface Vehicle {
  id: number;
  name: string;
  plate: string | null;
  status: "online" | "idle" | "offline";
  lastUpdate: string | null;
  position?: { lat: number; lon: number; speedKmh: number; battery: number | null } | null;
}

interface UserDetail {
  id: number;
  email: string;
  name: string | null;
  phone: string | null;
  role: string;
  isActive: boolean;
  createdAt: string;
  alertsEnabled: boolean;
  alertViaPush: boolean;
  alertViaWhatsapp: boolean;
  vehicles: Vehicle[];
  openAlertsCount: number;
  geofencesCount: number;
}

interface AllVehicle {
  id: number;
  name: string;
  plate: string | null;
  assignedUserId: number | null;
}

interface AllUser {
  id: number;
  name: string | null;
  email: string;
}

const STATUS_DOT: Record<string, string> = {
  online: "bg-green-500",
  idle: "bg-yellow-400",
  offline: "bg-zinc-400",
};

const STATUS_LABEL: Record<string, string> = {
  online: "Online",
  idle: "Idle",
  offline: "Offline",
};

export default function UserDetailPage() {
  const params = useParams();
  const router = useRouter();
  const userId = Number(params.id);

  const [user, setUser] = useState<UserDetail | null>(null);
  const [loading, setLoading] = useState(true);

  const [assignOpen, setAssignOpen] = useState(false);
  const [allVehicles, setAllVehicles] = useState<AllVehicle[]>([]);
  const [allUsers, setAllUsers] = useState<AllUser[]>([]);
  const [selectedVehicleId, setSelectedVehicleId] = useState("");
  const [assigning, setAssigning] = useState(false);

  async function fetchUser() {
    const r = await getUserDetail(userId);
    setUser(r.data);
  }

  useEffect(() => {
    fetchUser().finally(() => setLoading(false));
  }, [userId]);

  async function openAssignDialog() {
    const [vRes, uRes] = await Promise.all([getAdminVehicles(), getUsers()]);
    setAllVehicles(vRes.data);
    setAllUsers(uRes.data);
    setSelectedVehicleId("");
    setAssignOpen(true);
  }

  async function handleAssignVehicle() {
    if (!selectedVehicleId) return;
    setAssigning(true);
    try {
      await assignDevice(Number(selectedVehicleId), userId);
      await fetchUser();
      setAssignOpen(false);
      toast.success("Vehicle assigned");
    } catch {
      toast.error("Failed to assign vehicle");
    } finally {
      setAssigning(false);
    }
  }

  async function handleToggleActive() {
    if (!user) return;
    try {
      await updateUser(user.id, { isActive: !user.isActive });
      await fetchUser();
      toast.success(user.isActive ? "User deactivated" : "User activated");
    } catch {
      toast.error("Failed to update user");
    }
  }

  if (loading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-8 w-48" />
        <div className="grid grid-cols-3 gap-4">
          {Array.from({ length: 3 }).map((_, i) => (
            <Skeleton key={i} className="h-24 rounded-xl" />
          ))}
        </div>
        <Skeleton className="h-48 rounded-xl" />
      </div>
    );
  }

  if (!user) {
    return (
      <div className="text-center py-20 text-muted-foreground">
        User not found.{" "}
        <button className="underline text-primary" onClick={() => router.push("/users")}>
          Go back
        </button>
      </div>
    );
  }

  const unassignedVehicles = allVehicles.filter((v) => v.assignedUserId === null);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="icon" onClick={() => router.push("/users")} className="shrink-0">
          <ArrowLeft className="h-4 w-4" />
        </Button>
        <div className="flex-1 min-w-0">
          <h1 className="text-2xl font-bold truncate">{user.name || user.email}</h1>
          <p className="text-sm text-muted-foreground">{user.email}</p>
        </div>
        <div className="flex items-center gap-2">
          {user.phone && (
            <Button variant="outline" size="sm" asChild>
              <a
                href={`https://wa.me/${user.phone.replace(/\D/g, "")}`}
                target="_blank"
                rel="noopener noreferrer"
                className="gap-1.5"
              >
                <MessageCircle className="h-3.5 w-3.5 text-green-600" />
                WhatsApp
              </a>
            </Button>
          )}
          <Button variant="outline" size="sm" onClick={handleToggleActive}>
            {user.isActive ? "Deactivate" : "Activate"}
          </Button>
        </div>
      </div>

      {/* Stats row */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
        <div className="bg-card border rounded-xl p-4">
          <div className="flex items-center gap-2 text-muted-foreground text-sm mb-1">
            <Car className="h-4 w-4" />
            Vehicles
          </div>
          <p className="text-2xl font-bold">{user.vehicles.length}</p>
        </div>
        <div className="bg-card border rounded-xl p-4">
          <div className="flex items-center gap-2 text-muted-foreground text-sm mb-1">
            <Bell className="h-4 w-4" />
            Open Alerts
          </div>
          <p className={`text-2xl font-bold ${user.openAlertsCount > 0 ? "text-destructive" : ""}`}>
            {user.openAlertsCount}
          </p>
        </div>
        <div className="bg-card border rounded-xl p-4">
          <div className="flex items-center gap-2 text-muted-foreground text-sm mb-1">
            <MapPin className="h-4 w-4" />
            Geofences
          </div>
          <p className="text-2xl font-bold">{user.geofencesCount}</p>
        </div>
        <div className="bg-card border rounded-xl p-4">
          <div className="flex items-center gap-2 text-muted-foreground text-sm mb-1">
            Status
          </div>
          <span className={`inline-flex items-center gap-1.5 text-sm font-semibold ${user.isActive ? "text-green-700" : "text-muted-foreground"}`}>
            {user.isActive ? <CheckCircle2 className="h-4 w-4" /> : <XCircle className="h-4 w-4" />}
            {user.isActive ? "Active" : "Inactive"}
          </span>
        </div>
      </div>

      {/* Profile card */}
      <div className="bg-card border rounded-xl p-5">
        <h2 className="font-semibold mb-4">Profile</h2>
        <dl className="grid grid-cols-2 gap-x-8 gap-y-3 text-sm">
          <div>
            <dt className="text-muted-foreground">Email</dt>
            <dd className="font-medium">{user.email}</dd>
          </div>
          <div>
            <dt className="text-muted-foreground">Phone</dt>
            <dd className="font-medium">{user.phone || "—"}</dd>
          </div>
          <div>
            <dt className="text-muted-foreground">Role</dt>
            <dd>
              <Badge variant={user.role === "admin" ? "default" : "secondary"}>{user.role}</Badge>
            </dd>
          </div>
          <div>
            <dt className="text-muted-foreground">Joined</dt>
            <dd className="font-medium" title={new Date(user.createdAt).toLocaleString()}>
              {relativeTime(user.createdAt)}
            </dd>
          </div>
          <div>
            <dt className="text-muted-foreground">Push notifications</dt>
            <dd className={user.alertViaPush ? "text-green-700 font-medium" : "text-muted-foreground"}>
              {user.alertViaPush ? "Enabled" : "Disabled"}
            </dd>
          </div>
          <div>
            <dt className="text-muted-foreground">WhatsApp alerts</dt>
            <dd className={user.alertViaWhatsapp ? "text-green-700 font-medium" : "text-muted-foreground"}>
              {user.alertViaWhatsapp ? "Enabled" : "Disabled"}
            </dd>
          </div>
        </dl>
      </div>

      {/* Vehicles */}
      <div className="bg-card border rounded-xl p-5">
        <div className="flex items-center justify-between mb-4">
          <h2 className="font-semibold">Assigned Vehicles</h2>
          <Button variant="outline" size="sm" onClick={openAssignDialog} className="gap-1.5">
            <PlusCircle className="h-3.5 w-3.5" />
            Assign Vehicle
          </Button>
        </div>
        {user.vehicles.length === 0 ? (
          <p className="text-sm text-muted-foreground py-4 text-center">No vehicles assigned.</p>
        ) : (
          <div className="space-y-2">
            {user.vehicles.map((v) => (
              <div
                key={v.id}
                className="flex items-center justify-between p-3 rounded-lg border bg-muted/30 hover:bg-muted/50 cursor-pointer transition-colors"
                onClick={() => router.push(`/vehicles/${v.id}`)}
              >
                <div className="flex items-center gap-3">
                  <span className={`h-2.5 w-2.5 rounded-full shrink-0 ${STATUS_DOT[v.status]}`} />
                  <div>
                    <p className="text-sm font-medium">{v.name}</p>
                    {v.plate && <p className="text-xs text-muted-foreground">{v.plate}</p>}
                  </div>
                </div>
                <div className="flex items-center gap-4 text-sm text-muted-foreground">
                  {v.position?.battery != null && (
                    <span className="text-xs">🔋 {v.position.battery}%</span>
                  )}
                  <span>{STATUS_LABEL[v.status]}</span>
                  <span className="text-xs">{relativeTime(v.lastUpdate)}</span>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Assign Vehicle Dialog */}
      <Dialog open={assignOpen} onOpenChange={setAssignOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Assign a vehicle to {user.name || user.email}</DialogTitle>
          </DialogHeader>
          <div className="py-2">
            <label className="text-sm font-medium block mb-1">Select unassigned vehicle</label>
            <select
              className="w-full border rounded-md px-3 py-2 text-sm bg-background"
              value={selectedVehicleId}
              onChange={(e) => setSelectedVehicleId(e.target.value)}
            >
              <option value="">— Choose a vehicle —</option>
              {unassignedVehicles.map((v) => (
                <option key={v.id} value={v.id}>
                  {v.name} {v.plate ? `(${v.plate})` : ""}
                </option>
              ))}
            </select>
            {unassignedVehicles.length === 0 && (
              <p className="text-xs text-muted-foreground mt-2">No unassigned vehicles available.</p>
            )}
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setAssignOpen(false)}>Cancel</Button>
            <Button onClick={handleAssignVehicle} disabled={!selectedVehicleId || assigning}>
              {assigning ? "Assigning..." : "Assign"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
