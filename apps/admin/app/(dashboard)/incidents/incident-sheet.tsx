import { useEffect, useState } from "react";
import { getIncidentEvents, updateIncident } from "@/lib/api";
import { relativeTime } from "@/lib/utils";
import { toast } from "sonner";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetDescription,
  SheetFooter,
} from "@/components/ui/sheet";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { Clock, User, ShieldAlert, CheckCheck, XCircle, AlertTriangle } from "lucide-react";

interface IncidentEvent {
  id: string;
  action: string;
  note: string | null;
  actorId: number | null;
  createdAt: string;
}

interface IncidentSheetProps {
  incidentId: string | null;
  onClose: () => void;
}

export function IncidentSheet({ incidentId, onClose }: IncidentSheetProps) {
  const [events, setEvents] = useState<IncidentEvent[]>([]);
  const [loading, setLoading] = useState(false);
  const [updating, setUpdating] = useState(false);
  const [note, setNote] = useState("");

  useEffect(() => {
    if (!incidentId) return;
    setLoading(true);
    setNote("");
    getIncidentEvents(incidentId)
      .then((r) => setEvents(r.data))
      .catch(() => toast.error("Erreur lors du chargement de l'historique"))
      .finally(() => setLoading(false));
  }, [incidentId]);

  async function handleUpdate(status: string) {
    if (!incidentId) return;
    
    // Si c'est une résolution ou fausse alarme, exiger une note si le champ est vide? 
    // Pas strictement obligatoire mais recommandé.
    if ((status === "resolved" || status === "false_alarm") && note.trim().length === 0) {
      toast.error("Veuillez saisir une note explicative pour clôturer l'incident.");
      return;
    }

    setUpdating(true);
    try {
      await updateIncident(incidentId, status, note);
      toast.success(`Statut mis à jour : ${status}`);
      onClose(); // Fermer la sheet après mise à jour
    } catch {
      toast.error("Échec de la mise à jour de l'incident");
    } finally {
      setUpdating(false);
    }
  }

  const isOpen = !!incidentId;

  return (
    <Sheet open={isOpen} onOpenChange={(open) => !open && onClose()}>
      <SheetContent side="right" className="w-[400px] sm:w-[540px] flex flex-col h-full border-l">
        <SheetHeader className="pb-4 border-b">
          <SheetTitle className="flex items-center gap-2">
            <ShieldAlert className="h-5 w-5 text-destructive" />
            Détails de l&apos;Incident
          </SheetTitle>
          <SheetDescription className="font-mono text-xs">
            ID: {incidentId}
          </SheetDescription>
        </SheetHeader>

        <div className="flex-1 flex flex-col min-h-0 py-4 gap-4">
          <h3 className="font-semibold text-sm flex items-center gap-2">
            <Clock className="h-4 w-4 text-muted-foreground" />
            Historique (Timeline)
          </h3>
          
          <div className="flex-1 border rounded-md p-4 bg-muted/10 overflow-y-auto">
            {loading ? (
              <div className="space-y-4">
                <Skeleton className="h-12 w-full" />
                <Skeleton className="h-12 w-full" />
                <Skeleton className="h-12 w-full" />
              </div>
            ) : events.length === 0 ? (
              <p className="text-sm text-muted-foreground text-center py-8">
                Aucun événement enregistré.
              </p>
            ) : (
              <div className="space-y-4 relative before:absolute before:inset-0 before:ml-5 before:-translate-x-px md:before:mx-auto md:before:translate-x-0 before:h-full before:w-0.5 before:bg-gradient-to-b before:from-transparent before:via-slate-300 before:to-transparent">
                {events.map((evt) => (
                  <div key={evt.id} className="relative flex items-center justify-between md:justify-normal md:odd:flex-row-reverse group is-active">
                    {/* Icon */}
                    <div className="flex items-center justify-center w-6 h-6 rounded-full border border-white bg-slate-300 text-slate-500 shadow shrink-0 md:order-1 md:group-odd:-translate-x-1/2 md:group-even:translate-x-1/2 z-10">
                      {evt.action === "created" ? <AlertTriangle className="h-3 w-3 text-destructive" /> : 
                       evt.action === "acknowledged" ? <CheckCheck className="h-3 w-3 text-blue-500" /> :
                       <User className="h-3 w-3" />}
                    </div>
                    {/* Card */}
                    <div className="w-[calc(100%-2.5rem)] md:w-[calc(50%-1.5rem)] p-3 rounded border bg-card shadow">
                      <div className="flex items-center justify-between mb-1">
                        <div className="font-bold text-xs capitalize">{evt.action}</div>
                        <time className="font-mono text-[10px] text-muted-foreground">{new Date(evt.createdAt).toLocaleTimeString()}</time>
                      </div>
                      <div className="text-xs text-muted-foreground">
                        {evt.note || (evt.actorId ? `Par Admin #${evt.actorId}` : "Système")}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

          <div className="space-y-2 mt-4">
            <h3 className="font-semibold text-sm">Action Manuelle</h3>
            <textarea 
              placeholder="Ajouter une note de résolution ou un détail (obligatoire pour clôturer)..."
              className="flex min-h-[80px] w-full rounded-md border border-input bg-transparent px-3 py-2 text-sm shadow-sm placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50"
              value={note}
              onChange={(e) => setNote(e.target.value)}
              disabled={updating}
            />
          </div>
        </div>

        <SheetFooter className="pt-4 border-t gap-2 sm:gap-0">
          <div className="flex flex-wrap gap-2 w-full justify-between">
            <Button 
              variant="outline" 
              size="sm" 
              onClick={() => handleUpdate("acknowledged")}
              disabled={updating}
              className="w-[48%]"
            >
              Prendre en charge (Ack)
            </Button>
            <Button 
              variant="secondary" 
              size="sm" 
              onClick={() => handleUpdate("escalated")}
              disabled={updating}
              className="w-[48%] border-orange-200 text-orange-600 hover:bg-orange-50"
            >
              Escalader (Force)
            </Button>
            <Button 
              variant="default" 
              size="sm" 
              onClick={() => handleUpdate("resolved")}
              disabled={updating}
              className="w-[48%] bg-green-600 hover:bg-green-700 text-white"
            >
              Clôturer (Résolu)
            </Button>
            <Button 
              variant="destructive" 
              size="sm" 
              onClick={() => handleUpdate("false_alarm")}
              disabled={updating}
              className="w-[48%]"
            >
              <XCircle className="w-4 h-4 mr-1.5" />
              Fausse Alarme
            </Button>
          </div>
        </SheetFooter>
      </SheetContent>
    </Sheet>
  );
}
