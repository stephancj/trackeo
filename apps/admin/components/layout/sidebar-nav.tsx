"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { cn } from "@/lib/utils";
import { clearToken } from "@/lib/auth";
import {
  Users,
  Cpu,
  MapPin,
  Bell,
  BarChart2,
  CreditCard,
  Settings,
  LogOut,
  Map,
} from "lucide-react";
import { Button } from "@/components/ui/button";

const navItems = [
  { href: "/", label: "Dashboard", icon: BarChart2 },
  { href: "/users", label: "Users", icon: Users },
  { href: "/devices", label: "Devices", icon: Cpu },
  { href: "/geofences", label: "Geofences", icon: MapPin },
  { href: "/alerts", label: "Alerts", icon: Bell },
  { href: "/reports", label: "Reports", icon: Map },
  { href: "/subscriptions", label: "Subscriptions", icon: CreditCard },
  { href: "/settings", label: "Settings", icon: Settings },
];

export function SidebarNav() {
  const pathname = usePathname();
  const router = useRouter();

  function handleLogout() {
    clearToken();
    router.push("/login");
  }

  return (
    <aside className="flex flex-col w-60 min-h-screen border-r bg-card px-3 py-4">
      <div className="mb-8 px-2">
        <span className="text-xl font-bold tracking-tight">Trackeo</span>
        <span className="ml-1 text-xs text-muted-foreground font-medium">Admin</span>
      </div>
      <nav className="flex-1 space-y-1">
        {navItems.map(({ href, label, icon: Icon }) => (
          <Link
            key={href}
            href={href}
            className={cn(
              "flex items-center gap-3 rounded-md px-3 py-2 text-sm font-medium transition-colors",
              pathname === href
                ? "bg-primary text-primary-foreground"
                : "text-muted-foreground hover:bg-muted hover:text-foreground"
            )}
          >
            <Icon className="h-4 w-4" />
            {label}
          </Link>
        ))}
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
