"use client";

import { useEffect, useRef, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { getUsers, getAdminVehicles, getAlerts, ackAlert } from "@/lib/api";
import { relativeTime } from "@/lib/utils";
import { toast } from "sonner";
import { Users, Car, Bell, AlertTriangle, CheckCheck } from "lucide-react";

interface Alert {
  id: string;
  type: string;
  status: string;
  deviceId: string;
  message: string | null;
  createdAt: string;
}

interface Vehicle {
  status: string;
  assignedUserId: number | null;
}

const TYPE_LABELS: Record<string, string> = {
  geofence_enter: "Geofence Enter",
  geofence_exit: "Geofence Exit",
  low_battery: "Low Battery",
  speed_limit: "Speed Limit",
  sos: "SOS",
};

const TYPE_COLORS: Record<string, string> = {
  geofence_enter: "bg-trackeo-pastel-green text-trackeo-online",
  geofence_exit: "bg-trackeo-pastel-orange text-amber-600",
  low_battery: "bg-trackeo-pastel-red text-trackeo-alert",
  speed_limit: "bg-trackeo-pastel-red text-trackeo-alert",
  sos: "bg-trackeo-pastel-red text-trackeo-alert",
};

const REFRESH_INTERVAL = 60_000;

export default function DashboardPage() {
  const [users, setUsers] = useState(0);
  const [vehicles, setVehicles] = useState<Vehicle[]>([]);
  const [alerts, setAlerts] = useState<Alert[]>([]);
  const [acking, setAcking] = useState<string | null>(null);
  const intervalRef = useRef<ReturnType<typeof setInterval>>(null);

  function fetchAll() {
    return Promise.allSettled([
      getUsers().then((r) => setUsers(r.data?.length ?? 0)),
      getAdminVehicles().then((r) => setVehicles(r.data ?? [])),
      getAlerts().then((r) => setAlerts(r.data ?? [])),
    ]);
  }

  useEffect(() => {
    fetchAll();
    intervalRef.current = setInterval(fetchAll, REFRESH_INTERVAL);
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
      toast.success("Alert acknowledged");
    } catch {
      toast.error("Failed to acknowledge alert");
    } finally {
      setAcking(null);
    }
  }

  const online = vehicles.filter((v) => v.status === "online").length;
  const idle = vehicles.filter((v) => v.status === "idle").length;
  const unassigned = vehicles.filter((v) => v.assignedUserId === null).length;
  const openAlerts = alerts.filter((a) => a.status === "open");
  const recentOpen = openAlerts.slice(0, 5);

  const cards = [
    {
      label: "Users",
      value: String(users),
      icon: Users,
      iconBg: "bg-trackeo-pastel-blue",
      iconColor: "text-trackeo-idle",
    },
    {
      label: "Vehicles",
      value: `${online + idle}/${vehicles.length}`,
      sub: "active",
      icon: Car,
      iconBg: "bg-trackeo-pastel-green",
      iconColor: "text-trackeo-online",
    },
    {
      label: "Open Alerts",
      value: String(openAlerts.length),
      icon: Bell,
      iconBg: openAlerts.length > 0 ? "bg-trackeo-pastel-red" : "bg-muted",
      iconColor: openAlerts.length > 0 ? "text-trackeo-alert" : "text-muted-foreground",
    },
    {
      label: "Unassigned",
      value: String(unassigned),
      sub: "vehicles",
      icon: AlertTriangle,
      iconBg: unassigned > 0 ? "bg-trackeo-pastel-orange" : "bg-muted",
      iconColor: unassigned > 0 ? "text-trackeo-warning" : "text-muted-foreground",
    },
  ];

  return (
    <div>
      <h1 className="text-2xl font-bold text-trackeo-dark mb-6">Dashboard</h1>

      <div className="grid gap-4 grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 mb-8">
        {cards.map(({ label, value, sub, icon: Icon, iconBg, iconColor }) => (
          <Card key={label}>
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">{label}</CardTitle>
              <div className={`h-9 w-9 rounded-lg ${iconBg} flex items-center justify-center`}>
                <Icon className={`h-4.5 w-4.5 ${iconColor}`} />
              </div>
            </CardHeader>
            <CardContent>
              <div className="text-3xl font-bold tabular-nums text-foreground">{value}</div>
              {sub && <p className="text-xs text-muted-foreground mt-0.5">{sub}</p>}
            </CardContent>
          </Card>
        ))}
      </div>

      {recentOpen.length > 0 ? (
        <div>
          <div className="flex items-center justify-between mb-3">
            <h2 className="text-base font-semibold text-foreground">Open Alerts</h2>
            <a href="/alerts" className="text-xs font-medium text-trackeo-primary hover:text-trackeo-primary-dark transition-colors">
              View all →
            </a>
          </div>
          <Card>
            <div className="divide-y divide-border">
              {recentOpen.map((alert) => (
                <div key={alert.id} className="flex items-center gap-3 px-4 py-3">
                  <span className="h-2 w-2 rounded-full bg-trackeo-alert shrink-0 animate-pulse" />
                  <span className={`inline-flex items-center rounded-md px-2 py-0.5 text-[11px] font-semibold shrink-0 ${TYPE_COLORS[alert.type] ?? "bg-muted text-muted-foreground"}`}>
                    {TYPE_LABELS[alert.type] ?? alert.type}
                  </span>
                  <span className="text-xs font-mono text-muted-foreground shrink-0">
                    {alert.deviceId}
                  </span>
                  {alert.message && (
                    <span className="text-sm text-muted-foreground truncate flex-1">
                      {alert.message}
                    </span>
                  )}
                  <span
                    className="text-xs text-muted-foreground shrink-0 ml-auto"
                    title={new Date(alert.createdAt).toLocaleString()}
                  >
                    {relativeTime(alert.createdAt)}
                  </span>
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => handleAck(alert)}
                    disabled={acking === alert.id}
                    className="gap-1 h-7 text-xs shrink-0 hover:bg-trackeo-pastel-green hover:text-trackeo-online hover:border-trackeo-online/30"
                  >
                    <CheckCheck className="h-3 w-3" />
                    {acking === alert.id ? "..." : "Ack"}
                  </Button>
                </div>
              ))}
            </div>
          </Card>
        </div>
      ) : alerts.length > 0 ? (
        <Card className="px-4 py-6 text-center">
          <p className="text-muted-foreground text-sm">All clear — no open alerts.</p>
        </Card>
      ) : null}
    </div>
  );
}
