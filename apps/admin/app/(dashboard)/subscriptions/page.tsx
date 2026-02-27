"use client";

import { useEffect, useState, useCallback } from "react";
import {
  CreditCard,
  RefreshCw,
  Edit2,
  CheckCircle,
  XCircle,
  Clock,
  Ban,
} from "lucide-react";
import { getSubscriptions, upsertSubscription } from "@/lib/api";
import { Button } from "@/components/ui/button";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet";
import { cn } from "@/lib/utils";
import { toast } from "sonner";

// ── Types ─────────────────────────────────────────────────────────────────────

type Plan = "free" | "basic" | "premium";
type Status = "trial" | "active" | "suspended" | "cancelled";

interface Subscription {
  id: string;
  userId: number;
  plan: Plan;
  status: Status;
  vehicleLimit: number;
  nextBillingDate: string | null;
  trialEndsAt: string | null;
  notes: string | null;
  createdAt: string;
  updatedAt: string;
}

interface SubscriptionRow {
  userId: number;
  name: string | null;
  email: string;
  phone: string | null;
  isActive: boolean;
  subscription: Subscription | null;
}

// ── Config ────────────────────────────────────────────────────────────────────

const PLAN_LABELS: Record<Plan, string> = {
  free: "Free",
  basic: "Basic",
  premium: "Premium",
};

const PLAN_COLORS: Record<Plan, string> = {
  free: "bg-slate-100 text-slate-600",
  basic: "bg-blue-100 text-blue-700",
  premium: "bg-violet-100 text-violet-700",
};

const STATUS_CONFIG: Record<
  Status,
  { label: string; color: string; icon: React.ComponentType<{ className?: string }> }
> = {
  trial: {
    label: "Trial",
    color: "bg-amber-100 text-amber-700",
    icon: Clock,
  },
  active: {
    label: "Active",
    color: "bg-emerald-100 text-emerald-700",
    icon: CheckCircle,
  },
  suspended: {
    label: "Suspended",
    color: "bg-rose-100 text-rose-700",
    icon: XCircle,
  },
  cancelled: {
    label: "Cancelled",
    color: "bg-slate-100 text-slate-500",
    icon: Ban,
  },
};

const VEHICLE_LIMITS: Record<Plan, number> = {
  free: 1,
  basic: 5,
  premium: 999,
};

// ── Edit Sheet ────────────────────────────────────────────────────────────────

function EditSheet({
  row,
  open,
  onClose,
  onSaved,
}: {
  row: SubscriptionRow;
  open: boolean;
  onClose: () => void;
  onSaved: () => void;
}) {
  const sub = row.subscription;
  const [plan, setPlan] = useState<Plan>(sub?.plan ?? "free");
  const [status, setStatus] = useState<Status>(sub?.status ?? "trial");
  const [nextBillingDate, setNextBillingDate] = useState(
    sub?.nextBillingDate
      ? new Date(sub.nextBillingDate).toISOString().slice(0, 10)
      : ""
  );
  const [trialEndsAt, setTrialEndsAt] = useState(
    sub?.trialEndsAt
      ? new Date(sub.trialEndsAt).toISOString().slice(0, 10)
      : ""
  );
  const [notes, setNotes] = useState(sub?.notes ?? "");
  const [saving, setSaving] = useState(false);

  async function handleSave() {
    setSaving(true);
    try {
      await upsertSubscription(row.userId, {
        plan,
        status,
        nextBillingDate: nextBillingDate || null,
        trialEndsAt: trialEndsAt || null,
        notes: notes || null,
      });
      toast.success(`Subscription updated for ${row.name ?? row.email}`);
      onSaved();
      onClose();
    } catch {
      toast.error("Failed to update subscription");
    } finally {
      setSaving(false);
    }
  }

  return (
    <Sheet open={open} onOpenChange={(v) => !v && onClose()}>
      <SheetContent className="w-[400px] sm:w-[480px] overflow-y-auto">
        <SheetHeader>
          <SheetTitle>Edit Subscription</SheetTitle>
        </SheetHeader>
        <div className="mt-1 mb-4">
          <p className="font-medium">{row.name ?? row.email}</p>
          <p className="text-sm text-muted-foreground">{row.email}</p>
        </div>

        <div className="space-y-5">
          {/* Plan */}
          <div>
            <label className="text-sm font-medium block mb-1.5">Plan</label>
            <div className="flex gap-2">
              {(["free", "basic", "premium"] as Plan[]).map((p) => (
                <button
                  key={p}
                  onClick={() => setPlan(p)}
                  className={cn(
                    "flex-1 rounded-md border py-2 text-sm font-medium capitalize transition-colors",
                    plan === p
                      ? "bg-primary text-primary-foreground border-primary"
                      : "text-muted-foreground hover:bg-muted"
                  )}
                >
                  {p}
                  <div className="text-xs font-normal mt-0.5 opacity-70">
                    {VEHICLE_LIMITS[p] === 999
                      ? "Unlimited"
                      : `${VEHICLE_LIMITS[p]} vehicle${VEHICLE_LIMITS[p] > 1 ? "s" : ""}`}
                  </div>
                </button>
              ))}
            </div>
          </div>

          {/* Status */}
          <div>
            <label className="text-sm font-medium block mb-1.5">Status</label>
            <div className="grid grid-cols-2 gap-2">
              {(["trial", "active", "suspended", "cancelled"] as Status[]).map(
                (s) => {
                  const cfg = STATUS_CONFIG[s];
                  return (
                    <button
                      key={s}
                      onClick={() => setStatus(s)}
                      className={cn(
                        "flex items-center gap-2 rounded-md border px-3 py-2 text-sm transition-colors",
                        status === s
                          ? "bg-primary text-primary-foreground border-primary"
                          : "text-muted-foreground hover:bg-muted"
                      )}
                    >
                      <cfg.icon className="h-3.5 w-3.5" />
                      {cfg.label}
                    </button>
                  );
                }
              )}
            </div>
          </div>

          {/* Trial ends at */}
          <div>
            <label className="text-sm font-medium block mb-1.5">
              Trial Ends At
            </label>
            <input
              type="date"
              value={trialEndsAt}
              onChange={(e) => setTrialEndsAt(e.target.value)}
              className="w-full rounded-md border bg-background px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-ring"
            />
          </div>

          {/* Next billing date */}
          <div>
            <label className="text-sm font-medium block mb-1.5">
              Next Billing Date
            </label>
            <input
              type="date"
              value={nextBillingDate}
              onChange={(e) => setNextBillingDate(e.target.value)}
              className="w-full rounded-md border bg-background px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-ring"
            />
          </div>

          {/* Notes */}
          <div>
            <label className="text-sm font-medium block mb-1.5">
              Internal Notes
            </label>
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              rows={3}
              placeholder="e.g. Customer pays via mobile money, follow-up needed…"
              className="w-full rounded-md border bg-background px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-ring resize-none"
            />
          </div>

          <Button onClick={handleSave} disabled={saving} className="w-full">
            {saving ? "Saving…" : "Save Changes"}
          </Button>
        </div>
      </SheetContent>
    </Sheet>
  );
}

// ── Summary cards ─────────────────────────────────────────────────────────────

function SummaryCard({
  label,
  value,
  color,
}: {
  label: string;
  value: number;
  color: string;
}) {
  return (
    <div className="rounded-lg border bg-card p-4">
      <p className="text-2xl font-bold">{value}</p>
      <p className={cn("text-sm mt-0.5 font-medium", color)}>{label}</p>
    </div>
  );
}

// ── Page ──────────────────────────────────────────────────────────────────────

export default function SubscriptionsPage() {
  const [rows, setRows] = useState<SubscriptionRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [editing, setEditing] = useState<SubscriptionRow | null>(null);
  const [filter, setFilter] = useState<"all" | Plan | Status>("all");

  const load = useCallback(async (quiet = false) => {
    if (!quiet) setLoading(true);
    else setRefreshing(true);
    try {
      const res = await getSubscriptions();
      setRows(res.data as SubscriptionRow[]);
    } catch {
      // silently fail
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  // Summary counts
  const counts = {
    total: rows.length,
    active: rows.filter((r) => r.subscription?.status === "active").length,
    trial: rows.filter((r) => r.subscription?.status === "trial").length,
    suspended: rows.filter((r) => r.subscription?.status === "suspended").length,
    free: rows.filter((r) => (r.subscription?.plan ?? "free") === "free").length,
    basic: rows.filter((r) => r.subscription?.plan === "basic").length,
    premium: rows.filter((r) => r.subscription?.plan === "premium").length,
    none: rows.filter((r) => !r.subscription).length,
  };

  const FILTER_TABS = [
    { key: "all", label: `All (${counts.total})` },
    { key: "active", label: `Active (${counts.active})` },
    { key: "trial", label: `Trial (${counts.trial})` },
    { key: "suspended", label: `Suspended (${counts.suspended})` },
    { key: "free", label: `Free (${counts.free})` },
    { key: "basic", label: `Basic (${counts.basic})` },
    { key: "premium", label: `Premium (${counts.premium})` },
  ] as const;

  const filtered =
    filter === "all"
      ? rows
      : rows.filter((r) => {
          const sub = r.subscription;
          if (!sub) return filter === "free"; // no subscription → treated as free
          if (
            filter === "active" ||
            filter === "trial" ||
            filter === "suspended" ||
            filter === "cancelled"
          )
            return sub.status === filter;
          return sub.plan === filter;
        });

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64 text-muted-foreground">
        Loading subscriptions…
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">Subscriptions</h1>
          <p className="text-muted-foreground text-sm mt-0.5">
            Manage user plans, trial periods and billing status
          </p>
        </div>
        <Button
          variant="outline"
          size="sm"
          onClick={() => load(true)}
          disabled={refreshing}
        >
          <RefreshCw
            className={cn("h-4 w-4 mr-2", refreshing && "animate-spin")}
          />
          Refresh
        </Button>
      </div>

      {/* Summary cards */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        <SummaryCard
          label="Active"
          value={counts.active}
          color="text-emerald-600"
        />
        <SummaryCard
          label="On Trial"
          value={counts.trial}
          color="text-amber-600"
        />
        <SummaryCard
          label="Suspended"
          value={counts.suspended}
          color="text-rose-600"
        />
        <SummaryCard
          label="Premium Plan"
          value={counts.premium}
          color="text-violet-600"
        />
      </div>

      {/* Filter tabs */}
      <div className="flex flex-wrap gap-1.5">
        {FILTER_TABS.map(({ key, label }) => (
          <button
            key={key}
            onClick={() => setFilter(key as typeof filter)}
            className={cn(
              "text-sm px-3 py-1.5 rounded-md transition-colors",
              filter === key
                ? "bg-primary text-primary-foreground"
                : "text-muted-foreground hover:bg-muted"
            )}
          >
            {label}
          </button>
        ))}
      </div>

      {/* Table */}
      <div className="rounded-lg border bg-card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b bg-muted/30">
                <th className="px-4 py-2.5 text-left font-medium text-muted-foreground">
                  User
                </th>
                <th className="px-4 py-2.5 text-left font-medium text-muted-foreground">
                  Plan
                </th>
                <th className="px-4 py-2.5 text-left font-medium text-muted-foreground">
                  Status
                </th>
                <th className="px-4 py-2.5 text-left font-medium text-muted-foreground">
                  Vehicle Limit
                </th>
                <th className="px-4 py-2.5 text-left font-medium text-muted-foreground">
                  Trial Ends
                </th>
                <th className="px-4 py-2.5 text-left font-medium text-muted-foreground">
                  Next Billing
                </th>
                <th className="px-4 py-2.5 text-left font-medium text-muted-foreground">
                  Notes
                </th>
                <th className="px-4 py-2.5 text-right font-medium text-muted-foreground">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 ? (
                <tr>
                  <td
                    colSpan={8}
                    className="px-4 py-10 text-center text-muted-foreground"
                  >
                    No subscriptions found.
                  </td>
                </tr>
              ) : (
                filtered.map((row) => {
                  const sub = row.subscription;
                  const plan: Plan = sub?.plan ?? "free";
                  const status: Status = sub?.status ?? "trial";
                  const statusCfg = STATUS_CONFIG[status];

                  return (
                    <tr
                      key={row.userId}
                      className="border-b last:border-0 hover:bg-muted/30"
                    >
                      {/* User */}
                      <td className="px-4 py-3">
                        <div className="font-medium">
                          {row.name ?? row.email}
                        </div>
                        {row.name && (
                          <div className="text-xs text-muted-foreground">
                            {row.email}
                          </div>
                        )}
                        {!row.isActive && (
                          <span className="text-xs text-rose-500">
                            (deactivated)
                          </span>
                        )}
                      </td>

                      {/* Plan badge */}
                      <td className="px-4 py-3">
                        <span
                          className={cn(
                            "inline-block text-xs font-semibold px-2 py-0.5 rounded-full capitalize",
                            PLAN_COLORS[plan]
                          )}
                        >
                          {PLAN_LABELS[plan]}
                        </span>
                      </td>

                      {/* Status badge */}
                      <td className="px-4 py-3">
                        <span
                          className={cn(
                            "inline-flex items-center gap-1 text-xs font-medium px-2 py-0.5 rounded-full",
                            statusCfg.color
                          )}
                        >
                          <statusCfg.icon className="h-3 w-3" />
                          {statusCfg.label}
                        </span>
                      </td>

                      {/* Vehicle limit */}
                      <td className="px-4 py-3 text-muted-foreground font-mono">
                        {sub
                          ? sub.vehicleLimit >= 999
                            ? "∞"
                            : sub.vehicleLimit
                          : VEHICLE_LIMITS[plan]}
                      </td>

                      {/* Trial ends at */}
                      <td className="px-4 py-3 text-muted-foreground tabular-nums">
                        {sub?.trialEndsAt ? (
                          <span
                            className={cn(
                              new Date(sub.trialEndsAt) < new Date() &&
                                "text-rose-500"
                            )}
                          >
                            {new Date(sub.trialEndsAt).toLocaleDateString(
                              "en-US",
                              { month: "short", day: "numeric", year: "numeric" }
                            )}
                          </span>
                        ) : (
                          <span className="text-muted-foreground/50">—</span>
                        )}
                      </td>

                      {/* Next billing date */}
                      <td className="px-4 py-3 text-muted-foreground tabular-nums">
                        {sub?.nextBillingDate ? (
                          new Date(sub.nextBillingDate).toLocaleDateString(
                            "en-US",
                            { month: "short", day: "numeric", year: "numeric" }
                          )
                        ) : (
                          <span className="text-muted-foreground/50">—</span>
                        )}
                      </td>

                      {/* Notes */}
                      <td className="px-4 py-3 max-w-[180px]">
                        {sub?.notes ? (
                          <span
                            className="text-xs text-muted-foreground truncate block"
                            title={sub.notes}
                          >
                            {sub.notes}
                          </span>
                        ) : (
                          <span className="text-muted-foreground/50 text-xs">
                            —
                          </span>
                        )}
                      </td>

                      {/* Edit action */}
                      <td className="px-4 py-3 text-right">
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => setEditing(row)}
                        >
                          <Edit2 className="h-3.5 w-3.5 mr-1.5" />
                          Edit
                        </Button>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Edit sheet */}
      {editing && (
        <EditSheet
          row={editing}
          open={!!editing}
          onClose={() => setEditing(null)}
          onSaved={() => load(true)}
        />
      )}
    </div>
  );
}
