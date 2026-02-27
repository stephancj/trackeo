import { SidebarNav } from "@/components/layout/sidebar-nav";
import { AuthGuard } from "@/components/layout/auth-guard";

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <AuthGuard>
      <div className="flex min-h-screen">
        <SidebarNav />
        <main className="flex-1 overflow-auto bg-muted/20">
          <div className="p-6">{children}</div>
        </main>
      </div>
    </AuthGuard>
  );
}
