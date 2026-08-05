"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { cn } from "@/lib/utils";
import { clearToken } from "@/lib/auth";
import { getAlerts } from "@/lib/api";
import {
  Users,
  Car,
  MapPin,
  Bell,
  BarChart2,
  Settings,
  LogOut,
  Map,
  Search,
  LayoutDashboard,
  Boxes,
  Layers3,
  CreditCard,
  ShieldAlert,
} from "lucide-react";
import { Button } from "@/components/ui/button";

export function SidebarNav() {
  const pathname = usePathname();
  const router = useRouter();
  const [openAlerts, setOpenAlerts] = useState(0);

  useEffect(() => {
    function fetchOpenAlerts() {
      getAlerts()
        .then((r) => {
          const open = (r.data as { status: string }[]).filter(
            (a) => a.status === "open"
          ).length;
          setOpenAlerts(open);
        })
        .catch(() => {});
    }
    fetchOpenAlerts();
    const id = setInterval(fetchOpenAlerts, 60_000);
    return () => clearInterval(id);
  }, []);

  function handleLogout() {
    clearToken();
    router.push("/login");
  }

  function openSearch() {
    window.dispatchEvent(new KeyboardEvent("keydown", { key: "k", metaKey: true, bubbles: true }));
  }

  const navItems = [
    { href: "/", label: "Vue d’ensemble", icon: LayoutDashboard, exact: true },
    { href: "/users", label: "Utilisateurs", icon: Users },
    { href: "/vehicles", label: "Véhicules", icon: Car },
    { href: "/map", label: "Carte de la flotte", icon: Map },
    { href: "/geofences", label: "Zones", icon: MapPin },
    {
      href: "/alerts",
      label: "Alertes",
      icon: Bell,
      badge: openAlerts > 0 ? openAlerts : undefined,
    },
    { href: "/incidents", label: "Incidents sécurité", icon: ShieldAlert },
    { href: "/reports", label: "Rapports", icon: BarChart2 },
    { href: "/features", label: "Fonctionnalités", icon: Boxes },
    { href: "/plans", label: "Plans", icon: Layers3 },
    { href: "/subscriptions", label: "Abonnements", icon: CreditCard },
    { href: "/settings", label: "Configuration", icon: Settings },
  ];

  return (
    <aside className="hidden lg:flex flex-col w-60 min-h-screen border-r border-sidebar-border bg-sidebar px-3 py-5">
      {/* Brand */}
      <div className="mb-5 px-3 flex items-center gap-2">
        <div className="h-8 w-8 rounded-lg bg-trackeo-primary flex items-center justify-center">
          <MapPin className="h-4.5 w-4.5 text-white" />
        </div>
        <div className="flex items-baseline gap-1.5">
          <span className="text-lg font-bold tracking-tight text-foreground">iooeh</span>
          <span className="text-[10px] font-semibold uppercase tracking-widest text-trackeo-primary">Admin</span>
        </div>
      </div>

      {/* Search */}
      <button
        onClick={openSearch}
        className="flex items-center gap-2 w-full mb-4 px-3 py-2 text-sm text-muted-foreground rounded-lg border border-border bg-background/60 hover:bg-background transition-colors"
      >
        <Search className="h-3.5 w-3.5" />
        <span className="flex-1 text-left">Rechercher…</span>
        <kbd className="text-[10px] border border-border rounded px-1.5 py-0.5 font-mono text-muted-foreground bg-muted">⌘K</kbd>
      </button>

      {/* Navigation */}
      <nav className="flex-1 space-y-0.5">
        {navItems.map(({ href, label, icon: Icon, badge, exact }) => {
          const active = exact
            ? pathname === href
            : pathname === href || pathname.startsWith(href + "/");
          return (
            <Link
              key={href}
              href={href}
              className={cn(
                "flex items-center justify-between rounded-lg px-3 py-2 text-sm font-medium transition-all duration-150",
                active
                  ? "bg-trackeo-primary text-white shadow-sm"
                  : "text-sidebar-foreground hover:bg-sidebar-accent hover:text-sidebar-accent-foreground"
              )}
            >
              <span className="flex items-center gap-3">
                <Icon className="h-4 w-4 shrink-0" />
                {label}
              </span>
              {badge != null && (
                <span
                  className={cn(
                    "inline-flex h-5 min-w-5 items-center justify-center rounded-full px-1.5 text-[10px] font-bold tabular-nums",
                    active
                      ? "bg-white/20 text-white"
                      : "bg-trackeo-alert text-white"
                  )}
                >
                  {badge > 99 ? "99+" : badge}
                </span>
              )}
            </Link>
          );
        })}
      </nav>

      {/* Logout */}
      <div className="pt-4 border-t border-sidebar-border">
        <Button
          variant="ghost"
          className="w-full justify-start gap-3 text-muted-foreground hover:text-foreground hover:bg-sidebar-accent"
          onClick={handleLogout}
        >
          <LogOut className="h-4 w-4" />
          Déconnexion
        </Button>
      </div>
    </aside>
  );
}
