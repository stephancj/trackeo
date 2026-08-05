"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { Check, Layers3, Plus, Save, Sparkles } from "lucide-react";
import { toast } from "sonner";
import {
  CommercialPlan,
  createPlan,
  FeatureDefinition,
  getFeatures,
  getPlans,
  replacePlanFeatures,
  updatePlan,
} from "@/lib/api";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

type GrantState = Record<string, { enabled: boolean; value: boolean | number | string | null }>;
type PlanForm = { code: string; name: string; description: string; priceMonthly: number; currency: string; displayOrder: number };
const emptyPlan: PlanForm = { code: "", name: "", description: "", priceMonthly: 0, currency: "MGA", displayOrder: 40 };

export default function PlansPage() {
  const [plans, setPlans] = useState<CommercialPlan[]>([]);
  const [features, setFeatures] = useState<FeatureDefinition[]>([]);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [grants, setGrants] = useState<GrantState>({});
  const [loading, setLoading] = useState(true);
  const [savingRights, setSavingRights] = useState(false);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editing, setEditing] = useState<CommercialPlan | null>(null);
  const [form, setForm] = useState<PlanForm>(emptyPlan);

  const load = useCallback(async (keepSelection?: string | null) => {
    setLoading(true);
    try {
      const [planResponse, featureResponse] = await Promise.all([getPlans(), getFeatures()]);
      setPlans(planResponse.data);
      setFeatures(featureResponse.data.filter((feature) => feature.isActive));
      setSelectedId((current) => keepSelection ?? current ?? planResponse.data[0]?.id ?? null);
    } catch {
      toast.error("Impossible de charger les plans.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { void load(); }, [load]);
  const selected = plans.find((plan) => plan.id === selectedId) ?? null;

  useEffect(() => {
    if (!selected) return;
    const next: GrantState = {};
    for (const feature of features) {
      const existing = selected.planFeatures.find((grant) => grant.featureId === feature.id);
      next[feature.id] = {
        enabled: existing?.enabled ?? false,
        value: existing?.value ?? (feature.valueType === "number" ? 0 : true),
      };
    }
    setGrants(next);
  }, [selected, features]);

  const grouped = useMemo(() => {
    const map = new Map<string, FeatureDefinition[]>();
    for (const feature of features) map.set(feature.category, [...(map.get(feature.category) ?? []), feature]);
    return Array.from(map.entries());
  }, [features]);

  function showCreate() {
    setEditing(null); setForm(emptyPlan); setDialogOpen(true);
  }
  function showEdit(plan: CommercialPlan) {
    setEditing(plan);
    setForm({ code: plan.code, name: plan.name, description: plan.description ?? "", priceMonthly: Number(plan.priceMonthly), currency: plan.currency, displayOrder: plan.displayOrder });
    setDialogOpen(true);
  }

  async function savePlan() {
    try {
      if (editing) await updatePlan(editing.id, form);
      else await createPlan(form);
      toast.success(editing ? "Plan mis à jour" : "Plan créé");
      setDialogOpen(false);
      await load(editing?.id ?? null);
    } catch {
      toast.error("Le plan n’a pas pu être enregistré.");
    }
  }

  async function saveRights() {
    if (!selected) return;
    setSavingRights(true);
    try {
      await replacePlanFeatures(selected.id, features.map((feature) => ({
        featureId: feature.id,
        enabled: grants[feature.id]?.enabled ?? false,
        value: grants[feature.id]?.value ?? null,
      })));
      toast.success(`Droits du plan ${selected.name} enregistrés`);
      await load(selected.id);
    } catch {
      toast.error("Les droits n’ont pas pu être enregistrés.");
    } finally {
      setSavingRights(false);
    }
  }

  return (
    <div className="space-y-6">
      <header className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
        <div>
          <div className="mb-2 flex items-center gap-2 text-xs font-semibold uppercase tracking-[0.18em] text-trackeo-primary"><Layers3 className="h-4 w-4" /> Architecture tarifaire</div>
          <h1 className="text-3xl font-bold tracking-tight text-trackeo-dark">Plans & droits</h1>
          <p className="mt-1 text-sm text-muted-foreground">Composez chaque offre à partir du catalogue, sans redéployer l’application.</p>
        </div>
        <Button onClick={showCreate} className="gap-2"><Plus className="h-4 w-4" /> Nouveau plan</Button>
      </header>

      {loading ? <div className="rounded-2xl border bg-card p-12 text-center text-muted-foreground">Chargement des plans…</div> : (
        <>
          <div className="grid gap-3 lg:grid-cols-3">
            {plans.map((plan) => {
              const active = plan.id === selectedId;
              return <button key={plan.id} onClick={() => setSelectedId(plan.id)} className={`relative overflow-hidden rounded-2xl border p-5 text-left transition-all ${active ? "border-trackeo-primary bg-trackeo-pastel-green shadow-sm" : "bg-card hover:-translate-y-0.5 hover:shadow-sm"}`}>
                {active && <div className="absolute right-0 top-0 rounded-bl-xl bg-trackeo-primary px-3 py-1 text-[10px] font-bold uppercase tracking-wider text-trackeo-dark">Sélectionné</div>}
                <div className="flex items-center gap-2"><h2 className="text-xl font-bold text-trackeo-dark">{plan.name}</h2>{!plan.isActive && <Badge variant="secondary">Inactif</Badge>}</div>
                <p className="mt-2 min-h-10 text-sm text-muted-foreground">{plan.description}</p>
                <div className="mt-5 flex items-end justify-between"><div><strong className="text-2xl text-trackeo-dark">{Number(plan.priceMonthly).toLocaleString("fr-FR")}</strong><span className="ml-1 text-xs text-muted-foreground">{plan.currency}/mois</span></div><span className="text-xs font-medium text-muted-foreground">{plan.planFeatures.filter((grant) => grant.enabled).length} droits</span></div>
                <Button variant="ghost" size="sm" className="mt-3 -ml-3" onClick={(event) => { event.stopPropagation(); showEdit(plan); }}>Modifier le plan</Button>
              </button>;
            })}
          </div>

          {selected && <section className="overflow-hidden rounded-2xl border bg-card shadow-sm">
            <div className="flex flex-col gap-3 border-b bg-trackeo-dark px-5 py-4 text-white md:flex-row md:items-center md:justify-between">
              <div><div className="flex items-center gap-2"><Sparkles className="h-4 w-4 text-trackeo-primary" /><h2 className="font-semibold">Matrice de droits · {selected.name}</h2></div><p className="mt-1 text-xs text-white/60">Les modifications sont appliquées à tous les abonnés de ce plan.</p></div>
              <Button onClick={saveRights} disabled={savingRights} className="gap-2"><Save className="h-4 w-4" /> {savingRights ? "Enregistrement…" : "Enregistrer les droits"}</Button>
            </div>
            <div className="divide-y">
              {grouped.map(([category, items]) => <div key={category} className="grid md:grid-cols-[190px_1fr]"><div className="bg-muted/35 p-5 text-xs font-bold uppercase tracking-[0.14em] text-muted-foreground">{category}</div><div className="divide-y">{items.map((feature) => {
                const grant = grants[feature.id] ?? { enabled: false, value: null };
                return <div key={feature.id} className="grid gap-3 p-4 sm:grid-cols-[1fr_130px] sm:items-center">
                  <button onClick={() => setGrants({ ...grants, [feature.id]: { ...grant, enabled: !grant.enabled } })} className="flex items-start gap-3 text-left">
                    <span className={`mt-0.5 flex h-6 w-6 shrink-0 items-center justify-center rounded-md border ${grant.enabled ? "border-trackeo-primary bg-trackeo-primary text-trackeo-dark" : "bg-background text-transparent"}`}><Check className="h-4 w-4" /></span>
                    <span><span className="block text-sm font-semibold">{feature.name}</span><span className="mt-0.5 block text-xs text-muted-foreground">{feature.description}</span></span>
                  </button>
                  {feature.valueType === "number" ? <div className="relative"><Input type="number" min={0} disabled={!grant.enabled} value={Number(grant.value ?? 0)} onChange={(event) => setGrants({ ...grants, [feature.id]: { ...grant, value: Number(event.target.value) } })} className="pr-16" /><span className="pointer-events-none absolute right-3 top-2.5 text-xs text-muted-foreground">{feature.unit}</span></div> : <Badge variant={grant.enabled ? "default" : "outline"} className="w-fit sm:ml-auto">{grant.enabled ? "Inclus" : "Exclu"}</Badge>}
                </div>;
              })}</div></div>)}
            </div>
          </section>}
        </>
      )}

      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}><DialogContent className="sm:max-w-xl"><DialogHeader><DialogTitle>{editing ? "Modifier le plan" : "Créer un plan"}</DialogTitle></DialogHeader><div className="grid gap-4 py-2 sm:grid-cols-2">
        <Field label="Nom"><Input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} /></Field>
        <Field label="Code immuable"><Input disabled={!!editing} value={form.code} onChange={(e) => setForm({ ...form, code: e.target.value })} placeholder="ex. business" /></Field>
        <Field label="Prix mensuel"><Input type="number" min={0} value={form.priceMonthly} onChange={(e) => setForm({ ...form, priceMonthly: Number(e.target.value) })} /></Field>
        <Field label="Devise"><Input maxLength={3} value={form.currency} onChange={(e) => setForm({ ...form, currency: e.target.value.toUpperCase() })} /></Field>
        <Field label="Ordre"><Input type="number" value={form.displayOrder} onChange={(e) => setForm({ ...form, displayOrder: Number(e.target.value) })} /></Field>
        <div className="sm:col-span-2"><Field label="Description"><textarea className="min-h-24 w-full rounded-md border bg-background p-3 text-sm" value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} /></Field></div>
      </div><DialogFooter><Button variant="outline" onClick={() => setDialogOpen(false)}>Annuler</Button><Button onClick={savePlan}>Enregistrer</Button></DialogFooter></DialogContent></Dialog>
    </div>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) { return <div className="space-y-1.5"><Label>{label}</Label>{children}</div>; }
