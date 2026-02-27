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
  CreditCard,
  Settings,
  LogOut,
  Map,
  Search,
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
    { href: "/", label: "Dashboard", icon: BarChart2, exact: true },
    { href: "/users", label: "Users", icon: Users },
    { href: "/vehicles", label: "Vehicles", icon: Car },
    { href: "/map", label: "Fleet Map", icon: Map },
    { href: "/geofences", label: "Geofences", icon: MapPin },
    {
      href: "/alerts",
      label: "Alerts",
      icon: Bell,
      badge: openAlerts > 0 ? openAlerts : undefined,
    },
    { href: "/reports", label: "Reports", icon: BarChart2 },
    { href: "/subscriptions", label: "Subscriptions", icon: CreditCard },
    { href: "/settings", label: "Settings", icon: Settings },
  ];

  return (
    <aside className="flex flex-col w-60 min-h-screen border-r bg-card px-3 py-4">
      <div className="mb-6 px-2">
        <span className="text-xl font-bold tracking-tight">Trackeo</span>
        <span className="ml-1 text-xs text-muted-foreground font-medium">Admin</span>
      </div>

      {/* ⌘K search button */}
      <button
        onClick={openSearch}
        className="flex items-center gap-2 w-full mb-4 px-3 py-2 text-sm text-muted-foreground rounded-md border bg-muted/40 hover:bg-muted transition-colors"
      >
        <Search className="h-3.5 w-3.5" />
        <span className="flex-1 text-left">Search…</span>
        <kbd className="text-xs border rounded px-1 font-mono bg-card">⌘K</kbd>
      </button>

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
                "flex items-center justify-between rounded-md px-3 py-2 text-sm font-medium transition-colors",
                active
                  ? "bg-primary text-primary-foreground"
                  : "text-muted-foreground hover:bg-muted hover:text-foreground"
              )}
            >
              <span className="flex items-center gap-3">
                <Icon className="h-4 w-4 shrink-0" />
                {label}
              </span>
              {badge != null && (
                <span
                  className={cn(
                    "inline-flex h-5 min-w-5 items-center justify-center rounded-full px-1.5 text-xs font-semibold tabular-nums",
                    active
                      ? "bg-primary-foreground/20 text-primary-foreground"
                      : "bg-destructive text-destructive-foreground"
                  )}
                >
                  {badge > 99 ? "99+" : badge}
                </span>
              )}
            </Link>
          );
        })}
      </nav>
      <div className="pt-4 border-t">
        <Button
          variant="ghost"
          className="w-full justify-start gap-3 text-muted-foreground"
          onClick={handleLogout}
        >
          <LogOut className="h-4 w-4" />
          Logout
        </Button>
      </div>
    </aside>
  );
}
