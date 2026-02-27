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
} from "lucide-react";
import { getReportsOverview, getVehicleReports } from "@/lib/api";
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

  const load = useCallback(
    async (p: Period, quiet = false) => {
      if (!quiet) setLoading(true);
      else setRefreshing(true);
      try {
        const [ov, vr] = await Promise.all([
          getReportsOverview(),
          getVehicleReports(p),
        ]);
        setOverview(ov.data as Overview);
        setVehicleData(vr.data as { from: string; to: string; vehicles: VehicleReport[] });
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
    </div>
  );
}
