"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";
import { CircleDollarSign, TrendingUp, CreditCard, Activity, Eye, X, Info } from "lucide-react";

export default function FinancesPage() {
  const [stats, setStats] = useState({
    totalRevenue: 0,
    monthlyRevenue: 0,
    totalTransactions: 0,
  });
  const [transactions, setTransactions] = useState<any[]>([]);
  const [selectedTransaction, setSelectedTransaction] = useState<any | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchFinances = async () => {
      setLoading(true);
      
      const { data: resData, error: resError } = await supabase
        .from("reservations")
        .select("id, reservation_date, start_time, created_at, status, restaurant_id, user_id, guest_name, allergies, dietary_preferences, chronic_diseases")
        .in("status", ["confirmed", "completed"])
        .order("created_at", { ascending: false });

      if (resError) {
        console.error("Error fetching finances:", resError);
        alert(`Veri çekilirken hata: ${resError.message}`);
      }

      if (resData) {
        const totalRev = resData.length * 500;
        
        const currentMonth = new Date().getMonth();
        const monthlyData = resData.filter((d) => new Date(d.created_at).getMonth() === currentMonth);
        const monthlyRev = monthlyData.length * 500;

        setStats({
          totalRevenue: totalRev,
          monthlyRevenue: monthlyRev,
          totalTransactions: resData.length,
        });

        // Fetch related restaurants
        const restaurantIds = Array.from(new Set(resData.map((r: any) => r.restaurant_id).filter(Boolean)));
        let restaurantsMap: Record<string, string> = {};
        if (restaurantIds.length > 0) {
          const { data: restData } = await supabase.from("restaurants").select("id, name").in("id", restaurantIds);
          if (restData) {
            restaurantsMap = Object.fromEntries(restData.map((r: any) => [r.id, r.name]));
          }
        }

        // Fetch related users
        const userIds = Array.from(new Set(resData.map((r: any) => r.user_id).filter(Boolean)));
        let usersMap: Record<string, string> = {};
        if (userIds.length > 0) {
          const { data: userData } = await supabase.from("users").select("id, full_name").in("id", userIds);
          if (userData) {
            usersMap = Object.fromEntries(userData.map((u: any) => [u.id, u.full_name]));
          }
        }

        // Mock işlemler
        const formattedTx = resData.slice(0, 50).map((res: any) => ({
          id: res.id,
          amount: 500,
          date: res.reservation_date || res.created_at,
          restaurant: restaurantsMap[res.restaurant_id] || "Bilinmeyen Restoran",
          user: usersMap[res.user_id] || "Bilinmeyen Kullanıcı",
          guest_name: res.guest_name,
          allergies: res.allergies,
          dietary_preferences: res.dietary_preferences,
          chronic_diseases: res.chronic_diseases,
        }));
        setTransactions(formattedTx);
      }
      setLoading(false);
    };

    fetchFinances();
  }, []);

  if (loading) {
    return <div className="p-8 text-text-secondary">Finans verileri yükleniyor...</div>;
  }

  return (
    <div className="p-8 max-w-7xl mx-auto">
      <div className="mb-8 flex items-center gap-3">
        <CircleDollarSign className="w-8 h-8 text-success" />
        <div>
          <h1 className="text-2xl font-bold text-text-primary">Finans ve Gelirler</h1>
          <p className="text-text-secondary mt-1">Sistem geneli varsayımsal gelir ve işlem özetleri</p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div className="bg-surface rounded-md p-5 border border-divider shadow-sm flex items-center justify-between">
          <div>
            <p className="text-xs font-bold text-text-secondary uppercase tracking-wider">Toplam Sistem Geliri (Tahmini)</p>
            <p className="text-2xl font-bold text-success mt-2">₺{stats.totalRevenue.toLocaleString("tr-TR")}</p>
          </div>
          <div className="w-10 h-10 rounded-md bg-success/10 flex items-center justify-center">
            <TrendingUp className="w-5 h-5 text-success" />
          </div>
        </div>

        <div className="bg-surface rounded-md p-5 border border-divider shadow-sm flex items-center justify-between">
          <div>
            <p className="text-xs font-bold text-text-secondary uppercase tracking-wider">Bu Ayki Gelir</p>
            <p className="text-2xl font-bold text-primary mt-2">₺{stats.monthlyRevenue.toLocaleString("tr-TR")}</p>
          </div>
          <div className="w-10 h-10 rounded-md bg-primary/10 flex items-center justify-center">
            <Activity className="w-5 h-5 text-primary" />
          </div>
        </div>

        <div className="bg-surface rounded-md p-5 border border-divider shadow-sm flex items-center justify-between">
          <div>
            <p className="text-xs font-bold text-text-secondary uppercase tracking-wider">Başarılı İşlem</p>
            <p className="text-2xl font-bold text-text-primary mt-2">{stats.totalTransactions}</p>
          </div>
          <div className="w-10 h-10 rounded-md bg-background border border-divider flex items-center justify-center">
            <CreditCard className="w-5 h-5 text-text-secondary" />
          </div>
        </div>
      </div>

      {/* İşlem Geçmişi Tablosu */}
      <div className="bg-surface rounded-md border border-divider overflow-hidden">
        <div className="p-4 border-b border-divider flex justify-between items-center bg-background/50">
          <h2 className="text-sm font-bold text-text-primary uppercase tracking-wider">Son İşlemler (Örneklem)</h2>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead>
              <tr className="bg-background/50 border-b border-divider">
                <th className="py-3 px-6 text-xs font-semibold text-text-secondary uppercase">İşlem ID</th>
                <th className="py-3 px-6 text-xs font-semibold text-text-secondary uppercase">Restoran</th>
                <th className="py-3 px-6 text-xs font-semibold text-text-secondary uppercase">Müşteri</th>
                <th className="py-3 px-6 text-xs font-semibold text-text-secondary uppercase text-right">Tutar</th>
                <th className="py-3 px-6 text-xs font-semibold text-text-secondary uppercase text-right">Tarih</th>
                <th className="py-3 px-6 text-xs font-semibold text-text-secondary uppercase text-right">İşlem</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-divider">
              {transactions.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-8 text-center text-text-secondary">Herhangi bir işlem bulunamadı.</td>
                </tr>
              ) : (
                transactions.map((tx) => (
                  <tr key={tx.id} className="hover:bg-background/30 transition-colors">
                    <td className="py-4 px-6 text-sm text-text-secondary font-mono">{tx.id.substring(0, 8)}...</td>
                    <td className="py-4 px-6 text-sm font-medium text-text-primary">{tx.restaurant}</td>
                    <td className="py-4 px-6 text-sm text-text-secondary">
                      <div className="flex flex-col">
                        <span className="font-medium text-text-primary">{tx.user}</span>
                        {tx.guest_name && tx.guest_name !== tx.user && (
                          <span className="text-xs text-text-secondary">Misafir: {tx.guest_name}</span>
                        )}
                      </div>
                    </td>
                    <td className="py-4 px-6 text-sm font-bold text-success text-right">+₺{tx.amount}</td>
                    <td className="py-4 px-6 text-sm text-text-secondary text-right">
                      {new Date(tx.date).toLocaleString("tr-TR", { dateStyle: "short", timeStyle: "short" })}
                    </td>
                    <td className="py-4 px-6 text-right">
                      <button
                        onClick={() => setSelectedTransaction(tx)}
                        className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm font-medium text-text-secondary hover:bg-background transition-colors border border-divider"
                      >
                        <Eye className="w-4 h-4" />
                        Detay
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Transaction Anamnesis Modal */}
      {selectedTransaction && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
          <div className="bg-surface border border-divider rounded-md w-full max-w-2xl overflow-hidden flex flex-col max-h-[90vh]">
            <div className="flex items-center justify-between p-4 border-b border-divider bg-background/50">
              <h2 className="text-sm font-bold text-text-primary uppercase tracking-wider flex items-center gap-2">
                <Info className="w-4 h-4 text-primary" />
                İşlem Detayları
              </h2>
              <button 
                onClick={() => setSelectedTransaction(null)}
                className="text-text-secondary hover:text-text-primary p-1 rounded hover:bg-divider transition-colors"
              >
                <X className="w-4 h-4" />
              </button>
            </div>
            
            <div className="p-6 overflow-y-auto flex-1 space-y-6">
              <div>
                <h3 className="text-sm font-bold text-text-primary mb-1">
                  İşlem No: {selectedTransaction.id}
                </h3>
                <div className="flex gap-2 mt-2">
                  <div className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-background border border-divider text-text-secondary">
                    {new Date(selectedTransaction.date).toLocaleString("tr-TR")}
                  </div>
                  <div className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-background border border-divider text-text-secondary">
                    Tutar: ₺{selectedTransaction.amount}
                  </div>
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <h4 className="text-xs font-bold text-text-secondary uppercase tracking-wider mb-2">Müşteri Bilgileri</h4>
                  <div className="bg-background p-4 rounded-md border border-divider space-y-4">
                    <div>
                      <span className="text-xs font-bold text-text-secondary block mb-1">Rezervasyon Sahibi</span>
                      <p className="text-sm text-text-primary font-medium">{selectedTransaction.user}</p>
                    </div>
                    {selectedTransaction.guest_name && (
                      <div>
                        <span className="text-xs font-bold text-text-secondary block mb-1">Misafir</span>
                        <p className="text-sm text-text-primary">{selectedTransaction.guest_name}</p>
                      </div>
                    )}
                  </div>
                </div>

                <div>
                  <h4 className="text-xs font-bold text-text-secondary uppercase tracking-wider mb-2">Sağlık & Beslenme</h4>
                  <div className="bg-background p-4 rounded-md border border-divider space-y-4 h-full">
                    <div>
                      <span className="text-xs font-bold text-text-secondary block mb-1">Alerjiler</span>
                      <p className="text-sm text-text-primary bg-error/5 p-2 rounded-sm border border-error/10">
                        {selectedTransaction.allergies || "Belirtilmedi"}
                      </p>
                    </div>
                    <div>
                      <span className="text-xs font-bold text-text-secondary block mb-1">Diyet Tercihleri</span>
                      <p className="text-sm text-text-primary bg-primary/5 p-2 rounded-sm border border-primary/10">
                        {selectedTransaction.dietary_preferences || "Belirtilmedi"}
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div className="p-4 border-t border-divider bg-background/50 flex justify-end gap-3">
              <button
                onClick={() => setSelectedTransaction(null)}
                className="px-4 py-2 rounded-md text-sm font-bold text-text-primary bg-surface border border-divider hover:bg-background transition-colors"
              >
                Kapat
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
