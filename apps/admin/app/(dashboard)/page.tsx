"use client";

import { useEffect, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { getUsers, getDevices, getAlerts, getVehicles } from "@/lib/api";
import { Users, Cpu, Bell, Car } from "lucide-react";

interface Stats {
  users: number;
  devices: number;
  alerts: number;
  vehicles: number;
}

export default function DashboardPage() {
  const [stats, setStats] = useState<Stats>({ users: 0, devices: 0, alerts: 0, vehicles: 0 });

  useEffect(() => {
    Promise.allSettled([getUsers(), getDevices(), getAlerts(), getVehicles()]).then(
      ([users, devices, alerts, vehicles]) => {
        setStats({
          users: users.status === "fulfilled" ? (users.value.data?.length ?? 0) : 0,
          devices: devices.status === "fulfilled" ? (devices.value.data?.length ?? 0) : 0,
          alerts: alerts.status === "fulfilled" ? (alerts.value.data?.length ?? 0) : 0,
          vehicles: vehicles.status === "fulfilled" ? (vehicles.value.data?.length ?? 0) : 0,
        });
      }
    );
  }, []);

  const cards = [
    { label: "Users", value: stats.users, icon: Users, color: "text-blue-500" },
    { label: "Devices", value: stats.devices, icon: Cpu, color: "text-green-500" },
    { label: "Vehicles", value: stats.vehicles, icon: Car, color: "text-orange-500" },
    { label: "Alerts", value: stats.alerts, icon: Bell, color: "text-red-500" },
  ];

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Dashboard</h1>
      <div className="grid gap-4 grid-cols-1 sm:grid-cols-2 lg:grid-cols-4">
        {cards.map(({ label, value, icon: Icon, color }) => (
          <Card key={label}>
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">{label}</CardTitle>
              <Icon className={`h-5 w-5 ${color}`} />
            </CardHeader>
            <CardContent>
              <div className="text-3xl font-bold">{value}</div>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
}
