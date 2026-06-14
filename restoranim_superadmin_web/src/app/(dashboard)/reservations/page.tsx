"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";
import { CalendarCheck, Search, Eye, X, Info } from "lucide-react";

type Reservation = {
  id: string;
  restaurant_id: string;
  user_id: string;
  reservation_date: string;
  start_time: string;
  guest_count: number;
  status: string;
  created_at: string;
  guest_name?: string | null;
  allergies?: string | null;
  dietary_preferences?: string | null;
  chronic_diseases?: string | null;
  restaurant_name?: string;
  user_name?: string;
};

export default function ReservationsPage() {
  const [reservations, setReservations] = useState<Reservation[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedReservation, setSelectedReservation] = useState<Reservation | null>(null);

  const fetchReservations = async () => {
    setLoading(true);
    
    // First fetch reservations
    let { data: resData, error: resError } = await supabase
      .from("reservations")
      .select("*")
      .order("created_at", { ascending: false });

    if (resError) {
      console.error("Error fetching reservations:", resError);
      setLoading(false);
      return;
    }

    if (resData && resData.length > 0) {
      // Fetch related restaurants
      const restaurantIds = Array.from(new Set(resData.map((r: any) => r.restaurant_id).filter(Boolean)));
      let restaurantsMap: Record<string, string> = {};
      if (restaurantIds.length > 0) {
        const { data: restData } = await supabase
          .from("restaurants")
          .select("id, name")
          .in("id", restaurantIds);
        
        if (restData) {
          restaurantsMap = Object.fromEntries(restData.map((r: any) => [r.id, r.name]));
        }
      }

      // Fetch related users
      const userIds = Array.from(new Set(resData.map((r: any) => r.user_id).filter(Boolean)));
      let usersMap: Record<string, string> = {};
      if (userIds.length > 0) {
        const { data: userData } = await supabase
          .from("users")
          .select("id, full_name")
          .in("id", userIds);
        
        if (userData) {
          usersMap = Object.fromEntries(userData.map((u: any) => [u.id, u.full_name]));
        }
      }

      // Merge data
      const formatted = resData.map((res: any) => ({
        ...res,
        restaurant_name: restaurantsMap[res.restaurant_id] || "Bilinmeyen Restoran",
        user_name: usersMap[res.user_id] || "Bilinmeyen Kullanıcı",
      }));
      setReservations(formatted);
    } else {
      setReservations([]);
    }
    
    setLoading(false);
  };

  useEffect(() => {
    fetchReservations();
  }, []);

  const filtered = reservations.filter((r) => 
    (r.restaurant_name || "").toLowerCase().includes(searchQuery.toLowerCase()) ||
    (r.user_name || "").toLowerCase().includes(searchQuery.toLowerCase()) ||
    (r.guest_name || "").toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="p-8 max-w-6xl mx-auto">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-8">
        <div>
          <h1 className="text-2xl font-bold text-text-primary flex items-center gap-2">
            <CalendarCheck className="w-6 h-6 text-primary" />
            Tüm Rezervasyonlar
          </h1>
          <p className="text-text-secondary mt-1">Sistem üzerindeki tüm restoran rezervasyonları</p>
        </div>

        <div className="relative w-full md:w-72">
          <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
            <Search className="h-4 w-4 text-text-secondary" />
          </div>
          <input
            type="text"
            placeholder="Restoran veya kullanıcı ara..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-10 pr-3 py-2 bg-surface border border-divider rounded-lg focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary text-sm"
          />
        </div>
      </div>

      <div className="bg-surface rounded-xl border border-divider overflow-hidden">
        {loading ? (
          <div className="p-8 text-center text-text-secondary">Yükleniyor...</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-background/50 border-b border-divider">
                  <th className="py-3 px-4 text-xs font-semibold text-text-secondary uppercase tracking-wider">Restoran</th>
                  <th className="py-3 px-4 text-xs font-semibold text-text-secondary uppercase tracking-wider">Kullanıcı (Misafir)</th>
                  <th className="py-3 px-4 text-xs font-semibold text-text-secondary uppercase tracking-wider">Tarih & Saat</th>
                  <th className="py-3 px-4 text-xs font-semibold text-text-secondary uppercase tracking-wider">Kişi</th>
                  <th className="py-3 px-4 text-xs font-semibold text-text-secondary uppercase tracking-wider">Durum</th>
                  <th className="py-3 px-4 text-xs font-semibold text-text-secondary uppercase tracking-wider text-right">İşlem</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-divider">
                {filtered.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="py-8 text-center text-text-secondary">Kayıt bulunamadı.</td>
                  </tr>
                ) : (
                  filtered.map((res) => (
                    <tr key={res.id} className="hover:bg-background/30 transition-colors">
                      <td className="py-3 px-4 text-sm font-medium text-text-primary">
                        {res.restaurant_name}
                      </td>
                      <td className="py-3 px-4 text-sm text-text-secondary">
                        <div className="flex flex-col">
                          <span className="font-medium text-text-primary">{res.user_name}</span>
                          {res.guest_name && res.guest_name !== res.user_name && (
                            <span className="text-xs text-text-secondary">Misafir: {res.guest_name}</span>
                          )}
                        </div>
                      </td>
                      <td className="py-3 px-4 text-sm text-text-secondary">
                        {res.reservation_date ? new Date(res.reservation_date).toLocaleDateString("tr-TR") : "-"} - {res.start_time || "-"}
                      </td>
                      <td className="py-3 px-4 text-sm font-medium text-text-primary">
                        {res.guest_count} Kişi
                      </td>
                      <td className="py-3 px-4">
                        <span
                          className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                            res.status === "confirmed" || res.status === "approved"
                              ? "bg-success/10 text-success"
                              : res.status === "cancelled" || res.status === "rejected"
                              ? "bg-error/10 text-error"
                              : "bg-warning/10 text-warning"
                          }`}
                        >
                          {res.status.toUpperCase()}
                        </span>
                      </td>
                      <td className="py-3 px-4 text-right">
                        <button
                          onClick={() => setSelectedReservation(res)}
                          className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm font-medium text-text-secondary hover:bg-background transition-colors border border-divider"
                        >
                          <Eye className="w-4 h-4" />
                          Anamnez Detayı
                        </button>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Reservation Anamnesis Modal */}
      {selectedReservation && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
          <div className="bg-surface border border-divider rounded-2xl w-full max-w-2xl overflow-hidden flex flex-col max-h-[90vh]">
            <div className="flex items-center justify-between p-6 border-b border-divider">
              <h2 className="text-xl font-bold text-text-primary flex items-center gap-2">
                <Info className="w-5 h-5 text-primary" />
                Rezervasyon Anamnezi
              </h2>
              <button 
                onClick={() => setSelectedReservation(null)}
                className="text-text-secondary hover:text-text-primary p-1 rounded-lg hover:bg-background transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            
            <div className="p-6 overflow-y-auto flex-1 space-y-6">
              <div>
                <h3 className="text-lg font-bold text-text-primary mb-1">
                  {selectedReservation.guest_name || selectedReservation.user_name}
                </h3>
                <div className="flex gap-2">
                  <div className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-background border border-divider text-text-secondary">
                    {selectedReservation.reservation_date ? new Date(selectedReservation.reservation_date).toLocaleDateString("tr-TR") : "-"} - {selectedReservation.start_time || "-"}
                  </div>
                  <div className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-background border border-divider text-text-secondary">
                    {selectedReservation.guest_count} Kişi
                  </div>
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <h4 className="text-sm font-semibold text-text-secondary uppercase tracking-wider mb-2">Sağlık & Beslenme</h4>
                  <div className="bg-background p-4 rounded-xl border border-divider space-y-4">
                    <div>
                      <span className="text-xs font-bold text-text-secondary block mb-1">Alerjiler</span>
                      <p className="text-sm text-text-primary bg-error/5 p-2 rounded border border-error/10">
                        {selectedReservation.allergies || "Belirtilmedi"}
                      </p>
                    </div>
                    <div>
                      <span className="text-xs font-bold text-text-secondary block mb-1">Diyet Tercihleri</span>
                      <p className="text-sm text-text-primary bg-primary/5 p-2 rounded border border-primary/10">
                        {selectedReservation.dietary_preferences || "Belirtilmedi"}
                      </p>
                    </div>
                  </div>
                </div>

                <div>
                  <h4 className="text-sm font-semibold text-text-secondary uppercase tracking-wider mb-2">Tıbbi Geçmiş</h4>
                  <div className="bg-background p-4 rounded-xl border border-divider space-y-4 h-full">
                    <div>
                      <span className="text-xs font-bold text-text-secondary block mb-1">Kronik Rahatsızlıklar</span>
                      <p className="text-sm text-text-primary bg-warning/5 p-2 rounded border border-warning/10">
                        {selectedReservation.chronic_diseases || "Belirtilmedi"}
                      </p>
                    </div>
                    {/* Placeholder for future notes */}
                    <div>
                      <span className="text-xs font-bold text-text-secondary block mb-1">Restoran Notu</span>
                      <p className="text-sm text-text-secondary italic">
                        Henüz not eklenmemiş.
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div className="p-6 border-t border-divider bg-background/50 flex justify-end gap-3">
              <button
                onClick={() => setSelectedReservation(null)}
                className="px-4 py-2 rounded-lg text-sm font-medium text-text-primary bg-surface border border-divider hover:bg-background transition-colors"
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
