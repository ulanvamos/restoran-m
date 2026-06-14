"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";
import { MessageSquare, Trash2, UserX, ShieldAlert, X, MoreVertical, Utensils, Calendar, Mail, Phone, Clock, AlertTriangle, FileText } from "lucide-react";

type Review = {
  id: string;
  user_id: string;
  restaurant_id: string;
  rating: number;
  ambiance_rating: number;
  food_rating: number;
  comment: string;
  created_at: string;
  users: { full_name: string } | null;
  restaurants: { name: string } | null;
  isBanned?: boolean;
};

type UserProfile = {
  id: string;
  email: string | null;
  phone_number: string | null;
  created_at: string;
};

type UserHistory = {
  id: string;
  reservation_date: string;
  guest_count: number;
  restaurants: { name: string } | null;
  dietary_preferences: string | null;
  allergies: string | null;
  chronic_diseases: string | null;
};

type UserPastReview = {
  id: string;
  rating: number;
  comment: string;
  created_at: string;
  restaurants: { name: string } | null;
};

export default function ReviewsPage() {
  const [reviews, setReviews] = useState<Review[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedReview, setSelectedReview] = useState<Review | null>(null);
  const [activeDropdown, setActiveDropdown] = useState<string | null>(null);
  
  // Modal advanced state
  const [userProfile, setUserProfile] = useState<UserProfile | null>(null);
  const [userHistory, setUserHistory] = useState<UserHistory[]>([]);
  const [userPastReviews, setUserPastReviews] = useState<UserPastReview[]>([]);
  const [loadingDetails, setLoadingDetails] = useState(false);

  const fetchReviews = async () => {
    setLoading(true);
    const { data: revData, error: revError } = await supabase
      .from("reviews")
      .select(`
        id, 
        user_id,
        restaurant_id,
        rating, 
        ambiance_rating,
        food_rating,
        comment, 
        created_at,
        users (full_name),
        restaurants (name)
      `)
      .order("created_at", { ascending: false });

    if (!revError && revData) {
      const userIds = Array.from(new Set(revData.map(r => r.user_id).filter(Boolean)));
      let bannedMap: Record<string, boolean> = {};
      if (userIds.length > 0) {
        const { data: userData } = await supabase
          .from("users")
          .select("id, is_banned")
          .in("id", userIds);
        
        if (userData) {
          userData.forEach(u => {
            bannedMap[u.id] = u.is_banned;
          });
        }
      }

      const formatted = revData.map(r => ({
        ...r,
        isBanned: bannedMap[r.user_id] || false
      }));

      setReviews(formatted as Review[]);
    }
    setLoading(false);
  };

  useEffect(() => {
    fetchReviews();
  }, []);

  useEffect(() => {
    const fetchFullDetails = async () => {
      if (!selectedReview) return;
      setLoadingDetails(true);
      setUserProfile(null);
      setUserHistory([]);
      setUserPastReviews([]);
      
      const [userRes, historyRes, reviewsRes] = await Promise.all([
        supabase.from("users").select("id, email, phone_number, created_at").eq("id", selectedReview.user_id).single(),
        supabase.from("reservations").select(`id, reservation_date, guest_count, dietary_preferences, allergies, chronic_diseases, restaurants (name)`).eq("user_id", selectedReview.user_id).order("reservation_date", { ascending: false }).limit(20),
        supabase.from("reviews").select(`id, rating, comment, created_at, restaurants (name)`).eq("user_id", selectedReview.user_id).order("created_at", { ascending: false }).limit(20)
      ]);

      if (userRes.data) setUserProfile(userRes.data);
      if (historyRes.data) setUserHistory(historyRes.data as any);
      if (reviewsRes.data) setUserPastReviews(reviewsRes.data as any);
      
      setLoadingDetails(false);
    };

    fetchFullDetails();
  }, [selectedReview]);

  useEffect(() => {
    const handleClickOutside = () => setActiveDropdown(null);
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const deleteReview = async (id: string, isFromModal = false) => {
    if (!window.confirm("Bu yorumu kalıcı olarak silmek istediğinize emin misiniz?")) return;
    
    const { error } = await supabase.from("reviews").delete().eq("id", id);
    if (!error) {
      setReviews((prev) => prev.filter((r) => r.id !== id));
      if (isFromModal && selectedReview?.id === id) {
        setSelectedReview(null);
      } else if (isFromModal) {
        // If deleting a past review inside the modal, just update the list
        setUserPastReviews(prev => prev.filter(r => r.id !== id));
      }
    } else {
      alert("Yorum silinirken bir hata oluştu.");
    }
    setActiveDropdown(null);
  };

  const banUser = async (userId: string, userName: string) => {
    if (!window.confirm(`DİKKAT: ${userName} adlı kullanıcıyı sistemden süresiz olarak uzaklaştırmak (banlamak) istediğinize emin misiniz?`)) return;

    const { error } = await supabase.from("users").update({ is_banned: true }).eq("id", userId);
    if (!error) {
      setReviews((prev) => prev.map(r => r.user_id === userId ? { ...r, isBanned: true } : r));
      if (selectedReview && selectedReview.user_id === userId) {
        setSelectedReview({ ...selectedReview, isBanned: true });
      }
      alert(`${userName} başarıyla sistemden banlandı.`);
    } else {
      alert("Kullanıcı banlanırken bir hata oluştu.");
    }
    setActiveDropdown(null);
  };

  const renderStars = (rating: number) => {
    return Array.from({ length: 5 }).map((_, i) => (
      <span key={i} className={`text-lg ${i < rating ? 'text-warning' : 'text-divider'}`}>★</span>
    ));
  };

  const toggleDropdown = (e: React.MouseEvent, id: string) => {
    e.preventDefault();
    e.stopPropagation();
    setActiveDropdown(prev => prev === id ? null : id);
  };

  // Extract all unique anamnesis info
  const aggregateAnamnesis = () => {
    const diets = new Set<string>();
    const allergies = new Set<string>();
    const chronic = new Set<string>();

    userHistory.forEach(h => {
      if (h.dietary_preferences) diets.add(h.dietary_preferences);
      if (h.allergies) allergies.add(h.allergies);
      if (h.chronic_diseases) chronic.add(h.chronic_diseases);
    });

    return {
      diets: Array.from(diets),
      allergies: Array.from(allergies),
      chronic: Array.from(chronic)
    };
  };

  const anamnesis = aggregateAnamnesis();

  return (
    <div className="p-8 max-w-7xl mx-auto pb-24">
      <div className="mb-8 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-text-primary flex items-center gap-2">
            <ShieldAlert className="w-7 h-7 text-error" />
            Yorum ve Moderasyon Merkezi
          </h1>
        </div>
      </div>

      <div className="bg-surface rounded-xl border border-divider shadow-sm overflow-visible">
        {loading ? (
          <div className="p-12 flex flex-col items-center justify-center">
            <div className="w-8 h-8 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
            <p className="mt-4 text-text-secondary">Yorumlar yükleniyor...</p>
          </div>
        ) : (
          <div className="overflow-visible">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-background/80 border-b border-divider">
                  <th className="py-4 px-6 text-xs font-semibold text-text-secondary uppercase tracking-wider">Kullanıcı & Restoran</th>
                  <th className="py-4 px-6 text-xs font-semibold text-text-secondary uppercase tracking-wider">Değerlendirmeler</th>
                  <th className="py-4 px-6 text-xs font-semibold text-text-secondary uppercase tracking-wider">Yorum Önizlemesi</th>
                  <th className="py-4 px-6 text-xs font-semibold text-text-secondary uppercase tracking-wider text-right w-16"></th>
                </tr>
              </thead>
              <tbody className="divide-y divide-divider">
                {reviews.length === 0 ? (
                  <tr>
                    <td colSpan={4} className="py-12 text-center text-text-secondary">
                      <MessageSquare className="w-12 h-12 text-divider mx-auto mb-3" />
                      Hiç yorum bulunamadı.
                    </td>
                  </tr>
                ) : (
                  reviews.map((review) => (
                    <tr key={review.id} className="hover:bg-background/40 transition-colors group">
                      <td className="py-4 px-6">
                        <div className="flex flex-col">
                          <div className="flex items-center gap-2">
                            <span className="font-medium text-text-primary">
                              {review.users?.full_name || "Bilinmeyen Kullanıcı"}
                            </span>
                            {review.isBanned && (
                              <span className="px-2 py-0.5 rounded-full bg-error/10 text-error text-[10px] font-bold uppercase tracking-wider">
                                Banlı
                              </span>
                            )}
                          </div>
                          <span className="text-xs text-text-secondary mt-1">
                            {review.restaurants?.name || "Bilinmeyen Restoran"}
                          </span>
                          <span className="text-[10px] text-text-secondary mt-0.5">
                            {new Date(review.created_at).toLocaleDateString("tr-TR")}
                          </span>
                        </div>
                      </td>
                      <td className="py-4 px-6">
                        <div className="flex flex-col gap-1">
                          <div className="flex items-center gap-2 text-sm">
                            <span className="w-16 text-text-secondary">Genel:</span>
                            <div className="flex">{renderStars(review.rating)}</div>
                          </div>
                        </div>
                      </td>
                      <td className="py-4 px-6">
                        <p className="text-sm text-text-secondary line-clamp-2 max-w-sm">
                          {review.comment || <span className="italic">Yorum metni yok</span>}
                        </p>
                        <button 
                          onClick={() => setSelectedReview(review)}
                          className="text-xs text-primary font-medium mt-1 hover:underline opacity-0 group-hover:opacity-100 transition-opacity"
                        >
                          Derinlemesine İncele
                        </button>
                      </td>
                      <td className="py-4 px-6 text-right relative">
                        <button
                          onClick={(e) => toggleDropdown(e, review.id)}
                          className="p-2 rounded-lg text-text-secondary hover:bg-background transition-colors"
                        >
                          <MoreVertical className="w-5 h-5" />
                        </button>
                        
                        {activeDropdown === review.id && (
                          <div 
                            className="absolute right-12 top-0 w-48 bg-surface border border-divider rounded-xl shadow-2xl z-50 py-1 overflow-hidden"
                            onMouseDown={(e) => e.stopPropagation()}
                          >
                            <button
                              onClick={() => deleteReview(review.id)}
                              className="w-full flex items-center gap-2 px-4 py-2.5 text-sm text-error hover:bg-error/10 transition-colors text-left"
                            >
                              <Trash2 className="w-4 h-4" />
                              Yorumu Sil
                            </button>
                            {!review.isBanned && (
                              <button
                                onClick={() => banUser(review.user_id, review.users?.full_name || "Bilinmiyor")}
                                className="w-full flex items-center gap-2 px-4 py-2.5 text-sm text-error hover:bg-error/10 transition-colors text-left border-t border-divider"
                              >
                                <UserX className="w-4 h-4" />
                                Kullanıcıyı Banla
                              </button>
                            )}
                          </div>
                        )}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Advanced Review & User Moderation Panel */}
      {selectedReview && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-background/90 backdrop-blur-md" onMouseDown={(e) => e.stopPropagation()}>
          <div className="bg-surface rounded-2xl w-[95vw] h-[90vh] shadow-2xl border border-divider overflow-hidden flex flex-col">
            
            <div className="flex items-center justify-between p-6 border-b border-divider bg-surface shrink-0">
              <div className="flex items-center gap-4">
                <div className="w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center text-primary font-bold text-xl">
                  {selectedReview.users?.full_name?.charAt(0) || "U"}
                </div>
                <div>
                  <h3 className="text-xl font-bold text-text-primary flex items-center gap-3">
                    {selectedReview.users?.full_name || "Bilinmeyen Kullanıcı"}
                    {selectedReview.isBanned && (
                      <span className="px-3 py-1 rounded-full bg-error/10 text-error text-xs font-bold uppercase tracking-wider">
                        Sistemden Uzaklaştırıldı
                      </span>
                    )}
                  </h3>
                  <div className="text-sm text-text-secondary mt-1">Kullanıcı Moderasyon & İnceleme Paneli</div>
                </div>
              </div>
              <button
                onClick={() => setSelectedReview(null)}
                className="p-3 text-text-secondary hover:text-error hover:bg-error/10 rounded-xl transition-colors"
              >
                <X className="w-6 h-6" />
              </button>
            </div>
            
            <div className="flex-1 overflow-y-auto bg-background p-6">
              {loadingDetails ? (
                <div className="w-full h-full flex items-center justify-center">
                  <div className="flex flex-col items-center">
                    <div className="w-10 h-10 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
                    <p className="mt-4 text-text-secondary">Kullanıcının tüm bilgileri toplanıyor...</p>
                  </div>
                </div>
              ) : (
                <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 h-full">
                  
                  {/* Sol Sütun: Kimlik & Anamnez */}
                  <div className="lg:col-span-3 flex flex-col gap-6">
                    <div className="bg-surface rounded-2xl border border-divider p-5 shadow-sm">
                      <h4 className="font-bold text-text-primary mb-4 flex items-center gap-2 border-b border-divider pb-3">
                        <UserX className="w-5 h-5 text-primary" /> İletişim Bilgileri
                      </h4>
                      <div className="space-y-4">
                        <div className="flex items-start gap-3">
                          <Mail className="w-4 h-4 text-text-secondary mt-0.5" />
                          <div>
                            <div className="text-xs text-text-secondary">E-Posta</div>
                            <div className="text-sm font-medium text-text-primary">{userProfile?.email || "Gizli / Yok"}</div>
                          </div>
                        </div>
                        <div className="flex items-start gap-3">
                          <Phone className="w-4 h-4 text-text-secondary mt-0.5" />
                          <div>
                            <div className="text-xs text-text-secondary">Telefon</div>
                            <div className="text-sm font-medium text-text-primary">{userProfile?.phone_number || "Gizli / Yok"}</div>
                          </div>
                        </div>
                        <div className="flex items-start gap-3">
                          <Clock className="w-4 h-4 text-text-secondary mt-0.5" />
                          <div>
                            <div className="text-xs text-text-secondary">Kayıt Tarihi</div>
                            <div className="text-sm font-medium text-text-primary">{userProfile?.created_at ? new Date(userProfile.created_at).toLocaleDateString("tr-TR") : "-"}</div>
                          </div>
                        </div>
                      </div>
                    </div>

                    <div className="bg-surface rounded-2xl border border-divider p-5 shadow-sm flex-1">
                      <h4 className="font-bold text-text-primary mb-4 flex items-center gap-2 border-b border-divider pb-3">
                        <AlertTriangle className="w-5 h-5 text-warning" /> Sağlık & Anamnez Özeti
                      </h4>
                      <div className="text-xs text-text-secondary mb-4">Sistemdeki tüm rezervasyonlarından toplanan beslenme ve sağlık bildirimleri:</div>
                      
                      <div className="space-y-4">
                        <div>
                          <div className="text-xs font-semibold text-text-secondary mb-1">Alerjiler</div>
                          {anamnesis.allergies.length > 0 ? (
                            <div className="flex flex-wrap gap-2">
                              {anamnesis.allergies.map(a => <span key={a} className="px-2 py-1 bg-error/10 text-error text-xs rounded font-medium">{a}</span>)}
                            </div>
                          ) : <div className="text-xs text-text-secondary italic">Kayıtlı alerji yok.</div>}
                        </div>

                        <div>
                          <div className="text-xs font-semibold text-text-secondary mb-1">Diyet Tercihleri</div>
                          {anamnesis.diets.length > 0 ? (
                            <div className="flex flex-wrap gap-2">
                              {anamnesis.diets.map(a => <span key={a} className="px-2 py-1 bg-success/10 text-success text-xs rounded font-medium">{a}</span>)}
                            </div>
                          ) : <div className="text-xs text-text-secondary italic">Kayıtlı diyet tercihi yok.</div>}
                        </div>

                        <div>
                          <div className="text-xs font-semibold text-text-secondary mb-1">Kronik Rahatsızlıklar</div>
                          {anamnesis.chronic.length > 0 ? (
                            <div className="flex flex-wrap gap-2">
                              {anamnesis.chronic.map(a => <span key={a} className="px-2 py-1 bg-warning/10 text-warning text-xs rounded font-medium">{a}</span>)}
                            </div>
                          ) : <div className="text-xs text-text-secondary italic">Kayıtlı rahatsızlık yok.</div>}
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* Orta Sütun: Şikayet Konusu Olan / İncelenen Yorum */}
                  <div className="lg:col-span-4 flex flex-col gap-6">
                    <div className="bg-error/5 border border-error/20 rounded-2xl p-6 shadow-sm flex-1 flex flex-col relative overflow-hidden">
                      <div className="absolute -right-4 -top-4 text-error/10">
                        <MessageSquare className="w-32 h-32" />
                      </div>
                      <h4 className="font-bold text-error mb-4 flex items-center gap-2">
                        <ShieldAlert className="w-5 h-5" /> İncelenen Yorum Özeti
                      </h4>
                      <div className="bg-surface rounded-xl p-5 border border-error/20 shadow-sm relative z-10">
                        <div className="flex justify-between items-start mb-4">
                          <div>
                            <div className="font-bold text-text-primary text-lg">{selectedReview.restaurants?.name || "Bilinmeyen Restoran"}</div>
                            <div className="text-sm text-text-secondary">{new Date(selectedReview.created_at).toLocaleString("tr-TR")}</div>
                          </div>
                          <div className="text-2xl font-bold text-warning drop-shadow-sm">
                            {selectedReview.rating} ★
                          </div>
                        </div>
                        <div className="bg-background rounded-lg p-4 text-text-primary whitespace-pre-wrap border border-divider">
                          {selectedReview.comment || <span className="italic text-text-secondary">Metin yok.</span>}
                        </div>
                        <div className="flex gap-4 mt-4 text-sm">
                          {selectedReview.food_rating && (
                            <div><span className="text-text-secondary">Lezzet:</span> <span className="font-bold">{selectedReview.food_rating}★</span></div>
                          )}
                          {selectedReview.ambiance_rating && (
                            <div><span className="text-text-secondary">Ambiyans:</span> <span className="font-bold">{selectedReview.ambiance_rating}★</span></div>
                          )}
                        </div>
                      </div>

                      <div className="mt-auto pt-6 flex flex-col gap-3 relative z-10">
                        <button
                          onClick={() => deleteReview(selectedReview.id, true)}
                          className="w-full py-3 rounded-xl border border-error text-error font-bold hover:bg-error hover:text-white transition-all text-center"
                        >
                          Bu Yorumu Kalıcı Sil
                        </button>
                        {!selectedReview.isBanned && (
                          <button
                            onClick={() => banUser(selectedReview.user_id, selectedReview.users?.full_name || "Bilinmiyor")}
                            className="w-full py-3 rounded-xl bg-error text-white font-bold shadow-lg shadow-error/20 hover:bg-error/90 transition-all text-center"
                          >
                            Kullanıcıyı Platformdan Banla
                          </button>
                        )}
                      </div>
                    </div>
                  </div>

                  {/* Sağ Sütun: Geçmiş Etkileşimler */}
                  <div className="lg:col-span-5 flex flex-col gap-6">
                    <div className="bg-surface rounded-2xl border border-divider shadow-sm flex-1 flex flex-col overflow-hidden">
                      <div className="p-5 border-b border-divider flex items-center gap-2">
                        <FileText className="w-5 h-5 text-primary" /> 
                        <h4 className="font-bold text-text-primary">Tüm Platform Geçmişi</h4>
                      </div>
                      
                      <div className="flex-1 overflow-y-auto p-5 space-y-8">
                        {/* Diğer Yorumlar */}
                        <div>
                          <h5 className="text-sm font-bold text-text-secondary uppercase mb-3 flex items-center gap-2">
                            <MessageSquare className="w-4 h-4" /> Yazdığı Diğer Yorumlar
                          </h5>
                          {userPastReviews.filter(r => r.id !== selectedReview.id).length === 0 ? (
                            <div className="text-sm text-text-secondary bg-background p-4 rounded-xl border border-divider text-center italic">
                              Başka yorumu bulunmuyor.
                            </div>
                          ) : (
                            <div className="space-y-3">
                              {userPastReviews.filter(r => r.id !== selectedReview.id).map(review => (
                                <div key={review.id} className="bg-background p-4 rounded-xl border border-divider relative group">
                                  <div className="flex justify-between items-start mb-2">
                                    <div className="font-semibold text-sm text-text-primary">{review.restaurants?.name}</div>
                                    <div className="text-warning text-sm font-bold">{review.rating} ★</div>
                                  </div>
                                  <p className="text-xs text-text-secondary line-clamp-2">{review.comment || "Metin yok"}</p>
                                  <div className="text-[10px] text-text-secondary mt-2 text-right">{new Date(review.created_at).toLocaleDateString("tr-TR")}</div>
                                  <button onClick={() => deleteReview(review.id, true)} className="absolute top-2 right-2 p-1.5 bg-surface text-error rounded-md opacity-0 group-hover:opacity-100 transition-opacity border border-divider hover:bg-error/10" title="Yorumu Sil"><Trash2 className="w-3 h-3"/></button>
                                </div>
                              ))}
                            </div>
                          )}
                        </div>

                        {/* Ziyaretler */}
                        <div>
                          <h5 className="text-sm font-bold text-text-secondary uppercase mb-3 flex items-center gap-2">
                            <Utensils className="w-4 h-4" /> Ziyaret Ettiği Restoranlar
                          </h5>
                          {userHistory.length === 0 ? (
                            <div className="text-sm text-text-secondary bg-background p-4 rounded-xl border border-divider text-center italic">
                              Geçmiş rezervasyon kaydı yok.
                            </div>
                          ) : (
                            <div className="bg-background rounded-xl border border-divider p-1">
                              {userHistory.map((hist, idx) => (
                                <div key={hist.id} className="p-3 border-b border-divider last:border-0 hover:bg-surface transition-colors flex justify-between items-center">
                                  <div>
                                    <div className="font-semibold text-sm text-text-primary">{hist.restaurants?.name || "Bilinmeyen Restoran"}</div>
                                    <div className="text-xs text-text-secondary mt-0.5 flex gap-2">
                                      <span>{hist.reservation_date ? new Date(hist.reservation_date).toLocaleDateString("tr-TR") : "-"}</span>
                                      <span>•</span>
                                      <span>{hist.guest_count} Kişi</span>
                                    </div>
                                  </div>
                                </div>
                              ))}
                            </div>
                          )}
                        </div>
                      </div>

                    </div>
                  </div>

                </div>
              )}
            </div>

          </div>
        </div>
      )}
    </div>
  );
}
