"use client";

import { useEffect, useRef, useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import { getUsers, getAdminVehicles, getAlerts } from "@/lib/api";
import { Search, User, Car, Bell, X } from "lucide-react";

interface SearchResult {
  id: string;
  type: "user" | "vehicle" | "alert";
  label: string;
  sub: string;
  href: string;
}

export function GlobalSearch() {
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<SearchResult[]>([]);
  const [loading, setLoading] = useState(false);
  const [selected, setSelected] = useState(0);
  const inputRef = useRef<HTMLInputElement>(null);
  const debounceRef = useRef<ReturnType<typeof setTimeout>>(null);

  // Open on ⌘K / Ctrl+K
  useEffect(() => {
    function onKeyDown(e: KeyboardEvent) {
      if ((e.metaKey || e.ctrlKey) && e.key === "k") {
        e.preventDefault();
        setOpen((o) => !o);
      }
      if (e.key === "Escape") setOpen(false);
    }
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, []);

  // Focus input when opened
  useEffect(() => {
    if (open) {
      setTimeout(() => inputRef.current?.focus(), 50);
      setQuery("");
      setResults([]);
      setSelected(0);
    }
  }, [open]);

  const search = useCallback(async (q: string) => {
    if (!q.trim()) { setResults([]); return; }
    setLoading(true);
    try {
      const [usersRes, vehiclesRes, alertsRes] = await Promise.all([
        getUsers(),
        getAdminVehicles(),
        getAlerts(),
      ]);

      const ql = q.toLowerCase();
      const out: SearchResult[] = [];

      for (const u of usersRes.data) {
        if (
          u.name?.toLowerCase().includes(ql) ||
          u.email?.toLowerCase().includes(ql) ||
          u.phone?.includes(q)
        ) {
          out.push({
            id: `user-${u.id}`,
            type: "user",
            label: u.name || u.email,
            sub: u.email,
            href: `/users/${u.id}`,
          });
        }
      }

      for (const v of vehiclesRes.data) {
        if (
          v.name?.toLowerCase().includes(ql) ||
          v.plate?.toLowerCase().includes(ql) ||
          v.serialNumber?.toLowerCase().includes(ql)
        ) {
          out.push({
            id: `vehicle-${v.id}`,
            type: "vehicle",
            label: v.name,
            sub: [v.plate, v.status].filter(Boolean).join(" · "),
            href: `/vehicles/${v.id}`,
          });
        }
      }

      for (const a of alertsRes.data) {
        const label = a.type?.replace(/_/g, " ");
        if (
          label?.toLowerCase().includes(ql) ||
          a.deviceId?.toString().includes(q) ||
          a.status?.includes(ql)
        ) {
          out.push({
            id: `alert-${a.id}`,
            type: "alert",
            label: label,
            sub: `${a.status} · device #${a.deviceId}`,
            href: `/alerts`,
          });
        }
      }

      setResults(out.slice(0, 12));
      setSelected(0);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (debounceRef.current) clearTimeout(debounceRef.current);
    debounceRef.current = setTimeout(() => search(query), 250);
    return () => { if (debounceRef.current) clearTimeout(debounceRef.current); };
  }, [query, search]);

  function navigate(href: string) {
    router.push(href);
    setOpen(false);
  }

  function onKeyDown(e: React.KeyboardEvent) {
    if (e.key === "ArrowDown") { e.preventDefault(); setSelected((s) => Math.min(s + 1, results.length - 1)); }
    if (e.key === "ArrowUp") { e.preventDefault(); setSelected((s) => Math.max(s - 1, 0)); }
    if (e.key === "Enter" && results[selected]) navigate(results[selected].href);
  }

  const ICON: Record<string, React.ReactNode> = {
    user: <User className="h-4 w-4 text-trackeo-idle" />,
    vehicle: <Car className="h-4 w-4 text-trackeo-online" />,
    alert: <Bell className="h-4 w-4 text-trackeo-warning" />,
  };

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center pt-[15vh]">
      {/* Backdrop */}
      <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" onClick={() => setOpen(false)} />

      {/* Palette */}
      <div className="relative w-full max-w-lg mx-4 bg-card rounded-xl shadow-2xl border overflow-hidden">
        {/* Input */}
        <div className="flex items-center gap-3 px-4 py-3 border-b">
          <Search className="h-4 w-4 text-muted-foreground shrink-0" />
          <input
            ref={inputRef}
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            onKeyDown={onKeyDown}
            placeholder="Search users, vehicles, alerts…"
            className="flex-1 bg-transparent outline-none text-sm placeholder:text-muted-foreground"
          />
          {query && (
            <button onClick={() => setQuery("")} className="text-muted-foreground hover:text-foreground">
              <X className="h-4 w-4" />
            </button>
          )}
          <kbd className="text-xs text-muted-foreground border rounded px-1.5 py-0.5 font-mono">Esc</kbd>
        </div>

        {/* Results */}
        <div className="max-h-80 overflow-y-auto">
          {loading && (
            <p className="text-center text-sm text-muted-foreground py-6">Searching…</p>
          )}
          {!loading && query && results.length === 0 && (
            <p className="text-center text-sm text-muted-foreground py-6">No results for &quot;{query}&quot;</p>
          )}
          {!loading && !query && (
            <p className="text-center text-sm text-muted-foreground py-6">
              Type to search across users, vehicles and alerts
            </p>
          )}
          {results.map((r, i) => (
            <div
              key={r.id}
              className={`flex items-center gap-3 px-4 py-3 cursor-pointer transition-colors ${
                i === selected ? "bg-primary/10" : "hover:bg-muted/50"
              }`}
              onMouseEnter={() => setSelected(i)}
              onClick={() => navigate(r.href)}
            >
              <span className="shrink-0">{ICON[r.type]}</span>
              <div className="min-w-0">
                <p className="text-sm font-medium truncate">{r.label}</p>
                <p className="text-xs text-muted-foreground truncate">{r.sub}</p>
              </div>
              <span className="ml-auto shrink-0 text-xs text-muted-foreground capitalize border rounded px-1.5 py-0.5">
                {r.type}
              </span>
            </div>
          ))}
        </div>

        {/* Footer */}
        <div className="flex items-center gap-4 px-4 py-2 border-t text-xs text-muted-foreground">
          <span className="flex items-center gap-1"><kbd className="border rounded px-1 font-mono">↑↓</kbd> navigate</span>
          <span className="flex items-center gap-1"><kbd className="border rounded px-1 font-mono">↵</kbd> open</span>
          <span className="flex items-center gap-1"><kbd className="border rounded px-1 font-mono">Esc</kbd> close</span>
        </div>
      </div>
    </div>
  );
}
