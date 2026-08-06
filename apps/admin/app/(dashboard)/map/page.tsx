"use client";

import { useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { getAdminVehicles } from "@/lib/api";
import { relativeTime } from "@/lib/utils";
import { OSMMap, MapMarker } from "@/components/map/osm-map";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { RefreshCw } from "lucide-react";

interface Vehicle {
  id: number;
  name: string;
  plate: string | null;
  status: "online" | "idle" | "offline";
  lastUpdate: string | null;
  assignedUserName: string | null;
  openAlertsCount: number;
  position?: {
    lat: number;
    lon: number;
    speedKmh: number;
    battery: number | null;
  } | null;
}

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

const MARKER_COLOR: Record<string, MapMarker["color"]> = {
  online: "green",
  idle: "yellow",
  offline: "gray",
};

const REFRESH_INTERVAL = 15_000;

export default function FleetMapPage() {
  const router = useRouter();
  const [vehicles, setVehicles] = useState<Vehicle[]>([]);
  const [loading, setLoading] = useState(true);
  const [lastRefresh, setLastRefresh] = useState<Date>(new Date());
  const [selected, setSelected] = useState<Vehicle | null>(null);
  const intervalRef = useRef<ReturnType<typeof setInterval>>(null);

  function fetchVehicles() {
    return getAdminVehicles(1, 1000)
      .then((r) => {
        setVehicles(r.data.data || []);
        setLastRefresh(new Date());
      });
  }

  useEffect(() => {
    fetchVehicles().finally(() => setLoading(false));
    intervalRef.current = setInterval(fetchVehicles, REFRESH_INTERVAL);
    return () => { if (intervalRef.current) clearInterval(intervalRef.current); };
  }, []);

  const vehiclesWithPosition = vehicles.filter((v) => v.position?.lat && v.position?.lon);

  const markers: MapMarker[] = vehiclesWithPosition.map((v) => ({
    lat: v.position!.lat,
    lon: v.position!.lon,
    color: MARKER_COLOR[v.status],
    label: `${v.name}${v.plate ? ` · ${v.plate}` : ""}`,
    onClick: () => setSelected(v),
  }));

  const counts = {
    online: vehicles.filter((v) => v.status === "online").length,
    idle: vehicles.filter((v) => v.status === "idle").length,
    offline: vehicles.filter((v) => v.status === "offline").length,
  };

  return (
    <div className="flex flex-col h-[calc(100vh-4rem)] -mx-6 -my-6">
      {/* Toolbar */}
      <div className="flex items-center justify-between px-6 py-3 border-b bg-card shrink-0">
        <div className="flex items-center gap-4">
          <h1 className="text-lg font-bold">Fleet Map</h1>
          <div className="flex items-center gap-3 text-sm">
            <span className="flex items-center gap-1.5">
              <span className="h-2 w-2 rounded-full bg-trackeo-online" /> {counts.online} online
            </span>
            <span className="flex items-center gap-1.5">
              <span className="h-2 w-2 rounded-full bg-trackeo-idle" /> {counts.idle} idle
            </span>
            <span className="flex items-center gap-1.5">
              <span className="h-2 w-2 rounded-full bg-trackeo-offline" /> {counts.offline} offline
            </span>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <span className="text-xs text-muted-foreground">Refreshes every 15s · {relativeTime(lastRefresh)}</span>
          <Button size="sm" variant="outline" onClick={fetchVehicles} className="gap-1.5">
            <RefreshCw className="h-3.5 w-3.5" />
            Refresh
          </Button>
        </div>
      </div>

      <div className="flex flex-1 overflow-hidden">
        {/* Sidebar */}
        <div className="w-72 border-r bg-card overflow-y-auto shrink-0">
          {loading ? (
            <div className="p-3 space-y-2">
              {Array.from({ length: 5 }).map((_, i) => (
                <Skeleton key={i} className="h-16 rounded-lg" />
              ))}
            </div>
          ) : (
            <div className="p-2 space-y-1">
              {vehicles.map((v) => (
                <div
                  key={v.id}
                  className={`p-3 rounded-lg cursor-pointer transition-colors border ${
                    selected?.id === v.id
                      ? "bg-primary/10 border-primary/30"
                      : "bg-transparent border-transparent hover:bg-muted/50"
                  }`}
                  onClick={() => setSelected(selected?.id === v.id ? null : v)}
                >
                  <div className="flex items-center gap-2 mb-1">
                    <span className={`h-2 w-2 rounded-full shrink-0 ${STATUS_DOT[v.status]}`} />
                    <span className="font-medium text-sm truncate">{v.name}</span>
                    {v.openAlertsCount > 0 && (
                      <span className="ml-auto shrink-0 inline-flex items-center justify-center h-4 min-w-4 px-1 rounded-full bg-destructive text-destructive-foreground text-xs font-semibold">
                        {v.openAlertsCount}
                      </span>
                    )}
                  </div>
                  <div className="flex items-center justify-between text-xs text-muted-foreground">
                    <span>{STATUS_LABEL[v.status]}</span>
                    <span>{relativeTime(v.lastUpdate)}</span>
                  </div>
                  {v.position?.battery != null && (
                    <div className="mt-1 flex items-center gap-1.5">
                      <div className="w-10 h-1.5 bg-muted rounded-full overflow-hidden">
                        <div
                          className={`h-full rounded-full ${v.position.battery > 50 ? "bg-trackeo-online" : v.position.battery > 20 ? "bg-trackeo-idle" : "bg-trackeo-alert"}`}
                          style={{ width: `${v.position.battery}%` }}
                        />
                      </div>
                      <span className="text-xs text-muted-foreground">{v.position.battery}%</span>
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Map */}
        <div className="flex-1 relative">
          {loading ? (
            <div className="h-full bg-muted/30 flex items-center justify-center text-muted-foreground">
              Loading map…
            </div>
          ) : (
            <OSMMap
              markers={markers}
              zoom={12}
              className="h-full w-full"
            />
          )}

          {/* Selected vehicle popover */}
          {selected && (
            <div className="absolute bottom-6 left-1/2 -translate-x-1/2 z-[1000] bg-card border rounded-xl shadow-xl p-4 min-w-64">
              <div className="flex items-center gap-2 mb-2">
                <span className={`h-2.5 w-2.5 rounded-full ${STATUS_DOT[selected.status]}`} />
                <span className="font-semibold">{selected.name}</span>
                {selected.plate && <span className="text-xs text-muted-foreground">{selected.plate}</span>}
              </div>
              <div className="grid grid-cols-2 gap-x-4 gap-y-1 text-sm mb-3">
                <span className="text-muted-foreground">Status</span>
                <span className="font-medium">{STATUS_LABEL[selected.status]}</span>
                {selected.position?.speedKmh != null && (
                  <>
                    <span className="text-muted-foreground">Speed</span>
                    <span className="font-medium">{Math.round(selected.position.speedKmh)} km/h</span>
                  </>
                )}
                {selected.position?.battery != null && (
                  <>
                    <span className="text-muted-foreground">Battery</span>
                    <span className="font-medium">{selected.position.battery}%</span>
                  </>
                )}
                {selected.assignedUserName && (
                  <>
                    <span className="text-muted-foreground">Owner</span>
                    <span className="font-medium truncate">{selected.assignedUserName}</span>
                  </>
                )}
                <span className="text-muted-foreground">Last seen</span>
                <span className="font-medium">{relativeTime(selected.lastUpdate)}</span>
              </div>
              <Button
                size="sm"
                className="w-full"
                onClick={() => router.push(`/vehicles/${selected.id}`)}
              >
                View Detail →
              </Button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
