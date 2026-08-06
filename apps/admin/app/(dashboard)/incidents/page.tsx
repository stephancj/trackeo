"use client";

import { useEffect, useRef, useState } from "react";
import { getIncidents } from "@/lib/api";
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
import { RefreshCw, ShieldAlert, AlertTriangle } from "lucide-react";
import { IncidentSheet } from "./incident-sheet";

export interface Incident {
  id: string;
  type: string;
  status: string;
  severity: string;
  deviceId: string;
  title: string;
  description: string | null;
  createdAt: string;
  escalateAt: string | null;
}

const TYPE_LABELS: Record<string, string> = {
  sos: "Détresse (SOS)",
  theft: "Véhicule Volé",
};

const STATUS_LABELS: Record<string, string> = {
  open: "Nouveau",
  acknowledged: "Pris en charge",
  in_progress: "En cours",
  escalated: "Escaladé",
  resolved: "Résolu",
  cancelled: "Annulé",
  false_alarm: "Fausse alarme",
};

function statusBadgeVariant(status: string): "default" | "secondary" | "destructive" | "outline" {
  if (status === "open" || status === "escalated") return "destructive";
  if (status === "acknowledged" || status === "in_progress") return "default";
  if (status === "resolved") return "outline";
  return "secondary";
}

type Tab = "active" | "all" | "resolved";

const REFRESH_INTERVAL = 30_000;

export default function IncidentsPage() {
  const [incidents, setIncidents] = useState<Incident[]>([]);
  const [tab, setTab] = useState<Tab>("active");
  const [loading, setLoading] = useState(true);
  const [lastRefresh, setLastRefresh] = useState<Date>(new Date());
  const [selectedIncidentId, setSelectedIncidentId] = useState<string | null>(null);
  const intervalRef = useRef<ReturnType<typeof setInterval>>(null);

  function fetchIncidents() {
    return getIncidents()
      .then((r) => {
        setIncidents(r.data);
        setLastRefresh(new Date());
      })
      .catch(() => toast.error("Erreur lors du chargement des incidents"));
  }

  useEffect(() => {
    fetchIncidents().finally(() => setLoading(false));
    intervalRef.current = setInterval(fetchIncidents, REFRESH_INTERVAL);
    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current);
    };
  }, []);

  const counts = {
    all: incidents.length,
    active: incidents.filter((a) => !["resolved", "cancelled", "false_alarm"].includes(a.status)).length,
    resolved: incidents.filter((a) => ["resolved", "cancelled", "false_alarm"].includes(a.status)).length,
  };

  const filtered = tab === "all" ? incidents : 
    tab === "active" ? incidents.filter((a) => !["resolved", "cancelled", "false_alarm"].includes(a.status)) :
    incidents.filter((a) => ["resolved", "cancelled", "false_alarm"].includes(a.status));

  const tabs: { key: Tab; label: string }[] = [
    { key: "active", label: `Actifs (${counts.active})` },
    { key: "all", label: `Tous (${counts.all})` },
    { key: "resolved", label: `Clôturés (${counts.resolved})` },
  ];

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold flex items-center gap-2">
            <ShieldAlert className="h-6 w-6 text-destructive" />
            Incidents Sécurité
          </h1>
          <p className="text-sm text-muted-foreground mt-1">
            Gérez les SOS et déclarations de vol (Cycle de vie, escalade, résolution).
          </p>
        </div>
        <div className="flex items-center gap-3">
          <span className="text-xs text-muted-foreground">
            Mis à jour {relativeTime(lastRefresh)}
          </span>
          <Button
            size="sm"
            variant="outline"
            onClick={() => fetchIncidents()}
            className="gap-1.5"
          >
            <RefreshCw className="h-3.5 w-3.5" />
            Rafraîchir
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
                ? "bg-destructive text-white border-destructive"
                : "bg-card text-muted-foreground border-border hover:text-foreground"
            }`}
          >
            {t.label}
          </button>
        ))}
      </div>

      <div className="overflow-x-auto rounded-md border bg-card">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Type</TableHead>
              <TableHead>Véhicule / Titre</TableHead>
              <TableHead>Statut</TableHead>
              <TableHead>Création</TableHead>
              <TableHead>Escalade auto.</TableHead>
              <TableHead className="w-24 text-right">Actions</TableHead>
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
                  <p className="text-muted-foreground font-medium flex items-center justify-center gap-2">
                    {tab === "active" ? (
                      <>
                        <CheckCircle className="h-5 w-5 text-green-500" />
                        Aucun incident actif.
                      </>
                    ) : "Aucun incident trouvé."}
                  </p>
                </TableCell>
              </TableRow>
            ) : (
              filtered.map((incident) => (
                <TableRow
                  key={incident.id}
                  className={incident.status === "open" ? "bg-destructive/5" : ""}
                >
                  <TableCell>
                    <div className="flex items-center gap-2">
                      <AlertTriangle className={`h-4 w-4 ${incident.type === 'sos' ? 'text-orange-500' : 'text-red-600'}`} />
                      <span className="font-semibold">{TYPE_LABELS[incident.type] ?? incident.type}</span>
                    </div>
                  </TableCell>
                  <TableCell>
                    <div className="font-medium">{incident.title}</div>
                    <div className="text-xs text-muted-foreground mt-0.5">Device: {incident.deviceId}</div>
                  </TableCell>
                  <TableCell>
                    <Badge variant={statusBadgeVariant(incident.status)}>
                      {STATUS_LABELS[incident.status] ?? incident.status}
                    </Badge>
                  </TableCell>
                  <TableCell
                    className="text-sm text-muted-foreground"
                    title={new Date(incident.createdAt).toLocaleString()}
                  >
                    {relativeTime(incident.createdAt)}
                  </TableCell>
                  <TableCell className="text-sm text-muted-foreground">
                    {["resolved", "cancelled", "false_alarm", "escalated"].includes(incident.status) ? (
                      "—"
                    ) : incident.escalateAt ? (
                      <span className={new Date(incident.escalateAt) < new Date() ? "text-destructive font-semibold" : ""}>
                        {relativeTime(incident.escalateAt)}
                      </span>
                    ) : (
                      "—"
                    )}
                  </TableCell>
                  <TableCell className="text-right">
                    <Button
                      size="sm"
                      variant={incident.status === "open" ? "default" : "secondary"}
                      onClick={() => setSelectedIncidentId(incident.id)}
                    >
                      Détails
                    </Button>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </div>

      {selectedIncidentId && (
        <IncidentSheet 
          incidentId={selectedIncidentId} 
          onClose={() => {
            setSelectedIncidentId(null);
            fetchIncidents();
          }} 
        />
      )}
    </div>
  );
}

function CheckCircle(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg
      {...props}
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
      <polyline points="22 4 12 14.01 9 11.01" />
    </svg>
  );
}
