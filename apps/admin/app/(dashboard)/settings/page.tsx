"use client";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";

const settings = [
  {
    section: "API",
    items: [
      { label: "API URL", value: process.env.NEXT_PUBLIC_API_URL || "http://localhost:3000/api" },
    ],
  },
  {
    section: "Notifications",
    items: [
      { label: "OneSignal", value: "Configured via backend .env" },
      { label: "WhatsApp Business", value: "Configured via backend .env" },
    ],
  },
  {
    section: "Infrastructure",
    items: [
      { label: "Traccar", value: "http://localhost:8082" },
      { label: "PostgreSQL", value: "TimescaleDB" },
    ],
  },
];

export default function SettingsPage() {
  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">System Configuration</h1>
      <div className="space-y-6">
        {settings.map(({ section, items }) => (
          <Card key={section}>
            <CardHeader>
              <CardTitle className="text-base">{section}</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              {items.map(({ label, value }) => (
                <div key={label} className="flex items-center justify-between py-1 border-b last:border-0">
                  <span className="text-sm text-muted-foreground">{label}</span>
                  <Badge variant="outline" className="font-mono text-xs">
                    {value}
                  </Badge>
                </div>
              ))}
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
}
