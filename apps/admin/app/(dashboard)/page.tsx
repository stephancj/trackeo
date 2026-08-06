"use client";

import { useEffect, useRef, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { getReportsOverview, ackAlert } from "@/lib/api";
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
  geofence_enter: "Entrée de zone",
  geofence_exit: "Sortie de zone",
  low_battery: "Batterie faible",
  speed_limit: "Excès de vitesse",
  sos: "SOS",
  sleep_movement: "Mouvement en veille",
};

const TYPE_COLORS: Record<string, string> = {
  geofence_enter: "bg-trackeo-pastel-green text-trackeo-online",
  geofence_exit: "bg-trackeo-pastel-orange text-amber-600",
  low_battery: "bg-trackeo-pastel-red text-trackeo-alert",
  speed_limit: "bg-trackeo-pastel-red text-trackeo-alert",
  sos: "bg-trackeo-pastel-red text-trackeo-alert",
  sleep_movement: "bg-trackeo-pastel-red text-trackeo-alert",
};

const REFRESH_INTERVAL = 60_000;

export default function DashboardPage() {
  const [overview, setOverview] = useState<any>(null);
  const [alerts, setAlerts] = useState<Alert[]>([]);
  const [acking, setAcking] = useState<string | null>(null);
  const intervalRef = useRef<ReturnType<typeof setInterval>>(null);

  function fetchAll() {
    return getReportsOverview().then((r) => {
      setOverview(r.data);
      setAlerts(r.data.recentOpenAlerts ?? []);
    });
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
      toast.success("Alerte acquittée");
    } catch {
      toast.error("Impossible d’acquitter l’alerte");
    } finally {
      setAcking(null);
    }
  }

  if (!overview) return <div className="p-8 text-center text-muted-foreground">Loading...</div>;

  const cards = [
    {
      label: "Utilisateurs",
      value: String(overview.totalUsers),
      icon: Users,
      iconBg: "bg-trackeo-pastel-blue",
      iconColor: "text-trackeo-idle",
    },
    {
      label: "Véhicules",
      value: `${overview.statusCounts.online + overview.statusCounts.idle}/${overview.totalVehicles}`,
      sub: "actifs",
      icon: Car,
      iconBg: "bg-trackeo-pastel-green",
      iconColor: "text-trackeo-online",
    },
    {
      label: "Alertes ouvertes",
      value: String(overview.openAlerts),
      icon: Bell,
      iconBg: overview.openAlerts > 0 ? "bg-trackeo-pastel-red" : "bg-muted",
      iconColor: overview.openAlerts > 0 ? "text-trackeo-alert" : "text-muted-foreground",
    },
    {
      label: "Non assignés",
      value: String(overview.unassignedVehicles),
      sub: "véhicules",
      icon: AlertTriangle,
      iconBg: overview.unassignedVehicles > 0 ? "bg-trackeo-pastel-orange" : "bg-muted",
      iconColor: overview.unassignedVehicles > 0 ? "text-trackeo-warning" : "text-muted-foreground",
    },
  ];

  return (
    <div>
      <h1 className="text-2xl font-bold text-trackeo-dark mb-6">Vue d’ensemble</h1>

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

      {alerts.length > 0 ? (
        <div>
          <div className="flex items-center justify-between mb-3">
            <h2 className="text-base font-semibold text-foreground">Alertes à traiter</h2>
            <a href="/alerts" className="text-xs font-medium text-trackeo-primary hover:text-trackeo-primary-dark transition-colors">
              Tout voir
            </a>
          </div>
          <Card>
            <div className="divide-y divide-border">
              {alerts.map((alert) => (
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
                    {acking === alert.id ? "..." : "Acquitter"}
                  </Button>
                </div>
              ))}
            </div>
          </Card>
        </div>
      ) : (
        <Card className="px-4 py-6 text-center">
          <p className="text-muted-foreground text-sm">Aucune alerte ouverte.</p>
        </Card>
      )}
    </div>
  );
}
