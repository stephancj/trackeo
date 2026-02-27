"use client";

import { useEffect, useRef, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { getVehicleDetail, ackAlert, assignDevice, getUsers, unassignDevice } from "@/lib/api";
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
import { OSMMap, MapMarker } from "@/components/map/osm-map";
import {
  ArrowLeft,
  RefreshCw,
  CheckCheck,
  MapPin,
  Zap,
  User,
  MessageCircle,
} from "lucide-react";

interface Position {
  lat: number;
  lon: number;
  speedKmh: number;
  battery: number | null;
  ignition: boolean | null;
  rssi: number | null;
  deviceTime: string | null;
}

interface Alert {
  id: string;
  type: string;
  status: string;
  message: string | null;
  createdAt: string;
}

interface Geofence {
  id: number;
  name: string;
  centerLat: number;
  centerLon: number;
  radiusM: number;
  isActive: boolean;
}

interface VehicleDetail {
  id: number;
  name: string;
  serialNumber: string;
  plate: string | null;
  status: "online" | "idle" | "offline";
  lastUpdate: string | null;
  position: Position | null;
  assignedUserId: number | null;
  assignedUserName: string | null;
  assignedUserPhone: string | null;
  recentAlerts: Alert[];
  linkedGeofences: Geofence[];
}

interface UserOption {
  id: number;
  name: string | null;
  email: string;
}

const STATUS_COLOR: Record<string, string> = {
  online: "bg-green-500",
  idle: "bg-yellow-400",
  offline: "bg-zinc-400",
};

const STATUS_LABEL: Record<string, string> = {
  online: "Online",
  idle: "Idle",
  offline: "Offline",
};

const TYPE_LABELS: Record<string, string> = {
  geofence_enter: "Geofence Enter",
  geofence_exit: "Geofence Exit",
  low_battery: "Low Battery",
  speed_limit: "Speed Limit",
  sos: "SOS",
};

function BatteryBar({ pct }: { pct: number | null | undefined }) {
  if (pct == null) return <span className="text-muted-foreground">—</span>;
  const color = pct > 50 ? "bg-green-500" : pct > 20 ? "bg-yellow-400" : "bg-red-500";
  return (
    <div className="flex items-center gap-2">
      <div className="w-20 h-2.5 bg-muted rounded-full overflow-hidden">
        <div className={`h-full rounded-full ${color}`} style={{ width: `${pct}%` }} />
      </div>
      <span className="text-sm font-medium tabular-nums">{pct}%</span>
    </div>
  );
}

const REFRESH_INTERVAL = 30_000;

export default function VehicleDetailPage() {
  const params = useParams();
  const router = useRouter();
  const vehicleId = Number(params.id);

  const [vehicle, setVehicle] = useState<VehicleDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [acking, setAcking] = useState<string | null>(null);
  const [lastRefresh, setLastRefresh] = useState<Date>(new Date());
  const intervalRef = useRef<ReturnType<typeof setInterval>>(null);

  const [assignOpen, setAssignOpen] = useState(false);
  const [users, setUsers] = useState<UserOption[]>([]);
  const [assignUserId, setAssignUserId] = useState("");
  const [assigning, setAssigning] = useState(false);

  async function fetchVehicle() {
    const r = await getVehicleDetail(vehicleId);
    setVehicle(r.data);
    setLastRefresh(new Date());
  }

  useEffect(() => {
    fetchVehicle().finally(() => setLoading(false));
    intervalRef.current = setInterval(fetchVehicle, REFRESH_INTERVAL);
    return () => { if (intervalRef.current) clearInterval(intervalRef.current); };
  }, [vehicleId]);

  async function handleAck(alertId: string) {
    setAcking(alertId);
    try {
      await ackAlert(alertId);
      setVehicle((prev) =>
        prev
          ? {
              ...prev,
              recentAlerts: prev.recentAlerts.map((a) =>
                a.id === alertId ? { ...a, status: "acked" } : a
              ),
            }
          : prev
      );
      toast.success("Alert acknowledged");
    } catch {
      toast.error("Failed to acknowledge alert");
    } finally {
      setAcking(null);
    }
  }

  async function openAssignDialog() {
    const r = await getUsers();
    setUsers(r.data);
    setAssignUserId(vehicle?.assignedUserId?.toString() ?? "");
    setAssignOpen(true);
  }

  async function handleAssign() {
    if (!assignUserId) return;
    setAssigning(true);
    try {
      await assignDevice(vehicleId, Number(assignUserId));
      await fetchVehicle();
      setAssignOpen(false);
      toast.success("Vehicle reassigned");
    } catch {
      toast.error("Failed to assign vehicle");
    } finally {
      setAssigning(false);
    }
  }

  async function handleUnassign() {
    try {
      await unassignDevice(vehicleId);
      await fetchVehicle();
      toast.success("Vehicle unassigned");
    } catch {
      toast.error("Failed to unassign");
    }
  }

  if (loading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-8 w-64" />
        <div className="grid grid-cols-2 gap-4">
          <Skeleton className="h-64 rounded-xl" />
          <Skeleton className="h-64 rounded-xl" />
        </div>
      </div>
    );
  }

  if (!vehicle) {
    return (
      <div className="text-center py-20 text-muted-foreground">
        Vehicle not found.{" "}
        <button className="underline text-primary" onClick={() => router.push("/vehicles")}>Go back</button>
      </div>
    );
  }

  const mapMarkerColor: MapMarker["color"] =
    vehicle.status === "online" ? "green" : vehicle.status === "idle" ? "yellow" : "gray";

  const mapMarkers: MapMarker[] = vehicle.position
    ? [{ lat: vehicle.position.lat, lon: vehicle.position.lon, color: mapMarkerColor, label: vehicle.name }]
    : [];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="icon" onClick={() => router.push("/vehicles")} className="shrink-0">
          <ArrowLeft className="h-4 w-4" />
        </Button>
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <span className={`h-2.5 w-2.5 rounded-full ${STATUS_COLOR[vehicle.status]}`} />
            <h1 className="text-2xl font-bold truncate">{vehicle.name}</h1>
            {vehicle.plate && <Badge variant="outline">{vehicle.plate}</Badge>}
          </div>
          <p className="text-sm text-muted-foreground font-mono">{vehicle.serialNumber}</p>
        </div>
        <div className="flex items-center gap-2">
          <span className="text-xs text-muted-foreground">Updated {relativeTime(lastRefresh)}</span>
          <Button variant="outline" size="sm" onClick={fetchVehicle} className="gap-1.5">
            <RefreshCw className="h-3.5 w-3.5" />
            Refresh
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Left column */}
        <div className="space-y-4">
          {/* Live position map */}
          <div className="bg-card border rounded-xl overflow-hidden">
            <div className="px-4 py-3 border-b flex items-center gap-2">
              <MapPin className="h-4 w-4 text-muted-foreground" />
              <span className="font-medium text-sm">Current Position</span>
              {vehicle.position && (
                <span className="ml-auto text-xs text-muted-foreground">
                  {vehicle.position.lat.toFixed(5)}, {vehicle.position.lon.toFixed(5)}
                </span>
              )}
            </div>
            {vehicle.position ? (
              <OSMMap
                markers={mapMarkers}
                center={[vehicle.position.lat, vehicle.position.lon]}
                zoom={15}
                className="h-64 w-full"
              />
            ) : (
              <div className="h-64 flex items-center justify-center text-muted-foreground text-sm">
                No position data available
              </div>
            )}
          </div>

          {/* Telemetry */}
          <div className="bg-card border rounded-xl p-5">
            <div className="flex items-center gap-2 mb-4">
              <Zap className="h-4 w-4 text-muted-foreground" />
              <span className="font-medium text-sm">Telemetry</span>
            </div>
            <dl className="grid grid-cols-2 gap-x-6 gap-y-3 text-sm">
              <div>
                <dt className="text-muted-foreground">Status</dt>
                <dd className="font-medium">{STATUS_LABEL[vehicle.status]}</dd>
              </div>
              <div>
                <dt className="text-muted-foreground">Speed</dt>
                <dd className="font-medium">
                  {vehicle.position?.speedKmh != null
                    ? `${Math.round(vehicle.position.speedKmh)} km/h`
                    : "—"}
                </dd>
              </div>
              <div>
                <dt className="text-muted-foreground">Battery</dt>
                <dd><BatteryBar pct={vehicle.position?.battery} /></dd>
              </div>
              <div>
                <dt className="text-muted-foreground">Ignition</dt>
                <dd className="font-medium">
                  {vehicle.position?.ignition == null
                    ? "—"
                    : vehicle.position.ignition
                    ? <span className="text-green-700">🔑 On</span>
                    : "Off"}
                </dd>
              </div>
              <div>
                <dt className="text-muted-foreground">Signal</dt>
                <dd className="font-medium">
                  {vehicle.position?.rssi != null ? `${vehicle.position.rssi} dBm` : "—"}
                </dd>
              </div>
              <div>
                <dt className="text-muted-foreground">Last update</dt>
                <dd className="font-medium" title={vehicle.lastUpdate ? new Date(vehicle.lastUpdate).toLocaleString() : undefined}>
                  {relativeTime(vehicle.lastUpdate)}
                </dd>
              </div>
            </dl>
          </div>

          {/* Assignment */}
          <div className="bg-card border rounded-xl p-5">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-2">
                <User className="h-4 w-4 text-muted-foreground" />
                <span className="font-medium text-sm">Assigned Owner</span>
              </div>
              <div className="flex gap-2">
                {vehicle.assignedUserId && (
                  <Button variant="outline" size="sm" className="h-7 text-xs text-destructive" onClick={handleUnassign}>
                    Unassign
                  </Button>
                )}
                <Button variant="outline" size="sm" className="h-7 text-xs" onClick={openAssignDialog}>
                  {vehicle.assignedUserId ? "Reassign" : "Assign"}
                </Button>
              </div>
            </div>
            {vehicle.assignedUserName ? (
              <div className="flex items-center justify-between">
                <div>
                  <p className="font-medium">{vehicle.assignedUserName}</p>
                  {vehicle.assignedUserPhone && (
                    <p className="text-sm text-muted-foreground">{vehicle.assignedUserPhone}</p>
                  )}
                </div>
                {vehicle.assignedUserPhone && (
                  <Button variant="outline" size="sm" asChild>
                    <a
                      href={`https://wa.me/${vehicle.assignedUserPhone.replace(/\D/g, "")}`}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="gap-1.5"
                    >
                      <MessageCircle className="h-3.5 w-3.5 text-green-600" />
                      WhatsApp
                    </a>
                  </Button>
                )}
              </div>
            ) : (
              <p className="text-sm text-muted-foreground">No owner assigned.</p>
            )}
          </div>
        </div>

        {/* Right column */}
        <div className="space-y-4">
          {/* Recent alerts */}
          <div className="bg-card border rounded-xl p-5">
            <h2 className="font-semibold mb-4">
              Recent Alerts{" "}
              {vehicle.recentAlerts.filter((a) => a.status === "open").length > 0 && (
                <span className="ml-2 inline-flex items-center justify-center h-5 min-w-5 px-1.5 rounded-full bg-destructive text-destructive-foreground text-xs font-semibold">
                  {vehicle.recentAlerts.filter((a) => a.status === "open").length}
                </span>
              )}
            </h2>
            {vehicle.recentAlerts.length === 0 ? (
              <p className="text-sm text-muted-foreground py-4 text-center">No alerts.</p>
            ) : (
              <div className="space-y-2 max-h-72 overflow-y-auto">
                {vehicle.recentAlerts.map((a) => (
                  <div
                    key={a.id}
                    className={`flex items-center justify-between p-3 rounded-lg border text-sm ${
                      a.status === "open" ? "border-destructive/30 bg-destructive/5" : "bg-muted/30"
                    }`}
                  >
                    <div>
                      <p className="font-medium">{TYPE_LABELS[a.type] ?? a.type}</p>
                      <p className="text-xs text-muted-foreground" title={new Date(a.createdAt).toLocaleString()}>
                        {relativeTime(a.createdAt)}
                      </p>
                    </div>
                    <div className="flex items-center gap-2">
                      <Badge
                        variant={
                          a.status === "open"
                            ? "destructive"
                            : a.status === "acked"
                            ? "secondary"
                            : "outline"
                        }
                      >
                        {a.status}
                      </Badge>
                      {a.status === "open" && (
                        <Button
                          size="sm"
                          variant="ghost"
                          className="h-7 gap-1 text-xs"
                          onClick={() => handleAck(a.id)}
                          disabled={acking === a.id}
                        >
                          <CheckCheck className="h-3.5 w-3.5" />
                          Ack
                        </Button>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Linked geofences */}
          <div className="bg-card border rounded-xl p-5">
            <h2 className="font-semibold mb-4">Linked Geofences</h2>
            {vehicle.linkedGeofences.length === 0 ? (
              <p className="text-sm text-muted-foreground py-4 text-center">
                No geofences linked to this vehicle.
              </p>
            ) : (
              <div className="space-y-2">
                {vehicle.linkedGeofences.map((g) => (
                  <div key={g.id} className="flex items-center justify-between p-3 rounded-lg border bg-muted/30 text-sm">
                    <div>
                      <p className="font-medium">{g.name}</p>
                      <p className="text-xs text-muted-foreground">
                        {g.centerLat.toFixed(4)}, {g.centerLon.toFixed(4)} · r={g.radiusM}m
                      </p>
                    </div>
                    <Badge variant={g.isActive ? "default" : "outline"}>
                      {g.isActive ? "Active" : "Inactive"}
                    </Badge>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Assign dialog */}
      <Dialog open={assignOpen} onOpenChange={setAssignOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{vehicle.assignedUserId ? "Reassign" : "Assign"} {vehicle.name}</DialogTitle>
          </DialogHeader>
          <div className="py-2">
            <label className="text-sm font-medium block mb-1">Select user</label>
            <select
              className="w-full border rounded-md px-3 py-2 text-sm bg-background"
              value={assignUserId}
              onChange={(e) => setAssignUserId(e.target.value)}
            >
              <option value="">— Choose a user —</option>
              {users.map((u) => (
                <option key={u.id} value={u.id}>
                  {u.name || u.email} ({u.email})
                </option>
              ))}
            </select>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setAssignOpen(false)}>Cancel</Button>
            <Button onClick={handleAssign} disabled={!assignUserId || assigning}>
              {assigning ? "Saving..." : "Assign"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
