"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";
import { Users, Store, Clock, CalendarCheck, MessageSquare, Headset, CircleDollarSign } from "lucide-react";
import {
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip as RechartsTooltip, ResponsiveContainer,
  BarChart, Bar, Legend
} from 'recharts';

export default function DashboardPage() {
  const [stats, setStats] = useState({
    totalRestaurants: 0,
    pendingRestaurants: 0,
    totalUsers: 0,
    totalReservations: 0,
    openTickets: 0,
    totalReviews: 0,
    totalRevenue: 0,
  });
  
  const [recentActivities, setRecentActivities] = useState<any[]>([]);
  const [reservationTrend, setReservationTrend] = useState<any[]>([]);
  const [revenueData, setRevenueData] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchStats = async () => {
      try {
        const [
          { count: totalRestaurants },
          { count: pendingRestaurants },
          { count: totalUsers },
          { data: reservationsData, count: totalReservations },
          { count: openTickets },
          { count: totalReviews },
        ] = await Promise.all([
          supabase.from("restaurants").select("*", { count: "exact", head: true }),
          supabase.from("restaurants").select("*", { count: "exact", head: true }).eq("is_verified", false),
          supabase.from("profiles").select("*", { count: "exact", head: true }),
          supabase.from("reservations").select("reservation_date, guest_count", { count: "exact" }),
          supabase.from("support_tickets").select("*", { count: "exact", head: true }).eq("status", "open"),
          supabase.from("reviews").select("*", { count: "exact", head: true }),
        ]);

        // Revenue simulation: Calculate from real reservations data
        const mockRevenue = (totalReservations || 0) * 500;

        setStats({
          totalRestaurants: totalRestaurants || 0,
          pendingRestaurants: pendingRestaurants || 0,
          totalUsers: totalUsers || 0,
          totalReservations: totalReservations || 0,
          openTickets: openTickets || 0,
          totalReviews: totalReviews || 0,
          totalRevenue: mockRevenue,
        });

        // Fetch recent restaurants for activity log
        const { data: recentRest } = await supabase
          .from("restaurants")
          .select("id, name, created_at")
          .order("created_at", { ascending: false })
          .limit(5);

        // Group reservations by date for the last 7 days
        const mockTrend = [];
        const mockRev = [];
        
        // Build map of counts
        const dailyCounts: Record<string, number> = {};
        if (reservationsData) {
          reservationsData.forEach((res: any) => {
            if (res.reservation_date) {
              const dateKey = new Date(res.reservation_date).toLocaleDateString('tr-TR', { weekday: 'short' });
              dailyCounts[dateKey] = (dailyCounts[dateKey] || 0) + 1;
            }
          });
        }

        for (let i = 6; i >= 0; i--) {
          const d = new Date();
          d.setDate(d.getDate() - i);
          const dayName = d.toLocaleDateString('tr-TR', { weekday: 'short' });
          const count = dailyCounts[dayName] || 0;
          
          mockTrend.push({
            name: dayName,
            rezervasyon: count,
          });
          mockRev.push({
            name: dayName,
            gelir: count * 500,
          });
        }
        setReservationTrend(mockTrend);
        setRevenueData(mockRev);

        setRecentActivities(recentRest || []);
      } catch (error) {
        console.error("Error fetching stats:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchStats();
  }, []);

  if (loading) {
    return <div className="p-8 text-text-secondary">İstatistikler yükleniyor...</div>;
  }

  const statCards = [
    { name: "Toplam Restoran", value: stats.totalRestaurants, icon: Store, color: "text-blue-500", bg: "bg-blue-500/10" },
    { name: "Onay Bekleyen", value: stats.pendingRestaurants, icon: Clock, color: "text-warning", bg: "bg-warning/10" },
    { name: "Toplam Kullanıcı", value: stats.totalUsers, icon: Users, color: "text-indigo-500", bg: "bg-indigo-500/10" },
    { name: "Toplam Rezervasyon", value: stats.totalReservations, icon: CalendarCheck, color: "text-purple-500", bg: "bg-purple-500/10" },
    { name: "Açık Destek Talebi", value: stats.openTickets, icon: Headset, color: "text-error", bg: "bg-error/10" },
    { name: "Sistem Yorumları", value: stats.totalReviews, icon: MessageSquare, color: "text-teal-500", bg: "bg-teal-500/10" },
    { name: "Tahmini Ciro Hacmi", value: `₺${stats.totalRevenue.toLocaleString("tr-TR")}`, icon: CircleDollarSign, color: "text-success", bg: "bg-success/10" },
  ];

  return (
    <div className="p-8 max-w-7xl mx-auto">
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-text-primary">Dashboard</h1>
        <p className="text-text-secondary mt-1">Sistem geneli özet istatistikler ve anlık durum</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        {statCards.map((stat, i) => (
          <div key={i} className="bg-surface rounded-md p-6 border border-divider shadow-sm flex items-center gap-4 transition-transform hover:-translate-y-1">
            <div className={`w-14 h-14 rounded-md flex items-center justify-center ${stat.bg}`}>
              <stat.icon className={`w-7 h-7 ${stat.color}`} />
            </div>
            <div>
              <div className="text-sm font-medium text-text-secondary">{stat.name}</div>
              <div className="text-2xl font-bold text-text-primary mt-1">{stat.value}</div>
            </div>
          </div>
        ))}
      </div>

      {/* Charts Section */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        {/* Reservation Trend Chart */}
        <div className="bg-surface rounded-md border border-divider overflow-hidden p-6">
          <h2 className="text-sm font-bold text-text-primary mb-4 uppercase tracking-wider">Son 7 Gün Rezervasyon Trendi</h2>
          <div className="h-72 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={reservationTrend} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                <defs>
                  <linearGradient id="colorRez" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#8b5cf6" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="#8b5cf6" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="rgba(255,255,255,0.1)" />
                <XAxis dataKey="name" tick={{ fill: '#9ca3af', fontSize: 12 }} axisLine={false} tickLine={false} />
                <YAxis tick={{ fill: '#9ca3af', fontSize: 12 }} axisLine={false} tickLine={false} />
                <RechartsTooltip
                  contentStyle={{ backgroundColor: '#1f2937', border: '1px solid #374151', borderRadius: '4px', color: '#fff' }}
                  itemStyle={{ color: '#fff' }}
                />
                <Area type="monotone" dataKey="rezervasyon" stroke="#8b5cf6" strokeWidth={3} fillOpacity={1} fill="url(#colorRez)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Revenue Trend Chart */}
        <div className="bg-surface rounded-md border border-divider overflow-hidden p-6">
          <h2 className="text-sm font-bold text-text-primary mb-4 uppercase tracking-wider">Gelir Özeti (Tahmini)</h2>
          <div className="h-72 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={revenueData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="rgba(255,255,255,0.1)" />
                <XAxis dataKey="name" tick={{ fill: '#9ca3af', fontSize: 12 }} axisLine={false} tickLine={false} />
                <YAxis tick={{ fill: '#9ca3af', fontSize: 12 }} axisLine={false} tickLine={false} />
                <RechartsTooltip
                  cursor={{ fill: 'rgba(255,255,255,0.05)' }}
                  contentStyle={{ backgroundColor: '#1f2937', border: '1px solid #374151', borderRadius: '4px', color: '#fff' }}
                  itemStyle={{ color: '#fff' }}
                  formatter={(value) => [`₺${value}`, 'Gelir']}
                />
                <Bar dataKey="gelir" fill="#10b981" radius={[2, 2, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      <div className="bg-surface rounded-md border border-divider overflow-hidden">
        <div className="p-4 border-b border-divider">
          <h2 className="text-sm font-bold text-text-primary uppercase tracking-wider">Son Kayıt Olan Restoranlar</h2>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead>
              <tr className="bg-background/50 border-b border-divider">
                <th className="py-3 px-6 text-xs font-semibold text-text-secondary uppercase">Restoran Adı</th>
                <th className="py-3 px-6 text-xs font-semibold text-text-secondary uppercase">Kayıt Tarihi</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-divider">
              {recentActivities.length === 0 ? (
                <tr>
                  <td colSpan={2} className="py-8 text-center text-text-secondary">Henüz aktivite yok.</td>
                </tr>
              ) : (
                recentActivities.map((act) => (
                  <tr key={act.id} className="hover:bg-background/30 transition-colors">
                    <td className="py-4 px-6 text-sm font-medium text-text-primary">{act.name}</td>
                    <td className="py-4 px-6 text-sm text-text-secondary">
                      {new Date(act.created_at).toLocaleString("tr-TR")}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
