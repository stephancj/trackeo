"use client";

import { useEffect, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Switch } from "@/components/ui/switch";
import { getConfig, updateConfig } from "@/lib/api";
import { toast } from "sonner";
import { Skeleton } from "@/components/ui/skeleton";

interface ConfigData {
  apiUrl: string;
  traccarUrl: string;
  oneSignalAppId: string;
  whatsappEnabled: boolean;
  pushEnabled: boolean;
  database: string;
}

export default function SettingsPage() {
  const [config, setConfig] = useState<ConfigData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getConfig()
      .then((res) => setConfig(res.data))
      .catch(() => toast.error("Erreur lors du chargement de la configuration"))
      .finally(() => setLoading(false));
  }, []);

  async function handleToggle(key: string, currentValue: boolean) {
    if (!config) return;
    const newValue = !currentValue;
    // Optimistic update
    setConfig({ ...config, [key]: newValue });
    try {
      const dbKey = key === "whatsappEnabled" ? "whatsapp_enabled" : "push_enabled";
      await updateConfig(dbKey, newValue);
      toast.success("Configuration mise à jour");
    } catch {
      setConfig({ ...config, [key]: currentValue });
      toast.error("Impossible de mettre à jour la configuration");
    }
  }

  if (loading || !config) {
    return (
      <div>
        <h1 className="text-2xl font-bold mb-6">System Configuration</h1>
        <div className="space-y-6">
          {[1, 2, 3].map((i) => (
            <Card key={i}>
              <CardHeader><Skeleton className="h-6 w-32" /></CardHeader>
              <CardContent><Skeleton className="h-10 w-full" /></CardContent>
            </Card>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">System Configuration</h1>
      <div className="space-y-6">
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Infrastructure</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <div className="flex items-center justify-between py-1 border-b last:border-0">
              <span className="text-sm text-muted-foreground">Backend API URL</span>
              <Badge variant="outline" className="font-mono text-xs">{config.apiUrl}</Badge>
            </div>
            <div className="flex items-center justify-between py-1 border-b last:border-0">
              <span className="text-sm text-muted-foreground">Serveur Traccar</span>
              <Badge variant="outline" className="font-mono text-xs">{config.traccarUrl}</Badge>
            </div>
            <div className="flex items-center justify-between py-1 border-b last:border-0">
              <span className="text-sm text-muted-foreground">Base de données</span>
              <Badge variant="outline" className="font-mono text-xs">{config.database}</Badge>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-base">Notifications (Globales)</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center justify-between py-1 border-b">
              <div className="space-y-0.5">
                <span className="text-sm font-medium">WhatsApp Business</span>
                <p className="text-xs text-muted-foreground">Autoriser l'envoi d'alertes via WhatsApp.</p>
              </div>
              <Switch
                checked={config.whatsappEnabled}
                onCheckedChange={() => handleToggle("whatsappEnabled", config.whatsappEnabled)}
              />
            </div>
            <div className="flex items-center justify-between py-1 border-b">
              <div className="space-y-0.5">
                <span className="text-sm font-medium">Push OneSignal</span>
                <p className="text-xs text-muted-foreground">Autoriser l'envoi de notifications push sur mobile.</p>
              </div>
              <Switch
                checked={config.pushEnabled}
                onCheckedChange={() => handleToggle("pushEnabled", config.pushEnabled)}
              />
            </div>
            <div className="flex items-center justify-between py-1">
              <span className="text-sm text-muted-foreground">OneSignal App ID</span>
              <Badge variant="outline" className="font-mono text-xs">{config.oneSignalAppId}</Badge>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
