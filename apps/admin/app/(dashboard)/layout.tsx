import Link from "next/link";
import { SidebarNav } from "@/components/layout/sidebar-nav";
import { GlobalSearch } from "@/components/global-search";

const mobileLinks = [
  ["/", "Vue d’ensemble"],
  ["/users", "Utilisateurs"],
  ["/vehicles", "Véhicules"],
  ["/map", "Carte"],
  ["/geofences", "Zones"],
  ["/alerts", "Alertes"],
  ["/reports", "Rapports"],
  ["/settings", "Configuration"],
];

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-screen flex-col lg:flex-row">
      <SidebarNav />
      <div className="sticky top-0 z-20 border-b bg-background lg:hidden">
        <div className="flex h-14 items-center justify-between px-4">
          <span className="font-bold text-foreground">iooeh Admin</span>
          <span className="text-xs font-semibold text-trackeo-primary">OPÉRATIONS</span>
        </div>
        <nav className="flex gap-1 overflow-x-auto px-3 pb-3" aria-label="Navigation mobile">
          {mobileLinks.map(([href, label]) => (
            <Link
              key={href}
              href={href}
              className="shrink-0 rounded-full border bg-card px-3 py-2 text-sm font-medium text-muted-foreground hover:border-primary hover:text-foreground"
            >
              {label}
            </Link>
          ))}
        </nav>
      </div>
      <main className="min-w-0 flex-1 overflow-auto bg-muted/20">
        <div className="p-4 md:p-6">{children}</div>
      </main>
      <GlobalSearch />
    </div>
  );
}
