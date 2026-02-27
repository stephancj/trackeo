"use client";

import { useEffect, useState } from "react";
import { getAlerts } from "@/lib/api";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";

interface Alert {
  id: string;
  type: string;
  status: string;
  deviceId: string;
  createdAt: string;
}

const TYPE_LABELS: Record<string, string> = {
  geofence_enter: "Geofence Enter",
  geofence_exit: "Geofence Exit",
  low_battery: "Low Battery",
  speed_limit: "Speed Limit",
  sos: "SOS",
};

function typeBadge(type: string) {
  if (type === "geofence_exit") return "destructive";
  if (type === "geofence_enter") return "default";
  if (type === "sos") return "destructive";
  return "secondary";
}

function statusBadge(status: string) {
  if (status === "open") return "destructive";
  if (status === "acked") return "secondary";
  return "outline";
}

export default function AlertsPage() {
  const [alerts, setAlerts] = useState<Alert[]>([]);
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getAlerts()
      .then((res) => setAlerts(res.data))
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  const filtered = alerts.filter(
    (a) =>
      a.type?.toLowerCase().includes(search.toLowerCase()) ||
      a.deviceId?.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Alerts</h1>
      <div className="mb-4">
        <Input
          placeholder="Filter by type or device..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="max-w-sm"
        />
      </div>
      <div className="rounded-md border bg-card">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Type</TableHead>
              <TableHead>Device ID</TableHead>
              <TableHead>Status</TableHead>
              <TableHead>Date</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {loading ? (
              Array.from({ length: 5 }).map((_, i) => (
                <TableRow key={i}>
                  {Array.from({ length: 4 }).map((_, j) => (
                    <TableCell key={j}>
                      <Skeleton className="h-4 w-full" />
                    </TableCell>
                  ))}
                </TableRow>
              ))
            ) : filtered.length === 0 ? (
              <TableRow>
                <TableCell colSpan={4} className="text-center text-muted-foreground py-8">
                  No alerts found
                </TableCell>
              </TableRow>
            ) : (
              filtered.map((alert) => (
                <TableRow key={alert.id}>
                  <TableCell>
                    <Badge variant={typeBadge(alert.type) as "default" | "secondary" | "destructive" | "outline"}>
                      {TYPE_LABELS[alert.type] ?? alert.type}
                    </Badge>
                  </TableCell>
                  <TableCell className="font-mono text-sm">{alert.deviceId}</TableCell>
                  <TableCell>
                    <Badge variant={statusBadge(alert.status) as "default" | "secondary" | "destructive" | "outline"}>
                      {alert.status}
                    </Badge>
                  </TableCell>
                  <TableCell className="text-muted-foreground text-sm">
                    {new Date(alert.createdAt).toLocaleString()}
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
