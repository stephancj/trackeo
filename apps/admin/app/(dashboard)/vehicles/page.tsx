"use client";

import { useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { getAdminVehicles, getUsers, assignDevice, unassignDevice } from "@/lib/api";
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
import { Skeleton } from "@/components/ui/skeleton";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import { MoreHorizontal, RefreshCw, Map } from "lucide-react";

interface Vehicle {
  id: number;
  name: string;
  serialNumber: string;
  plate: string | null;
  status: "online" | "idle" | "offline";
  lastUpdate: string | null;
  assignedUserId: number | null;
  assignedUserName: string | null;
  openAlertsCount: number;
  position?: {
    lat: number;
    lon: number;
    speedKmh: number;
    battery: number | null;
    ignition: boolean | null;
  } | null;
}

interface User {
  id: number;
  name: string | null;
  email: string;
}

type Tab = "all" | "online" | "idle" | "offline" | "unassigned";

const STATUS_DOT: Record<string, string> = {
  online: "bg-trackeo-online",
  idle: "bg-trackeo-idle",
  offline: "bg-trackeo-offline",
};

const STATUS_LABEL: Record<string, string> = {
  online: "Online",
  idle: "Idle",
  offline: "Offline",
};

const REFRESH_INTERVAL = 30_000;

function BatteryBar({ pct }: { pct: number | null | undefined }) {
  if (pct == null) return <span className="text-muted-foreground text-xs">—</span>;
  const color = pct > 50 ? "bg-trackeo-online" : pct > 20 ? "bg-trackeo-warning" : "bg-trackeo-alert";
  return (
    <div className="flex items-center gap-1.5">
      <div className="w-12 h-2 bg-muted rounded-full overflow-hidden">
        <div className={`h-full rounded-full ${color}`} style={{ width: `${pct}%` }} />
      </div>
      <span className="text-xs tabular-nums text-muted-foreground">{pct}%</span>
    </div>
  );
}

export default function VehiclesPage() {
  const router = useRouter();
  const [vehicles, setVehicles] = useState<Vehicle[]>([]);
  const [users, setUsers] = useState<User[]>([]);
  const [search, setSearch] = useState("");
  const [tab, setTab] = useState<Tab>("all");
  const [loading, setLoading] = useState(true);
  const [lastRefresh, setLastRefresh] = useState<Date>(new Date());
  const intervalRef = useRef<ReturnType<typeof setInterval>>(null);

  const [assignTarget, setAssignTarget] = useState<Vehicle | null>(null);
  const [assignUserId, setAssignUserId] = useState<string>("");
  const [saving, setSaving] = useState(false);

  function fetchVehicles() {
    return getAdminVehicles()
      .then((r) => {
        setVehicles(r.data);
        setLastRefresh(new Date());
      })
      .catch(() => toast.error("Failed to refresh vehicles"));
  }

  useEffect(() => {
    Promise.all([
      fetchVehicles(),
      getUsers().then((r) => setUsers(r.data)),
    ]).finally(() => setLoading(false));

    intervalRef.current = setInterval(fetchVehicles, REFRESH_INTERVAL);
    return () => { if (intervalRef.current) clearInterval(intervalRef.current); };
  }, []);

  async function handleAssign() {
    if (!assignTarget || !assignUserId) return;
    const user = users.find((u) => u.id === Number(assignUserId));
    setSaving(true);
    try {
      await assignDevice(assignTarget.id, Number(assignUserId));
      await fetchVehicles();
      toast.success(`${assignTarget.name} assigned`, { description: `To ${user?.name || user?.email}` });
      setAssignTarget(null);
      setAssignUserId("");
    } catch {
      toast.error("Failed to assign vehicle");
    } finally {
      setSaving(false);
    }
  }

  async function handleUnassign(v: Vehicle) {
    try {
      await unassignDevice(v.id);
      await fetchVehicles();
      toast.success(`${v.name} unassigned`);
    } catch {
      toast.error("Failed to unassign vehicle");
    }
  }

  const filtered = vehicles.filter((v) => {
    const matchSearch =
      v.name?.toLowerCase().includes(search.toLowerCase()) ||
      v.plate?.toLowerCase().includes(search.toLowerCase()) ||
      v.serialNumber?.toLowerCase().includes(search.toLowerCase());
    if (!matchSearch) return false;
    if (tab === "unassigned") return v.assignedUserId === null;
    if (tab !== "all") return v.status === tab;
    return true;
  });

  const counts = {
    all: vehicles.length,
    online: vehicles.filter((v) => v.status === "online").length,
    idle: vehicles.filter((v) => v.status === "idle").length,
    offline: vehicles.filter((v) => v.status === "offline").length,
    unassigned: vehicles.filter((v) => v.assignedUserId === null).length,
  };

  const tabs: { key: Tab; label: string }[] = [
    { key: "all", label: `All (${counts.all})` },
    { key: "online", label: `Online (${counts.online})` },
    { key: "idle", label: `Idle (${counts.idle})` },
    { key: "offline", label: `Offline (${counts.offline})` },
    { key: "unassigned", label: `Unassigned (${counts.unassigned})` },
  ];

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-trackeo-dark">Vehicles</h1>
        <div className="flex items-center gap-2">
          <Button size="sm" variant="outline" onClick={() => router.push("/map")} className="gap-1.5">
            <Map className="h-3.5 w-3.5" />
            Fleet Map
          </Button>
          <span className="text-xs text-muted-foreground">Updated {relativeTime(lastRefresh)}</span>
          <Button size="sm" variant="outline" onClick={fetchVehicles} className="gap-1.5">
            <RefreshCw className="h-3.5 w-3.5" />
            Refresh
          </Button>
        </div>
      </div>

      <div className="flex gap-2 mb-4 flex-wrap">
        {tabs.map((t) => (
          <button
            key={t.key}
            onClick={() => setTab(t.key)}
            className={`px-3 py-1.5 rounded-full text-sm font-medium border transition-colors ${
              tab === t.key
                ? "bg-trackeo-primary text-white border-trackeo-primary"
                : "bg-card text-muted-foreground border-border hover:bg-accent hover:text-foreground"
            }`}
          >
            {t.label}
          </button>
        ))}
      </div>

      <div className="mb-4">
        <Input
          placeholder="Search by name, plate or IMEI..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="max-w-sm"
        />
      </div>

      <div className="rounded-md border bg-card">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Vehicle</TableHead>
              <TableHead>Plate</TableHead>
              <TableHead>Status</TableHead>
              <TableHead>Battery</TableHead>
              <TableHead>Ignition</TableHead>
              <TableHead>Alerts</TableHead>
              <TableHead>Last Seen</TableHead>
              <TableHead>Assigned To</TableHead>
              <TableHead className="w-12"></TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {loading ? (
              Array.from({ length: 5 }).map((_, i) => (
                <TableRow key={i}>
                  {Array.from({ length: 9 }).map((_, j) => (
                    <TableCell key={j}><Skeleton className="h-4 w-full" /></TableCell>
                  ))}
                </TableRow>
              ))
            ) : filtered.length === 0 ? (
              <TableRow>
                <TableCell colSpan={9} className="py-12 text-center">
                  <p className="text-muted-foreground font-medium">
                    {tab === "unassigned" ? "All vehicles are assigned." : "No vehicles found."}
                  </p>
                </TableCell>
              </TableRow>
            ) : (
              filtered.map((v) => (
                <TableRow
                  key={v.id}
                  className="cursor-pointer hover:bg-muted/40"
                  onClick={() => router.push(`/vehicles/${v.id}`)}
                >
                  <TableCell className="font-medium">{v.name}</TableCell>
                  <TableCell className="text-sm">
                    {v.plate || <span className="text-muted-foreground">—</span>}
                  </TableCell>
                  <TableCell>
                    <span className="inline-flex items-center gap-1.5 text-sm">
                      <span className={`h-2 w-2 rounded-full shrink-0 ${STATUS_DOT[v.status]}`} />
                      {STATUS_LABEL[v.status]}
                    </span>
                  </TableCell>
                  <TableCell><BatteryBar pct={v.position?.battery} /></TableCell>
                  <TableCell>
                    {v.position?.ignition == null ? (
                      <span className="text-muted-foreground text-xs">—</span>
                    ) : v.position.ignition ? (
                      <span className="text-xs font-medium text-trackeo-online">🔑 On</span>
                    ) : (
                      <span className="text-xs text-muted-foreground">Off</span>
                    )}
                  </TableCell>
                  <TableCell>
                    {v.openAlertsCount > 0 ? (
                      <span className="inline-flex items-center justify-center h-5 min-w-5 px-1.5 rounded-full bg-trackeo-alert text-white text-xs font-semibold">
                        {v.openAlertsCount}
                      </span>
                    ) : (
                      <span className="text-muted-foreground text-xs">—</span>
                    )}
                  </TableCell>
                  <TableCell
                    className="text-sm text-muted-foreground"
                    title={v.lastUpdate ? new Date(v.lastUpdate).toLocaleString() : undefined}
                  >
                    {relativeTime(v.lastUpdate)}
                  </TableCell>
                  <TableCell>
                    {v.assignedUserName ? (
                      <span className="text-sm">{v.assignedUserName}</span>
                    ) : (
                      <Badge variant="outline" className="text-muted-foreground">Unassigned</Badge>
                    )}
                  </TableCell>
                  <TableCell onClick={(e) => e.stopPropagation()}>
                    <DropdownMenu>
                      <DropdownMenuTrigger asChild>
                        <Button size="icon" variant="ghost" className="h-8 w-8">
                          <MoreHorizontal className="h-4 w-4" />
                        </Button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuItem onClick={() => router.push(`/vehicles/${v.id}`)}>View detail</DropdownMenuItem>
                        <DropdownMenuItem
                          onClick={() => {
                            setAssignTarget(v);
                            setAssignUserId(v.assignedUserId?.toString() ?? "");
                          }}
                        >
                          {v.assignedUserId ? "Reassign" : "Assign to user"}
                        </DropdownMenuItem>
                        {v.assignedUserId !== null && (
                          <DropdownMenuItem className="text-destructive" onClick={() => handleUnassign(v)}>
                            Unassign
                          </DropdownMenuItem>
                        )}
                      </DropdownMenuContent>
                    </DropdownMenu>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </div>

      <Dialog open={!!assignTarget} onOpenChange={() => setAssignTarget(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {assignTarget?.assignedUserId ? "Reassign" : "Assign"} {assignTarget?.name}
            </DialogTitle>
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
            <Button variant="outline" onClick={() => setAssignTarget(null)}>Cancel</Button>
            <Button onClick={handleAssign} disabled={!assignUserId || saving}>
              {saving ? "Saving..." : "Assign"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
