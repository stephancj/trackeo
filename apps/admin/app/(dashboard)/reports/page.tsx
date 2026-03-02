"use client";

import { useEffect, useState, useCallback } from "react";
import {
  BarChart2,
  Car,
  AlertTriangle,
  Users,
  TrendingUp,
  Download,
  RefreshCw,
  Route,
  Gauge,
  Clock,
  MapPin,
} from "lucide-react";
import {
  getReportsOverview,
  getVehicleReports,
  getAdminVehicles,
  getVehicleActivitySummary,
  getVehicleTripLog,
  getVehicleSpeedViolations,
  getVehicleIdleTime,
  getVehicleGeofenceActivity,
} from "@/lib/api";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

// ── Types ─────────────────────────────────────────────────────────────────────

interface Overview {
  totalUsers: number;
  activeUsers: number;
  totalVehicles: number;
  statusCounts: { online: number; idle: number; offline: number };
  totalAlerts: number;
  openAlerts: number;
  alertsThisMonth: number;
  alertsByType: Record<string, number>;
}

interface VehicleReport {
  id: number;
  name: string;
  plate: string | null;
  status: string;
  lastUpdate: string | null;
  assignedUserName: string | null;
  distanceKm: number;
  maxSpeedKmh: number;
  pointCount: number;
  alertCount: number;
}

type Period = "today" | "7d" | "30d";
type DrillTab = "activity" | "trips" | "violations" | "idle" | "geofences";

interface VehicleOption {
  id: number;
  name: string;
  plate: string | null;
  status: string;
}

// ── Per-vehicle drill-down component ──────────────────────────────────────────

function VehicleDrillDown({ vehicles }: { vehicles: VehicleOption[] }) {
  const [selectedId, setSelectedId] = useState<number | null>(
    vehicles[0]?.id ?? null
  );
  const [tab, setTab] = useState<DrillTab>("activity");
  const [period, setPeriod] = useState<Period>("7d");
  const [loading, setLoading] = useState(false);
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const [data, setData] = useState<any>(null);

  const periodToRange = (p: Period) => {
    const now = new Date();
    let from: Date;
    if (p === "today")
      from = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    else if (p === "7d")
      from = new Date(now.getTime() - 7 * 24 * 3600 * 1000);
    else from = new Date(now.getTime() - 30 * 24 * 3600 * 1000);
    return { from: from.toISOString(), to: now.toISOString() };
  };

  useEffect(() => {
    if (!selectedId) return;
    setLoading(true);
    setData(null);
    const { from, to } = periodToRange(period);
    const fetcher =
      tab === "activity"
        ? getVehicleActivitySummary(selectedId, period)
        : tab === "trips"
        ? getVehicleTripLog(selectedId, from, to)
        : tab === "violations"
        ? getVehicleSpeedViolations(selectedId, from, to)
        : tab === "geofences"
        ? getVehicleGeofenceActivity(selectedId, from, to)
        : getVehicleIdleTime(selectedId, from, to);

    fetcher
      .then((r) => setData(r.data))
      .catch(() => {})
      .finally(() => setLoading(false));
  }, [selectedId, tab, period]);

  const DRILL_TABS: {
    key: DrillTab;
    label: string;
    icon: React.ComponentType<{ className?: string }>;
  }[] = [
    { key: "activity", label: "Activity", icon: BarChart2 },
    { key: "trips", label: "Trip Log", icon: Route },
    { key: "violations", label: "Speed Violations", icon: Gauge },
    { key: "idle", label: "Idle Time", icon: Clock },
    { key: "geofences", label: "Zones", icon: MapPin },
  ];

  const selected = vehicles.find((v) => v.id === selectedId);

  return (
    <div className="rounded-lg border bg-card overflow-hidden">
      {/* Header */}
      <div className="px-5 py-4 border-b">
        <h2 className="font-semibold flex items-center gap-2 mb-3">
          <Car className="h-4 w-4 text-muted-foreground" />
          Vehicle Detail Reports
        </h2>
        <div className="flex flex-wrap items-center gap-3">
          {/* Vehicle selector */}
          <select
            className="rounded-md border bg-background px-3 py-1.5 text-sm min-w-48"
            value={selectedId ?? ""}
            onChange={(e) => setSelectedId(Number(e.target.value))}
          >
            {vehicles.map((v) => (
              <option key={v.id} value={v.id}>
                {v.name}
                {v.plate ? ` · ${v.plate}` : ""}
              </option>
            ))}
          </select>

          {/* Tab selector */}
          <div className="flex gap-0.5">
            {DRILL_TABS.map(({ key, label, icon: Icon }) => (
              <button
                key={key}
                onClick={() => setTab(key)}
                className={cn(
                  "flex items-center gap-1.5 px-3 py-1.5 rounded-md text-sm font-medium transition-colors",
                  tab === key
                    ? "bg-primary text-primary-foreground"
                    : "text-muted-foreground hover:bg-muted"
                )}
              >
                <Icon className="h-3.5 w-3.5" />
                {label}
              </button>
            ))}
          </div>

          {/* Period selector */}
          <div className="ml-auto flex rounded-md border overflow-hidden text-xs">
            {(["today", "7d", "30d"] as Period[]).map((p) => (
              <button
                key={p}
                onClick={() => setPeriod(p)}
                className={cn(
                  "px-3 py-1.5 transition-colors",
                  period === p
                    ? "bg-primary text-primary-foreground"
                    : "text-muted-foreground hover:bg-muted"
                )}
              >
                {p === "today" ? "Today" : p === "7d" ? "Last 7d" : "Last 30d"}
              </button>
            ))}
          </div>
        </div>

        {selected && (
          <p className="text-xs text-muted-foreground mt-2">
            Showing data for{" "}
            <span className="font-medium text-foreground">{selected.name}</span>
            {selected.plate && (
              <span className="font-mono ml-1">({selected.plate})</span>
            )}
          </p>
        )}
      </div>

      {/* Content */}
      <div className="p-5">
        {loading ? (
          <div className="flex items-center justify-center h-28 text-sm text-muted-foreground">
            Loading…
          </div>
        ) : !data ? (
          <div className="flex items-center justify-center h-28 text-sm text-muted-foreground">
            Select a vehicle to view reports.
          </div>
        ) : (
          <>
            {/* Activity */}
            {tab === "activity" && (
              <div className="grid grid-cols-2 sm:grid-cols-4 xl:grid-cols-7 gap-3">
                {[
                  { label: "Distance", value: `${data.distanceKm} km` },
                  { label: "Driving Time", value: `${data.drivingMinutes} min` },
                  { label: "Idle Time", value: `${data.idleMinutes} min` },
                  {
                    label: "Max Speed",
                    value: `${data.maxSpeedKmh} km/h`,
                    warn: data.maxSpeedKmh > 120,
                  },
                  { label: "Trips", value: data.tripCount },
                  { label: "Violations", value: data.speedViolationCount },
                  {
                    label: "GPS Points",
                    value: data.pointCount?.toLocaleString(),
                  },
                ].map(({ label, value, warn }) => (
                  <div
                    key={label}
                    className={cn(
                      "rounded-lg border p-4 text-center",
                      warn ? "border-rose-300 bg-rose-50" : "bg-muted/30"
                    )}
                  >
                    <p
                      className={cn(
                        "text-2xl font-bold",
                        warn && "text-rose-600"
                      )}
                    >
                      {value}
                    </p>
                    <p className="text-xs text-muted-foreground mt-0.5">
                      {label}
                    </p>
                    {warn && (
                      <p className="text-xs text-rose-500 mt-0.5">⚠️ exceeded</p>
                    )}
                  </div>
                ))}
              </div>
            )}

            {/* Trip log */}
            {tab === "trips" && (
              <div className="overflow-x-auto">
                {!data.trips || data.trips.length === 0 ? (
                  <p className="text-sm text-muted-foreground text-center py-8">
                    No trips recorded in this period.
                  </p>
                ) : (
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-b text-muted-foreground text-left">
                        <th className="pb-2 font-medium">Start</th>
                        <th className="pb-2 font-medium">End</th>
                        <th className="pb-2 font-medium">Duration</th>
                        <th className="pb-2 font-medium">Distance</th>
                        <th className="pb-2 font-medium">Max Speed</th>
                        <th className="pb-2 font-medium">Points</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y">
                      {/* eslint-disable-next-line @typescript-eslint/no-explicit-any */}
                      {data.trips.map((t: any, i: number) => (
                        <tr key={i} className="hover:bg-muted/30">
                          <td className="py-2 tabular-nums text-sm">
                            {new Date(t.startTime).toLocaleString("en-US", {
                              month: "short",
                              day: "numeric",
                              hour: "2-digit",
                              minute: "2-digit",
                            })}
                          </td>
                          <td className="py-2 tabular-nums text-sm text-muted-foreground">
                            {new Date(t.endTime).toLocaleString("en-US", {
                              hour: "2-digit",
                              minute: "2-digit",
                            })}
                          </td>
                          <td className="py-2 font-mono">{t.durationMin}m</td>
                          <td className="py-2 font-mono">
                            {t.distanceKm?.toFixed(1)} km
                          </td>
                          <td
                            className={cn(
                              "py-2 font-mono",
                              t.maxSpeedKmh > 120 &&
                                "text-rose-600 font-semibold"
                            )}
                          >
                            {t.maxSpeedKmh} km/h
                          </td>
                          <td className="py-2 text-muted-foreground">
                            {t.pointCount}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                )}
              </div>
            )}

            {/* Speed violations */}
            {tab === "violations" && (
              <div className="overflow-x-auto">
                {!data.violations || data.violations.length === 0 ? (
                  <p className="text-sm text-muted-foreground text-center py-8">
                    ✅ No speed violations (threshold: {data.thresholdKmh}{" "}
                    km/h).
                  </p>
                ) : (
                  <>
                    <p className="text-sm text-muted-foreground mb-3">
                      Threshold: {data.thresholdKmh} km/h ·{" "}
                      <span className="text-rose-600 font-medium">
                        {data.violations.length} event
                        {data.violations.length !== 1 ? "s" : ""}
                      </span>
                    </p>
                    <table className="w-full text-sm">
                      <thead>
                        <tr className="border-b text-muted-foreground text-left">
                          <th className="pb-2 font-medium">Time</th>
                          <th className="pb-2 font-medium">Location</th>
                          <th className="pb-2 font-medium">Max Speed</th>
                          <th className="pb-2 font-medium">Duration</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y">
                        {/* eslint-disable-next-line @typescript-eslint/no-explicit-any */}
                        {data.violations.map((v: any, i: number) => (
                          <tr key={i} className="hover:bg-muted/30">
                            <td className="py-2 tabular-nums">
                              {new Date(v.startTime).toLocaleString("en-US", {
                                month: "short",
                                day: "numeric",
                                hour: "2-digit",
                                minute: "2-digit",
                              })}
                            </td>
                            <td className="py-2 font-mono text-xs text-muted-foreground">
                              {v.lat?.toFixed(4)}, {v.lon?.toFixed(4)}
                            </td>
                            <td className="py-2 font-mono font-semibold text-rose-600">
                              {v.maxSpeedKmh} km/h
                            </td>
                            <td className="py-2 text-muted-foreground">
                              {v.durationSec}s
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </>
                )}
              </div>
            )}

            {/* Idle time */}
            {tab === "idle" && (
              <div className="overflow-x-auto">
                {!data.episodes || data.episodes.length === 0 ? (
                  <p className="text-sm text-muted-foreground text-center py-8">
                    No idle episodes recorded in this period.
                  </p>
                ) : (
                  <>
                    <p className="text-sm text-muted-foreground mb-3">
                      Total idle:{" "}
                      <span className="font-medium text-foreground">
                        {data.totalIdleMinutes} min
                      </span>{" "}
                      across {data.episodes.length} episode
                      {data.episodes.length !== 1 ? "s" : ""}
                    </p>
                    <table className="w-full text-sm">
                      <thead>
                        <tr className="border-b text-muted-foreground text-left">
                          <th className="pb-2 font-medium">Start</th>
                          <th className="pb-2 font-medium">End</th>
                          <th className="pb-2 font-medium">Duration</th>
                          <th className="pb-2 font-medium">Location</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y">
                        {/* eslint-disable-next-line @typescript-eslint/no-explicit-any */}
                        {data.episodes.map((e: any, i: number) => (
                          <tr key={i} className="hover:bg-muted/30">
                            <td className="py-2 tabular-nums">
                              {new Date(e.startTime).toLocaleString("en-US", {
                                month: "short",
                                day: "numeric",
                                hour: "2-digit",
                                minute: "2-digit",
                              })}
                            </td>
                            <td className="py-2 tabular-nums text-muted-foreground">
                              {new Date(e.endTime).toLocaleString("en-US", {
                                hour: "2-digit",
                                minute: "2-digit",
                              })}
                            </td>
                            <td
                              className={cn(
                                "py-2 font-mono font-medium",
                                e.durationMin >= 30 && "text-amber-600"
                              )}
                            >
                              {e.durationMin} min
                            </td>
                            <td className="py-2 font-mono text-xs text-muted-foreground">
                              {e.lat?.toFixed(4)}, {e.lon?.toFixed(4)}
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </>
                )}
              </div>
            )}

            {/* Geofence activity */}
            {tab === "geofences" && (
              <div className="overflow-x-auto">
                {!data.geofences || data.geofences.length === 0 ? (
                  <p className="text-sm text-muted-foreground text-center py-8">
                    No geofences configured for this vehicle.
                  </p>
                ) : (
                  <>
                    <p className="text-sm text-muted-foreground mb-3">
                      {data.geofences.length} zone
                      {data.geofences.length !== 1 ? "s" : ""} ·{" "}
                      <span className="font-medium text-foreground">
                        {data.geofences.reduce(
                          // eslint-disable-next-line @typescript-eslint/no-explicit-any
                          (s: number, g: any) => s + g.totalEvents,
                          0
                        )}{" "}
                        events
                      </span>{" "}
                      total
                    </p>
                    <table className="w-full text-sm">
                      <thead>
                        <tr className="border-b text-muted-foreground text-left">
                          <th className="pb-2 font-medium">Zone</th>
                          <th className="pb-2 font-medium">Status</th>
                          <th className="pb-2 font-medium">Entries</th>
                          <th className="pb-2 font-medium">Exits</th>
                          <th className="pb-2 font-medium">Total</th>
                          <th className="pb-2 font-medium">Last Event</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y">
                        {/* eslint-disable-next-line @typescript-eslint/no-explicit-any */}
                        {data.geofences.map((g: any, i: number) => (
                          <tr
                            key={i}
                            className={cn(
                              "hover:bg-muted/30",
                              g.totalEvents === 0 && "opacity-50"
                            )}
                          >
                            <td className="py-2 font-medium">{g.geofenceName}</td>
                            <td className="py-2">
                              {g.isActive ? (
                                <span className="text-xs px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-700 font-medium">
                                  Active
                                </span>
                              ) : (
                                <span className="text-xs px-2 py-0.5 rounded-full bg-muted text-muted-foreground">
                                  Inactive
                                </span>
                              )}
                            </td>
                            <td className="py-2 font-mono text-emerald-600 font-medium">
                              {g.enterCount > 0 ? `+${g.enterCount}` : "—"}
                            </td>
                            <td className="py-2 font-mono text-rose-600 font-medium">
                              {g.exitCount > 0 ? `-${g.exitCount}` : "—"}
                            </td>
                            <td className="py-2 font-mono font-bold">
                              {g.totalEvents}
                            </td>
                            <td className="py-2 text-xs text-muted-foreground tabular-nums">
                              {g.lastEventAt
                                ? new Date(g.lastEventAt).toLocaleString(
                                    "en-US",
                                    {
                                      month: "short",
                                      day: "numeric",
                                      hour: "2-digit",
                                      minute: "2-digit",
                                    }
                                  )
                                : "—"}
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </>
                )}
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
}

const PERIOD_LABELS: Record<Period, string> = {
  today: "Today",
  "7d": "Last 7 Days",
  "30d": "Last 30 Days",
};

// ── Helpers ───────────────────────────────────────────────────────────────────

function StatCard({
  label,
  value,
  sub,
  icon: Icon,
  color,
}: {
  label: string;
  value: number | string;
  sub?: string;
  icon: React.ComponentType<{ className?: string }>;
  color: string;
}) {
  return (
    <div className="rounded-lg border bg-card p-5">
      <div className="flex items-start justify-between">
        <div>
          <p className="text-sm text-muted-foreground">{label}</p>
          <p className="text-3xl font-bold mt-1">{value}</p>
          {sub && <p className="text-xs text-muted-foreground mt-0.5">{sub}</p>}
        </div>
        <div className={cn("p-2 rounded-md", color)}>
          <Icon className="h-5 w-5 text-white" />
        </div>
      </div>
    </div>
  );
}

function StatusBar({
  label,
  value,
  total,
  color,
}: {
  label: string;
  value: number;
  total: number;
  color: string;
}) {
  const pct = total > 0 ? Math.round((value / total) * 100) : 0;
  return (
    <div>
      <div className="flex justify-between text-sm mb-1">
        <span className="text-muted-foreground capitalize">{label}</span>
        <span className="font-medium">
          {value}{" "}
          <span className="text-muted-foreground font-normal">({pct}%)</span>
        </span>
      </div>
      <div className="h-2 rounded-full bg-muted overflow-hidden">
        <div
          className={cn("h-full rounded-full transition-all", color)}
          style={{ width: `${pct}%` }}
        />
      </div>
    </div>
  );
}

// ── CSV export ────────────────────────────────────────────────────────────────

function exportCsv(vehicles: VehicleReport[], period: Period) {
  const header = [
    "ID",
    "Name",
    "Plate",
    "Status",
    "Assigned User",
    "Distance (km)",
    "Max Speed (km/h)",
    "GPS Points",
    "Alerts",
  ].join(",");
  const rows = vehicles.map((v) =>
    [
      v.id,
      `"${v.name}"`,
      v.plate ?? "",
      v.status,
      v.assignedUserName ?? "Unassigned",
      v.distanceKm,
      v.maxSpeedKmh,
      v.pointCount,
      v.alertCount,
    ].join(",")
  );
  const csv = [header, ...rows].join("\n");
  const blob = new Blob([csv], { type: "text/csv" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = `vehicle-report-${period}-${new Date().toISOString().slice(0, 10)}.csv`;
  a.click();
  URL.revokeObjectURL(url);
}

// ── Page ──────────────────────────────────────────────────────────────────────

export default function ReportsPage() {
  const [overview, setOverview] = useState<Overview | null>(null);
  const [vehicleData, setVehicleData] = useState<{
    from: string;
    to: string;
    vehicles: VehicleReport[];
  } | null>(null);
  const [period, setPeriod] = useState<Period>("7d");
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [sortKey, setSortKey] = useState<keyof VehicleReport>("distanceKm");
  const [sortDir, setSortDir] = useState<"asc" | "desc">("desc");
  const [vehicleOptions, setVehicleOptions] = useState<VehicleOption[]>([]);

  const load = useCallback(
    async (p: Period, quiet = false) => {
      if (!quiet) setLoading(true);
      else setRefreshing(true);
      try {
        const [ov, vr, vehicles] = await Promise.all([
          getReportsOverview(),
          getVehicleReports(p),
          getAdminVehicles(),
        ]);
        setOverview(ov.data as Overview);
        setVehicleData(vr.data as { from: string; to: string; vehicles: VehicleReport[] });
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        setVehicleOptions((vehicles.data as any[]).map((v) => ({
          id: v.id,
          name: v.name,
          plate: v.plate ?? null,
          status: v.status,
        })));
      } catch {
        // silently fail
      } finally {
        setLoading(false);
        setRefreshing(false);
      }
    },
    []
  );

  useEffect(() => {
    load(period);
  }, [load, period]);

  function handleSort(key: keyof VehicleReport) {
    if (sortKey === key) setSortDir((d) => (d === "asc" ? "desc" : "asc"));
    else {
      setSortKey(key);
      setSortDir("desc");
    }
  }

  const sorted = vehicleData
    ? [...vehicleData.vehicles].sort((a, b) => {
        const av = a[sortKey] ?? 0;
        const bv = b[sortKey] ?? 0;
        if (typeof av === "string" && typeof bv === "string")
          return sortDir === "asc"
            ? av.localeCompare(bv)
            : bv.localeCompare(av);
        return sortDir === "asc"
          ? (av as number) - (bv as number)
          : (bv as number) - (av as number);
      })
    : [];

  const totalVehicles = overview?.totalVehicles ?? 0;

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64 text-muted-foreground">
        Loading reports…
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">Reports & Analytics</h1>
          <p className="text-muted-foreground text-sm mt-0.5">
            Fleet performance overview and per-vehicle statistics
          </p>
        </div>
        <Button
          variant="outline"
          size="sm"
          onClick={() => load(period, true)}
          disabled={refreshing}
        >
          <RefreshCw
            className={cn("h-4 w-4 mr-2", refreshing && "animate-spin")}
          />
          Refresh
        </Button>
      </div>

      {/* Overview stat cards */}
      {overview && (
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          <StatCard
            label="Total Users"
            value={overview.totalUsers}
            sub={`${overview.activeUsers} active`}
            icon={Users}
            color="bg-blue-500"
          />
          <StatCard
            label="Total Vehicles"
            value={overview.totalVehicles}
            sub={`${overview.statusCounts.online} online`}
            icon={Car}
            color="bg-emerald-500"
          />
          <StatCard
            label="Open Alerts"
            value={overview.openAlerts}
            sub={`${overview.alertsThisMonth} this month`}
            icon={AlertTriangle}
            color="bg-rose-500"
          />
          <StatCard
            label="Total Alerts"
            value={overview.totalAlerts}
            sub="all time"
            icon={BarChart2}
            color="bg-violet-500"
          />
        </div>
      )}

      {/* Fleet status + Alerts by type */}
      {overview && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {/* Fleet status breakdown */}
          <div className="rounded-lg border bg-card p-5">
            <h2 className="font-semibold mb-4 flex items-center gap-2">
              <Car className="h-4 w-4 text-muted-foreground" />
              Fleet Status
            </h2>
            <div className="space-y-3">
              <StatusBar
                label="Online"
                value={overview.statusCounts.online}
                total={totalVehicles}
                color="bg-emerald-500"
              />
              <StatusBar
                label="Idle"
                value={overview.statusCounts.idle}
                total={totalVehicles}
                color="bg-amber-400"
              />
              <StatusBar
                label="Offline"
                value={overview.statusCounts.offline}
                total={totalVehicles}
                color="bg-slate-400"
              />
            </div>
          </div>

          {/* Alert type breakdown */}
          <div className="rounded-lg border bg-card p-5">
            <h2 className="font-semibold mb-4 flex items-center gap-2">
              <AlertTriangle className="h-4 w-4 text-muted-foreground" />
              Alerts by Type
            </h2>
            {Object.keys(overview.alertsByType).length === 0 ? (
              <p className="text-sm text-muted-foreground">No alerts recorded.</p>
            ) : (
              <div className="space-y-3">
                {Object.entries(overview.alertsByType)
                  .sort(([, a], [, b]) => b - a)
                  .map(([type, count]) => (
                    <StatusBar
                      key={type}
                      label={type.replace(/_/g, " ")}
                      value={count}
                      total={overview.totalAlerts}
                      color="bg-rose-400"
                    />
                  ))}
              </div>
            )}
          </div>
        </div>
      )}

      {/* Per-vehicle report table */}
      <div className="rounded-lg border bg-card">
        <div className="flex items-center justify-between px-5 py-4 border-b">
          <h2 className="font-semibold flex items-center gap-2">
            <TrendingUp className="h-4 w-4 text-muted-foreground" />
            Vehicle Report
          </h2>
          <div className="flex items-center gap-2">
            {/* Period tabs */}
            <div className="flex rounded-md border overflow-hidden text-sm">
              {(["today", "7d", "30d"] as Period[]).map((p) => (
                <button
                  key={p}
                  onClick={() => setPeriod(p)}
                  className={cn(
                    "px-3 py-1.5 transition-colors",
                    period === p
                      ? "bg-primary text-primary-foreground"
                      : "text-muted-foreground hover:bg-muted"
                  )}
                >
                  {PERIOD_LABELS[p]}
                </button>
              ))}
            </div>
            {/* CSV export */}
            {sorted.length > 0 && (
              <Button
                variant="outline"
                size="sm"
                onClick={() => exportCsv(sorted, period)}
              >
                <Download className="h-4 w-4 mr-1.5" />
                CSV
              </Button>
            )}
          </div>
        </div>

        {vehicleData && (
          <p className="px-5 py-2 text-xs text-muted-foreground border-b">
            Period:{" "}
            {new Date(vehicleData.from).toLocaleDateString("en-US", {
              month: "short",
              day: "numeric",
              hour: "2-digit",
              minute: "2-digit",
            })}{" "}
            →{" "}
            {new Date(vehicleData.to).toLocaleDateString("en-US", {
              month: "short",
              day: "numeric",
              hour: "2-digit",
              minute: "2-digit",
            })}
          </p>
        )}

        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b bg-muted/30">
                {[
                  { key: "name" as keyof VehicleReport, label: "Vehicle" },
                  { key: "status" as keyof VehicleReport, label: "Status" },
                  {
                    key: "assignedUserName" as keyof VehicleReport,
                    label: "Owner",
                  },
                  {
                    key: "distanceKm" as keyof VehicleReport,
                    label: "Distance (km)",
                  },
                  {
                    key: "maxSpeedKmh" as keyof VehicleReport,
                    label: "Max Speed",
                  },
                  {
                    key: "pointCount" as keyof VehicleReport,
                    label: "GPS Points",
                  },
                  {
                    key: "alertCount" as keyof VehicleReport,
                    label: "Alerts",
                  },
                ].map(({ key, label }) => (
                  <th
                    key={key}
                    className="px-4 py-2.5 text-left font-medium text-muted-foreground cursor-pointer select-none hover:text-foreground"
                    onClick={() => handleSort(key)}
                  >
                    {label}
                    {sortKey === key && (
                      <span className="ml-1 text-xs">
                        {sortDir === "asc" ? "↑" : "↓"}
                      </span>
                    )}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {sorted.length === 0 ? (
                <tr>
                  <td
                    colSpan={7}
                    className="px-4 py-10 text-center text-muted-foreground"
                  >
                    No vehicles found.
                  </td>
                </tr>
              ) : (
                sorted.map((v) => (
                  <tr
                    key={v.id}
                    className="border-b last:border-0 hover:bg-muted/30"
                  >
                    <td className="px-4 py-3">
                      <div className="font-medium">{v.name}</div>
                      {v.plate && (
                        <div className="text-xs text-muted-foreground font-mono">
                          {v.plate}
                        </div>
                      )}
                    </td>
                    <td className="px-4 py-3">
                      <span
                        className={cn(
                          "inline-flex items-center gap-1.5 text-xs font-medium px-2 py-0.5 rounded-full",
                          v.status === "online"
                            ? "bg-emerald-100 text-emerald-700"
                            : v.status === "idle"
                            ? "bg-amber-100 text-amber-700"
                            : "bg-slate-100 text-slate-500"
                        )}
                      >
                        <span
                          className={cn(
                            "h-1.5 w-1.5 rounded-full",
                            v.status === "online"
                              ? "bg-emerald-500"
                              : v.status === "idle"
                              ? "bg-amber-400"
                              : "bg-slate-400"
                          )}
                        />
                        {v.status}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-muted-foreground">
                      {v.assignedUserName ?? (
                        <span className="italic text-slate-400">Unassigned</span>
                      )}
                    </td>
                    <td className="px-4 py-3 font-mono font-medium">
                      {v.distanceKm > 0 ? (
                        <span>{v.distanceKm.toFixed(1)} km</span>
                      ) : (
                        <span className="text-muted-foreground">—</span>
                      )}
                    </td>
                    <td className="px-4 py-3 font-mono">
                      {v.maxSpeedKmh > 0 ? (
                        <span
                          className={cn(
                            v.maxSpeedKmh > 120 && "text-rose-600 font-semibold"
                          )}
                        >
                          {v.maxSpeedKmh} km/h
                        </span>
                      ) : (
                        <span className="text-muted-foreground">—</span>
                      )}
                    </td>
                    <td className="px-4 py-3 text-muted-foreground tabular-nums">
                      {v.pointCount.toLocaleString()}
                    </td>
                    <td className="px-4 py-3">
                      {v.alertCount > 0 ? (
                        <span className="inline-flex items-center justify-center h-5 min-w-5 rounded-full bg-rose-100 text-rose-700 text-xs font-semibold px-1.5">
                          {v.alertCount}
                        </span>
                      ) : (
                        <span className="text-muted-foreground">0</span>
                      )}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Per-vehicle drill-down */}
      {vehicleOptions.length > 0 && (
        <VehicleDrillDown vehicles={vehicleOptions} />
      )}
    </div>
  );
}
