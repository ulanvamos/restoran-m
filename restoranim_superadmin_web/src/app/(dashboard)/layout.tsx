"use client";

import { useEffect, useState } from "react";
import { useRouter, usePathname } from "next/navigation";
import { supabase } from "@/lib/supabase";
import Link from "next/link";
import { LayoutDashboard, Store, MessageSquare, Headset, LogOut, CalendarCheck, CircleDollarSign, Utensils, Users, Settings } from "lucide-react";

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const router = useRouter();
  const pathname = usePathname();
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const checkUser = async () => {
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) {
        router.replace("/login");
      } else {
        setLoading(false);
      }
    };
    
    checkUser();

    const { data: authListener } = supabase.auth.onAuthStateChange(
      (event, session) => {
        if (!session) {
          router.replace("/login");
        }
      }
    );

    return () => {
      authListener.subscription.unsubscribe();
    };
  }, [router]);

  if (loading) {
    return <div className="min-h-screen bg-background flex items-center justify-center">Yükleniyor...</div>;
  }

  const menuItems = [
    { name: "Dashboard", icon: LayoutDashboard, href: "/" },
    { name: "Restoranlar", icon: Store, href: "/restaurants" },
    { name: "Rezervasyonlar", icon: CalendarCheck, href: "/reservations" },
    { name: "Yorumlar", icon: MessageSquare, href: "/reviews" },
    { name: "Canlı Destek", icon: Headset, href: "/support" },
    { name: "Finans & Gelirler", icon: CircleDollarSign, href: "/finances" },
  ];

  return (
    <div className="flex h-screen bg-background overflow-hidden">
      {/* Sidebar */}
      <aside className="w-64 bg-[var(--color-sidebar)] border-r border-[var(--color-sidebar-border)] flex flex-col shrink-0 z-20">
        <div className="h-16 flex items-center px-6 border-b border-[var(--color-sidebar-border)] bg-[var(--color-sidebar)]">
          <div className="flex items-center gap-3">
            <Utensils className="w-6 h-6 text-primary" />
            <span className="text-sm font-black text-[var(--color-sidebar-text)] tracking-widest uppercase">Yönetim Paneli</span>
          </div>
        </div>
        
        <nav className="flex-1 px-3 py-6 space-y-1 overflow-y-auto">
          {menuItems.map((item) => {
            const isActive = pathname === item.href;
            return (
              <Link
                key={item.href}
                href={item.href}
                className={`flex items-center gap-3 px-3 py-2 rounded-md text-sm font-medium transition-colors ${
                  isActive
                    ? "bg-primary text-white shadow-sm"
                    : "text-[var(--color-sidebar-text-muted)] hover:bg-[var(--color-sidebar-hover)] hover:text-white"
                }`}
              >
                <item.icon className={`w-4 h-4 ${isActive ? "text-white" : "text-[var(--color-sidebar-text-muted)] group-hover:text-white"}`} />
                {item.name}
              </Link>
            );
          })}
        </nav>

        <div className="p-4 border-t border-[var(--color-sidebar-border)]">
          <button
            onClick={() => supabase.auth.signOut()}
            className="flex items-center gap-3 px-3 py-2 w-full text-left text-error hover:bg-error/10 hover:text-error rounded-md transition-colors text-sm font-medium"
          >
            <LogOut className="w-4 h-4" />
            Çıkış Yap
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 overflow-y-auto bg-background">
        {children}
      </main>
    </div>
  );
}
