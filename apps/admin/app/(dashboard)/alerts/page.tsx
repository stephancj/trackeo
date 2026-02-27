"use client";

import { useEffect, useRef, useState } from "react";
import { getAlerts, ackAlert } from "@/lib/api";
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
import { Skeleton } from "@/components/ui/skeleton";
import { CheckCheck, RefreshCw } from "lucide-react";

interface Alert {
  id: string;
  type: string;
  status: string;
  deviceId: string;
  message: string | null;
  createdAt: string;
}

const TYPE_LABELS: Record<string, string> = {
  geofence_enter: "Geofence Enter",
  geofence_exit: "Geofence Exit",
  low_battery: "Low Battery",
  speed_limit: "Speed Limit",
  sos: "SOS",
};

function typeBadgeClass(type: string): "default" | "secondary" | "destructive" | "outline" {
  if (type === "geofence_exit" || type === "sos") return "destructive";
  if (type === "geofence_enter") return "default";
  return "secondary";
}

type Tab = "all" | "open" | "acked";

const REFRESH_INTERVAL = 30_000;

export default function AlertsPage() {
  const [alerts, setAlerts] = useState<Alert[]>([]);
  const [tab, setTab] = useState<Tab>("open");
  const [loading, setLoading] = useState(true);
  const [acking, setAcking] = useState<string | null>(null);
  const [lastRefresh, setLastRefresh] = useState<Date>(new Date());
  const intervalRef = useRef<ReturnType<typeof setInterval>>(null);

  function fetchAlerts() {
    return getAlerts()
      .then((r) => {
        setAlerts(r.data);
        setLastRefresh(new Date());
      })
      .catch(() => toast.error("Failed to load alerts"));
  }

  useEffect(() => {
    fetchAlerts().finally(() => setLoading(false));
    intervalRef.current = setInterval(fetchAlerts, REFRESH_INTERVAL);
    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current);
    };
  }, []);

  async function handleAck(alert: Alert) {
    setAcking(alert.id);
    try {
      await ackAlert(alert.id);
      setAlerts((prev) =>
        prev.map((a) => (a.id === alert.id ? { ...a, status: "acked" } : a))
      );
      toast.success(`Alert acknowledged`, {
        description: TYPE_LABELS[alert.type] ?? alert.type,
      });
    } catch {
      toast.error("Failed to acknowledge alert");
    } finally {
      setAcking(null);
    }
  }

  const counts = {
    all: alerts.length,
    open: alerts.filter((a) => a.status === "open").length,
    acked: alerts.filter((a) => a.status === "acked").length,
  };

  const filtered = tab === "all" ? alerts : alerts.filter((a) => a.status === tab);

  const tabs: { key: Tab; label: string }[] = [
    { key: "open", label: `Open (${counts.open})` },
    { key: "all", label: `All (${counts.all})` },
    { key: "acked", label: `Acknowledged (${counts.acked})` },
  ];

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold">Alerts</h1>
        <div className="flex items-center gap-3">
          <span className="text-xs text-muted-foreground">
            Updated {relativeTime(lastRefresh)}
          </span>
          <Button
            size="sm"
            variant="outline"
            onClick={() => fetchAlerts()}
            className="gap-1.5"
          >
            <RefreshCw className="h-3.5 w-3.5" />
            Refresh
          </Button>
        </div>
      </div>

      <div className="flex gap-2 mb-4">
        {tabs.map((t) => (
          <button
            key={t.key}
            onClick={() => setTab(t.key)}
            className={`px-3 py-1 rounded-full text-sm font-medium border transition-colors ${
              tab === t.key
                ? "bg-primary text-primary-foreground border-primary"
                : "bg-card text-muted-foreground border-border hover:text-foreground"
            }`}
          >
            {t.label}
          </button>
        ))}
      </div>

      <div className="rounded-md border bg-card">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Type</TableHead>
              <TableHead>Device</TableHead>
              <TableHead>Message</TableHead>
              <TableHead>Status</TableHead>
              <TableHead>When</TableHead>
              <TableHead className="w-24"></TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {loading ? (
              Array.from({ length: 5 }).map((_, i) => (
                <TableRow key={i}>
                  {Array.from({ length: 6 }).map((_, j) => (
                    <TableCell key={j}>
                      <Skeleton className="h-4 w-full" />
                    </TableCell>
                  ))}
                </TableRow>
              ))
            ) : filtered.length === 0 ? (
              <TableRow>
                <TableCell colSpan={6} className="py-12 text-center">
                  <p className="text-muted-foreground font-medium">
                    {tab === "open" ? "No open alerts — all clear." : "No alerts found."}
                  </p>
                </TableCell>
              </TableRow>
            ) : (
              filtered.map((alert) => (
                <TableRow
                  key={alert.id}
                  className={alert.status === "open" ? "bg-destructive/5" : ""}
                >
                  <TableCell>
                    <Badge variant={typeBadgeClass(alert.type)}>
                      {TYPE_LABELS[alert.type] ?? alert.type}
                    </Badge>
                  </TableCell>
                  <TableCell className="font-mono text-xs text-muted-foreground">
                    {alert.deviceId}
                  </TableCell>
                  <TableCell className="text-sm text-muted-foreground max-w-[200px] truncate">
                    {alert.message || "—"}
                  </TableCell>
                  <TableCell>
                    <span
                      className={`inline-flex items-center gap-1.5 text-xs font-medium ${
                        alert.status === "open"
                          ? "text-destructive"
                          : "text-muted-foreground"
                      }`}
                    >
                      {alert.status === "open" && (
                        <span className="inline-block h-1.5 w-1.5 rounded-full bg-destructive" />
                      )}
                      {alert.status}
                    </span>
                  </TableCell>
                  <TableCell
                    className="text-sm text-muted-foreground"
                    title={new Date(alert.createdAt).toLocaleString()}
                  >
                    {relativeTime(alert.createdAt)}
                  </TableCell>
                  <TableCell>
                    {alert.status === "open" && (
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => handleAck(alert)}
                        disabled={acking === alert.id}
                        className="gap-1.5 h-7 text-xs"
                      >
                        <CheckCheck className="h-3 w-3" />
                        {acking === alert.id ? "..." : "Ack"}
                      </Button>
                    )}
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </div>
    </div>
  );
}
