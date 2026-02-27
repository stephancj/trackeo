"use client";

import { useEffect, useState } from "react";
import { getDevices } from "@/lib/api";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";

interface Device {
  id: number;
  name: string;
  uniqueId: string;
  status: string;
  lastUpdate: string;
  phone: string;
}

export default function DevicesPage() {
  const [devices, setDevices] = useState<Device[]>([]);
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getDevices()
      .then((res) => setDevices(res.data))
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  const filtered = devices.filter(
    (d) =>
      d.name?.toLowerCase().includes(search.toLowerCase()) ||
      d.uniqueId?.toLowerCase().includes(search.toLowerCase())
  );

  function statusVariant(status: string) {
    if (status === "online") return "default";
    if (status === "offline") return "secondary";
    return "outline";
  }

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Devices</h1>
      <div className="mb-4">
        <Input
          placeholder="Search by name or IMEI..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="max-w-sm"
        />
      </div>
      <div className="rounded-md border bg-card">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Name</TableHead>
              <TableHead>IMEI / Unique ID</TableHead>
              <TableHead>Status</TableHead>
              <TableHead>Last Update</TableHead>
              <TableHead>Phone</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {loading ? (
              Array.from({ length: 5 }).map((_, i) => (
                <TableRow key={i}>
                  {Array.from({ length: 5 }).map((_, j) => (
                    <TableCell key={j}>
                      <Skeleton className="h-4 w-full" />
                    </TableCell>
                  ))}
                </TableRow>
              ))
            ) : filtered.length === 0 ? (
              <TableRow>
                <TableCell colSpan={5} className="text-center text-muted-foreground py-8">
                  No devices found
                </TableCell>
              </TableRow>
            ) : (
              filtered.map((device) => (
                <TableRow key={device.id}>
                  <TableCell className="font-medium">{device.name}</TableCell>
                  <TableCell className="font-mono text-sm">{device.uniqueId}</TableCell>
                  <TableCell>
                    <Badge variant={statusVariant(device.status)}>{device.status}</Badge>
                  </TableCell>
                  <TableCell className="text-muted-foreground text-sm">
                    {device.lastUpdate ? new Date(device.lastUpdate).toLocaleString() : "—"}
                  </TableCell>
                  <TableCell>{device.phone || "—"}</TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </div>
    </div>
  );
}
