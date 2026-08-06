"use client";

import { useEffect, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { getPayments } from "@/lib/api";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  CreditCard,
  Search,
  CheckCircle2,
  Clock,
  XCircle,
  TrendingUp,
  RefreshCw,
  ExternalLink,
  Info,
} from "lucide-react";

interface AdminPayment {
  id: string;
  userId: number;
  userName: string;
  userEmail: string;
  planId: string;
  planName: string;
  planCode: string;
  reference: string;
  amount: number;
  currency: string;
  status: "created" | "pending" | "success" | "failed" | "expired";
  provider: string | null;
  paymentMethod: string | null;
  paymentLink: string | null;
  papiMerchantReference: string | null;
  papiPaymentReference: string | null;
  failureMessage: string | null;
  paidAt: string | null;
  expiresAt: string | null;
  createdAt: string;
}

export default function PaymentsAdminPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const pageParam = parseInt(searchParams.get("page") || "1", 10);

  const [payments, setPayments] = useState<AdminPayment[]>([]);
  const [meta, setMeta] = useState({ page: 1, totalPages: 1, total: 0 });
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<"all" | "success" | "pending" | "failed">("all");
  const [search, setSearch] = useState("");
  const [selectedPayment, setSelectedPayment] = useState<AdminPayment | null>(null);

  function loadData(p = pageParam) {
    setLoading(true);
    getPayments(p)
      .then((res) => {
        setPayments(res.data.data as AdminPayment[] || []);
        setMeta(res.data.meta || { page: 1, totalPages: 1, total: 0 });
      })
      .catch(() => {})
      .finally(() => setLoading(false));
  }

  useEffect(() => {
    loadData(pageParam);
  }, [pageParam]);

  const totalRevenue = payments
    .filter((p) => p.status === "success")
    .reduce((sum, p) => sum + (Number(p.amount) || 0), 0);

  const successCount = payments.filter((p) => p.status === "success").length;
  const pendingCount = payments.filter((p) => p.status === "pending" || p.status === "created").length;
  const failedCount = payments.filter((p) => p.status === "failed" || p.status === "expired").length;

  const filteredPayments = payments.filter((p) => {
    if (filter === "success" && p.status !== "success") return false;
    if (filter === "pending" && p.status !== "pending" && p.status !== "created") return false;
    if (filter === "failed" && p.status !== "failed" && p.status !== "expired") return false;

    if (search.trim()) {
      const q = search.toLowerCase();
      const matchEmail = p.userEmail.toLowerCase().includes(q);
      const matchName = p.userName.toLowerCase().includes(q);
      const matchRef = p.reference.toLowerCase().includes(q);
      const matchPapiRef = (p.papiPaymentReference || "").toLowerCase().includes(q);
      if (!matchEmail && !matchName && !matchRef && !matchPapiRef) return false;
    }

    return true;
  });

  function formatAmount(amount: number) {
    return new Intl.NumberFormat("fr-FR").format(amount);
  }

  function formatDate(dateStr: string | null) {
    if (!dateStr) return "—";
    const date = new Date(dateStr);
    return new Intl.DateTimeFormat("fr-FR", {
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    }).format(date);
  }

  return (
    <div className="space-y-6 p-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-foreground flex items-center gap-2">
            <CreditCard className="h-6 w-6 text-trackeo-primary" />
            Paiements & Caisse
          </h1>
          <p className="text-sm text-muted-foreground">
            Historique des transactions PAPI.mg, abonnements réglés et tentatives de paiement.
          </p>
        </div>
        <Button onClick={() => loadData()} variant="outline" size="sm" className="gap-2">
          <RefreshCw className={`h-4 w-4 ${loading ? "animate-spin" : ""}`} />
          Actualiser
        </Button>
      </div>

      {/* Metric Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="rounded-xl border border-border bg-card p-4 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
              Total Encaissements
            </span>
            <TrendingUp className="h-4 w-4 text-emerald-500" />
          </div>
          <div className="mt-2 text-2xl font-extrabold text-foreground">
            {formatAmount(totalRevenue)} <span className="text-xs font-semibold text-muted-foreground">MGA</span>
          </div>
          <p className="mt-1 text-[11px] text-muted-foreground">Chiffre d’affaires encaissé</p>
        </div>

        <div className="rounded-xl border border-border bg-card p-4 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
              Paiements Réussis
            </span>
            <CheckCircle2 className="h-4 w-4 text-emerald-500" />
          </div>
          <div className="mt-2 text-2xl font-extrabold text-emerald-600 dark:text-emerald-400">
            {successCount}
          </div>
          <p className="mt-1 text-[11px] text-muted-foreground">Transactions confirmées</p>
        </div>

        <div className="rounded-xl border border-border bg-card p-4 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
              En Attente
            </span>
            <Clock className="h-4 w-4 text-amber-500" />
          </div>
          <div className="mt-2 text-2xl font-extrabold text-amber-600 dark:text-amber-400">
            {pendingCount}
          </div>
          <p className="mt-1 text-[11px] text-muted-foreground">Liens de paiement ouverts</p>
        </div>

        <div className="rounded-xl border border-border bg-card p-4 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
              Échecs / Expirés
            </span>
            <XCircle className="h-4 w-4 text-rose-500" />
          </div>
          <div className="mt-2 text-2xl font-extrabold text-rose-600 dark:text-rose-400">
            {failedCount}
          </div>
          <p className="mt-1 text-[11px] text-muted-foreground">Tentatives non abouties</p>
        </div>
      </div>

      {/* Filters & Search */}
      <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-4">
        <div className="flex items-center gap-1 bg-muted p-1 rounded-lg border border-border">
          <button
            onClick={() => setFilter("all")}
            className={`px-3 py-1.5 text-xs font-semibold rounded-md transition-all ${
              filter === "all" ? "bg-background text-foreground shadow-sm" : "text-muted-foreground hover:text-foreground"
            }`}
          >
            Tous ({meta.total})
          </button>
          <button
            onClick={() => setFilter("success")}
            className={`px-3 py-1.5 text-xs font-semibold rounded-md transition-all ${
              filter === "success" ? "bg-background text-emerald-600 dark:text-emerald-400 shadow-sm" : "text-muted-foreground hover:text-foreground"
            }`}
          >
            Réussis ({successCount})
          </button>
          <button
            onClick={() => setFilter("pending")}
            className={`px-3 py-1.5 text-xs font-semibold rounded-md transition-all ${
              filter === "pending" ? "bg-background text-amber-600 dark:text-amber-400 shadow-sm" : "text-muted-foreground hover:text-foreground"
            }`}
          >
            En attente ({pendingCount})
          </button>
          <button
            onClick={() => setFilter("failed")}
            className={`px-3 py-1.5 text-xs font-semibold rounded-md transition-all ${
              filter === "failed" ? "bg-background text-rose-600 dark:text-rose-400 shadow-sm" : "text-muted-foreground hover:text-foreground"
            }`}
          >
            Échoués ({failedCount})
          </button>
        </div>

        <div className="relative w-full sm:w-72">
          <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
          <Input
            placeholder="Rechercher un client, réf..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="pl-9 text-xs"
          />
        </div>
      </div>

      {/* Table */}
      <div className="rounded-xl border border-border bg-card shadow-sm overflow-hidden">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Client</TableHead>
              <TableHead>Référence Marchand</TableHead>
              <TableHead>Plan</TableHead>
              <TableHead>Montant</TableHead>
              <TableHead>Moyen</TableHead>
              <TableHead>Statut</TableHead>
              <TableHead>Date</TableHead>
              <TableHead className="text-right">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {loading ? (
              <TableRow>
                <TableCell colSpan={8} className="text-center py-8 text-muted-foreground text-sm">
                  Chargement des transactions...
                </TableCell>
              </TableRow>
            ) : filteredPayments.length === 0 ? (
              <TableRow>
                <TableCell colSpan={8} className="text-center py-8 text-muted-foreground text-sm">
                  Aucun paiement trouvé pour ce filtre.
                </TableCell>
              </TableRow>
            ) : (
              filteredPayments.map((p) => (
                <TableRow key={p.id} className="hover:bg-muted/50 transition-colors">
                  <TableCell>
                    <div className="flex flex-col">
                      <span className="font-semibold text-foreground text-xs">{p.userName}</span>
                      <span className="text-[11px] text-muted-foreground">{p.userEmail}</span>
                    </div>
                  </TableCell>
                  <TableCell>
                    <span className="font-mono text-xs text-foreground bg-muted px-2 py-1 rounded border border-border">
                      {p.reference}
                    </span>
                  </TableCell>
                  <TableCell>
                    <Badge variant="outline" className="text-xs font-semibold">
                      {p.planName || "Plan"}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    <span className="font-bold text-foreground text-xs">
                      {formatAmount(p.amount)} {p.currency}
                    </span>
                  </TableCell>
                  <TableCell>
                    <span className="text-xs text-muted-foreground">
                      {p.paymentMethod || p.provider || "PAPI"}
                    </span>
                  </TableCell>
                  <TableCell>
                    {p.status === "success" && (
                      <Badge className="bg-emerald-500/15 text-emerald-700 dark:text-emerald-300 hover:bg-emerald-500/20 border-emerald-500/30 gap-1 text-[11px]">
                        <CheckCircle2 className="h-3 w-3" /> Payé
                      </Badge>
                    )}
                    {(p.status === "pending" || p.status === "created") && (
                      <Badge className="bg-amber-500/15 text-amber-700 dark:text-amber-300 hover:bg-amber-500/20 border-amber-500/30 gap-1 text-[11px]">
                        <Clock className="h-3 w-3" /> En attente
                      </Badge>
                    )}
                    {(p.status === "failed" || p.status === "expired") && (
                      <Badge className="bg-rose-500/15 text-rose-700 dark:text-rose-300 hover:bg-rose-500/20 border-rose-500/30 gap-1 text-[11px]">
                        <XCircle className="h-3 w-3" /> Échoué
                      </Badge>
                    )}
                  </TableCell>
                  <TableCell className="text-xs text-muted-foreground">
                    {formatDate(p.paidAt || p.createdAt)}
                  </TableCell>
                  <TableCell className="text-right">
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => setSelectedPayment(p)}
                      className="h-8 px-2 text-xs gap-1"
                    >
                      <Info className="h-3.5 w-3.5" />
                      Détails
                    </Button>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </div>

      <div className="mt-4 flex items-center justify-between">
        <p className="text-sm text-muted-foreground">
          Affichage de {payments.length} sur {meta.total} paiements
        </p>
        <div className="flex gap-2">
          <Button
            variant="outline"
            size="sm"
            disabled={meta.page <= 1}
            onClick={() => router.push(`/payments?page=${meta.page - 1}`)}
          >
            Précédent
          </Button>
          <Button
            variant="outline"
            size="sm"
            disabled={meta.page >= meta.totalPages}
            onClick={() => router.push(`/payments?page=${meta.page + 1}`)}
          >
            Suivant
          </Button>
        </div>
      </div>

      {/* Details Dialog */}
      <Dialog open={!!selectedPayment} onOpenChange={() => setSelectedPayment(null)}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2 text-lg font-bold">
              <CreditCard className="h-5 w-5 text-trackeo-primary" />
              Détails du Paiement
            </DialogTitle>
          </DialogHeader>

          {selectedPayment && (
            <div className="space-y-4 text-xs">
              <div className="rounded-lg border border-border p-3 bg-muted/40 space-y-2">
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Client :</span>
                  <span className="font-semibold">{selectedPayment.userName}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Email :</span>
                  <span className="font-mono">{selectedPayment.userEmail}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Plan :</span>
                  <span className="font-semibold">{selectedPayment.planName}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Montant :</span>
                  <span className="font-bold text-foreground">
                    {formatAmount(selectedPayment.amount)} {selectedPayment.currency}
                  </span>
                </div>
              </div>

              <div className="space-y-2">
                <div className="flex justify-between py-1 border-b border-border">
                  <span className="text-muted-foreground">Référence iooeh :</span>
                  <span className="font-mono text-xs">{selectedPayment.reference}</span>
                </div>
                <div className="flex justify-between py-1 border-b border-border">
                  <span className="text-muted-foreground">Référence PAPI :</span>
                  <span className="font-mono text-xs">{selectedPayment.papiPaymentReference || "—"}</span>
                </div>
                <div className="flex justify-between py-1 border-b border-border">
                  <span className="text-muted-foreground">Moyen de paiement :</span>
                  <span>{selectedPayment.paymentMethod || selectedPayment.provider || "PAPI"}</span>
                </div>
                <div className="flex justify-between py-1 border-b border-border">
                  <span className="text-muted-foreground">Créé le :</span>
                  <span>{formatDate(selectedPayment.createdAt)}</span>
                </div>
                <div className="flex justify-between py-1 border-b border-border">
                  <span className="text-muted-foreground">Réglé le :</span>
                  <span>{formatDate(selectedPayment.paidAt)}</span>
                </div>
                {selectedPayment.failureMessage && (
                  <div className="mt-2 rounded p-2 bg-rose-500/10 border border-rose-500/30 text-rose-600 dark:text-rose-400 text-xs">
                    <strong>Erreur PAPI :</strong> {selectedPayment.failureMessage}
                  </div>
                )}
              </div>

              {selectedPayment.paymentLink && (
                <div className="pt-2">
                  <Button
                    asChild
                    variant="outline"
                    className="w-full gap-2 text-xs"
                  >
                    <a href={selectedPayment.paymentLink} target="_blank" rel="noreferrer">
                      Ouvrir la page de paiement PAPI
                      <ExternalLink className="h-3.5 w-3.5" />
                    </a>
                  </Button>
                </div>
              )}
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
