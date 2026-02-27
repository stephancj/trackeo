import { SidebarNav } from "@/components/layout/sidebar-nav";
import { GlobalSearch } from "@/components/global-search";

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-screen">
      <SidebarNav />
      <main className="flex-1 overflow-auto bg-muted/20">
        <div className="p-6">{children}</div>
      </main>
      <GlobalSearch />
    </div>
  );
}
