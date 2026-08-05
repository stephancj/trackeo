"use client";

import { useEffect, useState } from "react";
import { getIncidents, updateIncident } from "@/lib/api";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { ShieldAlert, Clock3, MapPin, CheckCircle2 } from "lucide-react";
import { toast } from "sonner";

type Incident = { id: string; deviceId: number; ownerId: number; type: string; status: string; title: string | null; description: string | null; lat: number | null; lon: number | null; createdAt: string };
const active = new Set(["open", "acknowledged", "in_progress", "escalated"]);

export default function IncidentsPage() {
  const [rows, setRows] = useState<Incident[]>([]);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState<string | null>(null);
  const load = () => getIncidents().then((r) => setRows(r.data)).catch(() => toast.error("Incidents indisponibles")).finally(() => setLoading(false));
  useEffect(() => { void load(); const id = setInterval(load, 30_000); return () => clearInterval(id); }, []);
  async function transition(row: Incident, status: string) { setBusy(row.id); try { await updateIncident(row.id, status); toast.success("Incident mis à jour"); await load(); } catch { toast.error("Transition impossible"); } finally { setBusy(null); } }
  const open = rows.filter((r) => active.has(r.status));
  return <div className="space-y-6">
    <header className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between"><div><div className="mb-2 flex items-center gap-2 text-xs font-bold uppercase tracking-[.18em] text-destructive"><ShieldAlert className="h-4 w-4"/> Centre de réponse</div><h1 className="text-3xl font-bold tracking-tight">Incidents sécurité</h1><p className="mt-1 text-sm text-muted-foreground">SOS, vols et mouvements critiques, de l’ouverture à la résolution.</p></div><div className="rounded-2xl border bg-card px-5 py-3"><span className="text-xs text-muted-foreground">À traiter</span><strong className="ml-3 text-2xl text-destructive">{open.length}</strong></div></header>
    {loading ? <div className="rounded-2xl border bg-card p-12 text-center text-muted-foreground">Chargement de la file…</div> : <div className="grid gap-4">{rows.map((row) => <article key={row.id} className={`rounded-2xl border bg-card p-5 shadow-sm ${row.status === "escalated" ? "border-destructive/50" : ""}`}><div className="flex flex-col gap-4 lg:flex-row lg:items-center"><div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-destructive/10 text-destructive"><ShieldAlert className="h-6 w-6"/></div><div className="min-w-0 flex-1"><div className="flex flex-wrap items-center gap-2"><h2 className="font-bold">{row.title || row.type}</h2><Badge variant={row.status === "escalated" ? "destructive" : active.has(row.status) ? "secondary" : "outline"}>{row.status}</Badge></div><p className="mt-1 text-sm text-muted-foreground">{row.description} · véhicule #{row.deviceId} · client #{row.ownerId}</p><div className="mt-2 flex flex-wrap gap-4 text-xs text-muted-foreground"><span className="flex items-center gap-1"><Clock3 className="h-3.5 w-3.5"/>{new Date(row.createdAt).toLocaleString("fr-FR")}</span>{row.lat != null && <span className="flex items-center gap-1"><MapPin className="h-3.5 w-3.5"/>{row.lat.toFixed(4)}, {row.lon?.toFixed(4)}</span>}</div></div>{active.has(row.status) && <div className="flex flex-wrap gap-2"><Button variant="outline" disabled={busy === row.id} onClick={() => transition(row, row.status === "open" ? "acknowledged" : "in_progress")}>{row.status === "open" ? "Accuser réception" : "Prendre en charge"}</Button><Button disabled={busy === row.id} onClick={() => transition(row, "resolved")} className="gap-2"><CheckCircle2 className="h-4 w-4"/>Résoudre</Button></div>}</div></article>)}{rows.length === 0 && <div className="rounded-2xl border border-dashed bg-card p-14 text-center"><CheckCircle2 className="mx-auto h-10 w-10 text-emerald-600"/><h2 className="mt-3 font-bold">Aucun incident</h2><p className="text-sm text-muted-foreground">La file opérationnelle est vide.</p></div>}</div>}
  </div>;
}
