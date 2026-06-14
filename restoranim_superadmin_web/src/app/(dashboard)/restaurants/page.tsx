"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";
import { Check, X, Search, Store, Eye, Info, MapPin, Phone, Mail, ChefHat, Clock, Star, Users, Calendar, MessageSquare, ChevronRight } from "lucide-react";

type Restaurant = {
  id: string;
  name: string;
  description: string | null;
  chef_name: string | null;
  chef_details: string | null;
  service_hours: any;
  facilities: any;
  is_verified: boolean;
  is_sponsored?: boolean;
  created_at: string;
  owner_name: string | null;
  tax_number: string | null;
  address: string | null;
  phone_number: string | null;
  email: string | null;
};

type RestaurantActivity = {
  id: string;
  type: "reservation" | "review";
  date: string;
  user_name: string;
  details: string;
  rating?: number;
};

export default function RestaurantsPage() {
  const [restaurants, setRestaurants] = useState<Restaurant[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedRestaurant, setSelectedRestaurant] = useState<Restaurant | null>(null);
  const [activeTab, setActiveTab] = useState<"pending" | "verified">("pending");
  
  // Stream data
  const [activities, setActivities] = useState<RestaurantActivity[]>([]);
  const [loadingActivities, setLoadingActivities] = useState(false);
  const [stats, setStats] = useState({ totalRes: 0, totalRev: 0, avgRating: 0 });

  const fetchRestaurants = async () => {
    setLoading(true);
    const { data, error } = await supabase
      .from("restaurants")
      .select("id, name, description, chef_name, chef_details, service_hours, facilities, is_verified, is_sponsored, created_at, owner_name, tax_number, address, phone_number, email")
      .order("created_at", { ascending: false });

    if (!error && data) {
      setRestaurants(data);
      if (data.length > 0 && !selectedRestaurant) {
        setSelectedRestaurant(data[0]);
      }
    }
    setLoading(false);
  };

  useEffect(() => {
    fetchRestaurants();
  }, []);

  useEffect(() => {
    const fetchActivities = async () => {
      if (!selectedRestaurant) return;
      setLoadingActivities(true);
      
      const [resData, revData] = await Promise.all([
        supabase.from("reservations").select("id, created_at, guest_name, guest_count, status, users(full_name)").eq("restaurant_id", selectedRestaurant.id).order("created_at", { ascending: false }).limit(10),
        supabase.from("reviews").select("id, created_at, rating, comment, users(full_name)").eq("restaurant_id", selectedRestaurant.id).order("created_at", { ascending: false }).limit(10)
      ]);

      let combined: RestaurantActivity[] = [];
      let totRes = 0;
      let totRev = 0;
      let sumRating = 0;

      if (resData.data) {
        totRes = resData.data.length; // Approximate for demo
        const { count } = await supabase.from("reservations").select("*", { count: "exact", head: true }).eq("restaurant_id", selectedRestaurant.id);
        totRes = count || resData.data.length;

        resData.data.forEach((r: any) => {
          combined.push({
            id: `res-${r.id}`,
            type: "reservation",
            date: r.created_at,
            user_name: r.users?.full_name || r.guest_name || "Bilinmeyen Kullanıcı",
            details: `${r.guest_count} kişilik rezervasyon (${r.status})`
          });
        });
      }

      if (revData.data) {
        const { count } = await supabase.from("reviews").select("*", { count: "exact", head: true }).eq("restaurant_id", selectedRestaurant.id);
        totRev = count || revData.data.length;
        
        revData.data.forEach((r: any) => {
          sumRating += r.rating;
          combined.push({
            id: `rev-${r.id}`,
            type: "review",
            date: r.created_at,
            user_name: r.users?.full_name || "Bilinmeyen Kullanıcı",
            details: r.comment || "Yorum metni yok",
            rating: r.rating
          });
        });
      }

      combined.sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());

      setActivities(combined);
      setStats({
        totalRes: totRes,
        totalRev: totRev,
        avgRating: totRev > 0 ? Number((sumRating / revData.data!.length).toFixed(1)) : 0
      });
      setLoadingActivities(false);
    };

    fetchActivities();
  }, [selectedRestaurant?.id]);

  const toggleVerification = async (id: string, currentStatus: boolean) => {
    const { error } = await supabase
      .from("restaurants")
      .update({ is_verified: !currentStatus })
      .eq("id", id);

    if (!error) {
      setRestaurants((prev) =>
        prev.map((r) =>
          r.id === id ? { ...r, is_verified: !currentStatus } : r
        )
      );
      if (selectedRestaurant?.id === id) {
        setSelectedRestaurant({ ...selectedRestaurant, is_verified: !currentStatus });
      }
    } else {
      alert("Durum güncellenirken bir hata oluştu.");
    }
  };

  const toggleSponsorship = async (id: string, currentStatus: boolean) => {
    const { error } = await supabase
      .from("restaurants")
      .update({ is_sponsored: !currentStatus })
      .eq("id", id);

    if (!error) {
      setRestaurants((prev) =>
        prev.map((r) =>
          r.id === id ? { ...r, is_sponsored: !currentStatus } : r
        )
      );
      if (selectedRestaurant?.id === id) {
        setSelectedRestaurant({ ...selectedRestaurant, is_sponsored: !currentStatus });
      }
    } else {
      alert("Sponsorluk durumu güncellenirken bir hata oluştu.");
    }
  };

  const filteredRestaurants = restaurants.filter((r) => {
    const matchesSearch = r.name.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesTab = activeTab === "pending" ? !r.is_verified : r.is_verified;
    return matchesSearch && matchesTab;
  });

  return (
    <div className="p-4 md:p-8 max-w-[1600px] mx-auto h-[calc(100vh-4rem)] flex flex-col">
      <div className="mb-6 shrink-0">
        <h1 className="text-2xl font-bold text-text-primary flex items-center gap-2">
          <Store className="w-7 h-7 text-primary" />
          Restoran Yönetimi & Bilgi Akışı
        </h1>
        <p className="text-text-secondary mt-1">Restoranları onaylayın, detayları inceleyin ve canlı işlem akışlarını takip edin.</p>
      </div>

      <div className="flex flex-col lg:flex-row gap-6 flex-1 min-h-0">
        
        {/* SOL PANEL: Restoran Listesi */}
        <div className="w-full lg:w-1/3 xl:w-1/4 flex flex-col bg-surface rounded-md border border-divider shadow-sm overflow-hidden shrink-0">
          <div className="p-3 border-b border-divider bg-background/50 shrink-0">
            <div className="relative w-full">
              <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <Search className="h-4 w-4 text-text-secondary" />
              </div>
              <input
                type="text"
                placeholder="Restoran ara..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-10 pr-3 py-2 bg-surface border border-divider rounded-md focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary text-sm shadow-sm transition-shadow"
              />
            </div>
            
            <div className="flex mt-3 border border-divider rounded-md p-1 bg-surface">
              <button
                onClick={() => setActiveTab("pending")}
                className={`flex-1 py-1.5 text-xs font-bold rounded-sm transition-all ${
                  activeTab === "pending"
                    ? "bg-warning/10 text-warning shadow-sm"
                    : "text-text-secondary hover:bg-background"
                }`}
              >
                Onay Bekleyenler
              </button>
              <button
                onClick={() => setActiveTab("verified")}
                className={`flex-1 py-1.5 text-xs font-bold rounded-sm transition-all ${
                  activeTab === "verified"
                    ? "bg-success/10 text-success shadow-sm"
                    : "text-text-secondary hover:bg-background"
                }`}
              >
                Onaylılar
              </button>
            </div>
          </div>
          
          <div className="flex-1 overflow-y-auto p-2 space-y-1">
            {loading ? (
              <div className="text-center py-8 text-text-secondary text-sm">Yükleniyor...</div>
            ) : filteredRestaurants.length === 0 ? (
              <div className="text-center py-8 text-text-secondary text-sm">Kayıt bulunamadı.</div>
            ) : (
              filteredRestaurants.map((restaurant) => (
                <button
                  key={restaurant.id}
                  onClick={() => setSelectedRestaurant(restaurant)}
                  className={`w-full text-left p-3 rounded-md border transition-all duration-200 group ${
                    selectedRestaurant?.id === restaurant.id 
                      ? 'bg-primary/5 border-primary shadow-sm' 
                      : 'bg-background border-divider hover:border-primary/50 hover:bg-surface'
                  }`}
                >
                  <div className="flex justify-between items-start mb-2">
                    <h3 className={`font-bold truncate pr-2 ${selectedRestaurant?.id === restaurant.id ? 'text-primary' : 'text-text-primary'}`}>
                      {restaurant.name}
                    </h3>
                    <span className={`shrink-0 inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider ${
                      restaurant.is_verified ? 'bg-success/10 text-success' : 'bg-warning/10 text-warning'
                    }`}>
                      {restaurant.is_verified ? 'Onaylı' : 'Bekliyor'}
                    </span>
                  </div>
                  <div className="flex items-center gap-4 text-xs text-text-secondary">
                    <span className="flex items-center gap-1 truncate"><MapPin className="w-3 h-3 shrink-0"/> {restaurant.address ? restaurant.address.split(',')[0] : 'Bilinmiyor'}</span>
                  </div>
                </button>
              ))
            )}
          </div>
        </div>

        {/* SAĞ PANEL: Restoran Detay & Bilgi Akışı */}
        <div className="w-full lg:w-2/3 xl:w-3/4 flex flex-col bg-surface rounded-md border border-divider shadow-sm overflow-hidden flex-1 min-h-0">
          {selectedRestaurant ? (
            <div className="flex flex-col h-full">
              {/* Header */}
              <div className="p-4 md:p-6 border-b border-divider bg-background/30 shrink-0 flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div>
                  <div className="flex items-center gap-3 mb-1">
                    <h2 className="text-2xl font-bold text-text-primary">{selectedRestaurant.name}</h2>
                    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold uppercase tracking-wider ${
                      selectedRestaurant.is_verified ? 'bg-success/10 text-success' : 'bg-warning/10 text-warning'
                    }`}>
                      {selectedRestaurant.is_verified ? 'Sistemde Onaylı' : 'Onay Bekliyor'}
                    </span>
                  </div>
                  <div className="text-sm text-text-secondary flex items-center gap-2">
                    <Clock className="w-4 h-4" /> Sisteme Kayıt: {new Date(selectedRestaurant.created_at).toLocaleDateString("tr-TR")}
                  </div>
                </div>
                
                <div className="flex items-center gap-3 shrink-0">
                  <button
                    onClick={() => toggleSponsorship(selectedRestaurant.id, selectedRestaurant.is_sponsored || false)}
                    className={`shrink-0 flex items-center gap-2 px-4 py-2 rounded-md text-sm font-bold shadow-sm transition-all ${
                      selectedRestaurant.is_sponsored 
                        ? "bg-amber-100 text-amber-700 border border-amber-300 hover:bg-amber-200" 
                        : "bg-surface border border-divider text-text-primary hover:bg-background"
                    }`}
                  >
                    <Star className={`w-4 h-4 ${selectedRestaurant.is_sponsored ? "fill-amber-500 text-amber-500" : ""}`} /> 
                    {selectedRestaurant.is_sponsored ? 'Sponsorluğu Kaldır' : 'Öne Çıkar'}
                  </button>

                  <button
                    onClick={() => toggleVerification(selectedRestaurant.id, selectedRestaurant.is_verified)}
                    className={`shrink-0 flex items-center gap-2 px-4 py-2 rounded-md text-sm font-bold shadow-sm transition-all ${
                      selectedRestaurant.is_verified 
                        ? "bg-surface border border-divider text-error hover:bg-error/10" 
                        : "bg-success text-white border border-success hover:bg-success/90 shadow-success/20"
                    }`}
                  >
                    {selectedRestaurant.is_verified ? (
                      <><X className="w-4 h-4" /> Onayı İptal Et</>
                    ) : (
                      <><Check className="w-4 h-4" /> Restoranı Onayla</>
                    )}
                  </button>
                </div>
              </div>

              {/* Scrollable Content */}
              <div className="flex-1 overflow-y-auto p-4 md:p-6 flex flex-col xl:flex-row gap-6">
                
                {/* Sol Taraf: Statik Bilgiler (Anamnez) */}
                <div className="flex-1 space-y-6">
                  
                  <div className="grid grid-cols-3 gap-4">
                    <div className="bg-background rounded-md p-3 border border-divider">
                      <div className="text-text-secondary text-[10px] font-bold uppercase tracking-wider mb-1">Puanı</div>
                      <div className="text-xl font-bold text-warning flex items-center gap-1">{stats.avgRating > 0 ? stats.avgRating : '-'} <Star className="w-4 h-4 fill-warning"/></div>
                    </div>
                    <div className="bg-background rounded-md p-3 border border-divider">
                      <div className="text-text-secondary text-[10px] font-bold uppercase tracking-wider mb-1">Rezervasyon</div>
                      <div className="text-xl font-bold text-text-primary">{stats.totalRes}</div>
                    </div>
                    <div className="bg-background rounded-md p-3 border border-divider">
                      <div className="text-text-secondary text-[10px] font-bold uppercase tracking-wider mb-1">Yorum</div>
                      <div className="text-xl font-bold text-text-primary">{stats.totalRev}</div>
                    </div>
                  </div>

                  <div>
                    <h3 className="text-xs font-bold text-text-secondary uppercase tracking-wider mb-2 flex items-center gap-2">
                      <Info className="w-4 h-4 text-primary"/> Konsept & Detay
                    </h3>
                    <div className="bg-background rounded-md p-4 border border-divider text-sm text-text-primary leading-relaxed">
                      {selectedRestaurant.description || "Bu restoran için henüz bir açıklama veya konsept detayı girilmemiş."}
                    </div>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                      <h3 className="text-xs font-bold text-text-secondary uppercase tracking-wider mb-2 flex items-center gap-2">
                        <Store className="w-4 h-4 text-primary"/> Kurumsal
                      </h3>
                      <div className="bg-background rounded-md p-4 border border-divider space-y-3">
                        <div>
                          <div className="text-[10px] uppercase font-bold text-text-secondary mb-1">İşletmeci / Şirket</div>
                          <div className="font-medium text-sm">{selectedRestaurant.owner_name || "-"}</div>
                        </div>
                        <div>
                          <div className="text-[10px] uppercase font-bold text-text-secondary mb-1">Vergi No</div>
                          <div className="font-medium text-sm font-mono">{selectedRestaurant.tax_number || "-"}</div>
                        </div>
                        <div className="pt-2 border-t border-divider">
                          <div className="text-[10px] uppercase font-bold text-text-secondary mb-2">İletişim & Konum</div>
                          <div className="space-y-2 text-sm">
                            <div className="flex items-center gap-2"><Phone className="w-4 h-4 text-text-secondary"/> {selectedRestaurant.phone_number || "-"}</div>
                            <div className="flex items-center gap-2"><Mail className="w-4 h-4 text-text-secondary"/> {selectedRestaurant.email || "-"}</div>
                            <div className="flex items-start gap-2 mt-2"><MapPin className="w-4 h-4 text-text-secondary shrink-0 mt-0.5"/> <span className="leading-tight">{selectedRestaurant.address || "-"}</span></div>
                          </div>
                        </div>
                      </div>
                    </div>

                    <div className="space-y-6">
                      <div>
                        <h3 className="text-xs font-bold text-text-secondary uppercase tracking-wider mb-2 flex items-center gap-2">
                          <ChefHat className="w-4 h-4 text-primary"/> Şef Bilgileri
                        </h3>
                        <div className="bg-background rounded-md p-4 border border-divider space-y-2">
                          <div className="font-bold text-text-primary">{selectedRestaurant.chef_name || "Belirtilmemiş"}</div>
                          {selectedRestaurant.chef_details && (
                            <div className="text-sm text-text-secondary leading-relaxed border-l-2 border-primary/30 pl-3">
                              {selectedRestaurant.chef_details}
                            </div>
                          )}
                        </div>
                      </div>

                      <div>
                        <h3 className="text-xs font-bold text-text-secondary uppercase tracking-wider mb-2 flex items-center gap-2">
                          <Clock className="w-4 h-4 text-primary"/> Servis & Olanaklar
                        </h3>
                        <div className="bg-background rounded-md p-4 border border-divider">
                          <div className="flex justify-between items-center text-sm border-b border-divider pb-2 mb-2">
                            <span className="text-text-secondary">Öğle Servisi</span>
                            <span className="font-medium">{selectedRestaurant.service_hours?.lunch_start || "-"} - {selectedRestaurant.service_hours?.lunch_end || "-"}</span>
                          </div>
                          <div className="flex justify-between items-center text-sm border-b border-divider pb-2 mb-2">
                            <span className="text-text-secondary">Akşam Servisi</span>
                            <span className="font-medium">{selectedRestaurant.service_hours?.dinner_start || "-"} - {selectedRestaurant.service_hours?.dinner_end || "-"}</span>
                          </div>
                          <div className="flex flex-wrap gap-2 pt-1">
                            {selectedRestaurant.facilities?.valet && <span className="px-2 py-1 bg-primary/10 text-primary text-[10px] rounded uppercase font-bold tracking-wider">Vale Hizmeti</span>}
                            {selectedRestaurant.facilities?.tasting_menu && <span className="px-2 py-1 bg-primary/10 text-primary text-[10px] rounded uppercase font-bold tracking-wider">Tadım Menüsü</span>}
                            {!selectedRestaurant.facilities?.valet && !selectedRestaurant.facilities?.tasting_menu && <span className="text-sm text-text-secondary">Ekstra olanak belirtilmemiş.</span>}
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Sağ Taraf: Canlı Bilgi Akışı (Stream) */}
                <div className="xl:w-80 flex flex-col shrink-0">
                  <h3 className="text-xs font-bold text-text-secondary uppercase tracking-wider mb-3 flex items-center gap-2">
                    <Activity className="w-4 h-4 text-primary" /> Son Etkileşimler
                  </h3>
                  
                  <div className="bg-background rounded-md border border-divider p-1 overflow-hidden flex-1 relative">
                    {loadingActivities ? (
                      <div className="absolute inset-0 flex items-center justify-center">
                        <div className="w-6 h-6 border-2 border-primary border-t-transparent rounded-full animate-spin"></div>
                      </div>
                    ) : activities.length === 0 ? (
                      <div className="p-8 text-center text-text-secondary text-sm italic">
                        Etkileşim bulunmuyor.
                      </div>
                    ) : (
                      <div className="overflow-y-auto max-h-[600px] p-3 space-y-4">
                        {activities.map((act) => (
                          <div key={act.id} className="relative pl-3 border-l-2 border-divider pb-3 last:pb-0">
                            <div className={`absolute w-2 h-2 rounded-full -left-[5px] top-1 ${
                              act.type === 'reservation' ? 'bg-primary' : 'bg-warning'
                            }`}></div>
                            
                            <div className="flex items-center gap-2 mb-1">
                              <span className="text-[10px] font-bold uppercase tracking-wider text-text-secondary">
                                {act.type === 'reservation' ? 'Rezervasyon' : 'Yorum'}
                              </span>
                              <span className="text-[10px] text-text-secondary ml-auto">
                                {new Date(act.date).toLocaleDateString("tr-TR")}
                              </span>
                            </div>
                            
                            <div className="bg-surface p-2.5 rounded-sm border border-divider mt-1 shadow-sm">
                              <div className="font-bold text-xs text-text-primary mb-0.5">{act.user_name}</div>
                              {act.type === 'review' && act.rating && (
                                <div className="text-warning text-[10px] font-bold mb-1">{act.rating} ★</div>
                              )}
                              <p className="text-xs text-text-secondary leading-relaxed">
                                {act.details}
                              </p>
                            </div>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                </div>

              </div>
            </div>
          ) : (
            <div className="h-full flex flex-col items-center justify-center text-text-secondary p-8">
              <Store className="w-16 h-16 text-divider mb-4" />
              <p className="text-lg font-medium">Detayları görmek için sol taraftan bir restoran seçin.</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

// Activity icon for imports
const Activity = ({ className }: { className?: string }) => (
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className={className}>
    <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"></polyline>
  </svg>
);
