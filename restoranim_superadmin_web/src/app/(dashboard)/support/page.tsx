"use client";

import { useEffect, useState, useRef } from "react";
import { supabase } from "@/lib/supabase";
import { Headset, Send, User, CheckCircle } from "lucide-react";

type Ticket = {
  id: string;
  user_id: string;
  status: string;
  created_at: string;
  profiles?: { full_name: string } | null;
};

type Message = {
  id: string;
  ticket_id: string;
  sender_id: string;
  message: string;
  created_at: string;
};

export default function SupportPage() {
  const [tickets, setTickets] = useState<Ticket[]>([]);
  const [selectedTicket, setSelectedTicket] = useState<Ticket | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [inputText, setInputText] = useState("");
  const [loading, setLoading] = useState(true);
  const [currentUser, setCurrentUser] = useState<any>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  useEffect(() => {
    supabase.auth.getUser().then(({ data }) => setCurrentUser(data.user));
    fetchTickets();
  }, []);

  const fetchTickets = async () => {
    setLoading(true);
    let { data, error } = await supabase
      .from("support_tickets")
      .select("*")
      .order("created_at", { ascending: false });

    if (error) {
      console.error("Error fetching tickets:", error);
    } else if (data && data.length > 0) {
      // Fetch profiles manually using 'users' table
      const userIds = Array.from(new Set(data.map((t: any) => t.user_id).filter(Boolean)));
      if (userIds.length > 0) {
        const profilesRes = await supabase
          .from("users")
          .select("id, full_name")
          .in("id", userIds);
        
        if (profilesRes.data) {
          const profilesMap = Object.fromEntries(
            profilesRes.data.map((p: any) => [p.id, p])
          );
          data = data.map((t: any) => ({
            ...t,
            profiles: profilesMap[t.user_id] ? { full_name: profilesMap[t.user_id].full_name } : null
          }));
        }
      }
    }

    if (data) setTickets(data as any);
    setLoading(false);
  };

  // Subscribe to tickets table (for new tickets or status updates)
  useEffect(() => {
    const ticketChannel = supabase
      .channel("public:support_tickets")
      .on(
        "postgres_changes",
        { event: "*", schema: "public", table: "support_tickets" },
        (payload) => {
          if (payload.eventType === "INSERT") {
            const newTicket = payload.new as Ticket;
            setTickets((prev) => {
              if (prev.some((t) => t.id === newTicket.id)) return prev;
              return [newTicket, ...prev];
            });
            // Fetch name for new ticket
            if (newTicket.user_id) {
              supabase.from("users").select("full_name").eq("id", newTicket.user_id).single()
                .then(({ data }) => {
                  if (data) {
                    setTickets((prev) => 
                      prev.map(t => t.id === newTicket.id ? { ...t, profiles: { full_name: data.full_name } } : t)
                    );
                  }
                });
            }
          } else if (payload.eventType === "UPDATE") {
            const updatedTicket = payload.new as Ticket;
            setTickets((prev) => 
              prev.map(t => t.id === updatedTicket.id ? { ...t, status: updatedTicket.status } : t)
            );
            if (selectedTicket?.id === updatedTicket.id) {
              setSelectedTicket(prev => prev ? { ...prev, status: updatedTicket.status } : prev);
            }
          }
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(ticketChannel);
    };
  }, [selectedTicket]);

  // Messages subscription for the selected ticket
  useEffect(() => {
    let messageChannel: any = null;

    if (selectedTicket) {
      const fetchMessages = async () => {
        const { data } = await supabase
          .from("support_messages")
          .select("*")
          .eq("ticket_id", selectedTicket.id)
          .order("created_at", { ascending: true });
        
        if (data) {
          setMessages(data);
          setTimeout(scrollToBottom, 150);
        }
      };

      fetchMessages();

      messageChannel = supabase
        .channel(`messages_${selectedTicket.id}`)
        .on(
          "postgres_changes",
          {
            event: "INSERT",
            schema: "public",
            table: "support_messages",
            filter: `ticket_id=eq.${selectedTicket.id}`,
          },
          (payload) => {
            setMessages((prev) => {
              // prevent duplicate
              if (prev.some(m => m.id === payload.new.id)) return prev;
              return [...prev, payload.new as Message];
            });
            setTimeout(scrollToBottom, 150);
          }
        )
        .subscribe();
    }

    return () => {
      if (messageChannel) supabase.removeChannel(messageChannel);
    };
  }, [selectedTicket]);

  const sendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!inputText.trim() || !selectedTicket || !currentUser) return;

    const text = inputText;
    setInputText("");

    // Optimistic UI update can be done here, but since it's realtime, let's just wait for DB
    await supabase.from("support_messages").insert({
      ticket_id: selectedTicket.id,
      sender_id: currentUser.id,
      message: text,
    });
    
    // Smooth scroll again just in case
    scrollToBottom();
  };

  const resolveTicket = async () => {
    if (!selectedTicket) return;
    const { error } = await supabase
      .from("support_tickets")
      .update({ status: "resolved" })
      .eq("id", selectedTicket.id);
      
    if (error) {
      console.error("Error resolving ticket:", error);
      alert("Talep kapatılırken hata oluştu.");
    }
  };

  return (
    <div className="flex h-[calc(100vh-64px)] overflow-hidden">
      {/* Left Pane - Tickets */}
      <div className="w-80 border-r border-divider bg-surface flex flex-col h-full shrink-0">
        <div className="p-4 border-b border-divider bg-background/50">
          <h2 className="text-lg font-bold text-text-primary flex items-center gap-2">
            <Headset className="w-5 h-5 text-primary" />
            Destek Talepleri
          </h2>
        </div>
        
        <div className="flex-1 overflow-y-auto">
          {loading ? (
            <div className="p-4 text-center text-text-secondary text-sm">Yükleniyor...</div>
          ) : tickets.length === 0 ? (
            <div className="p-4 text-center text-text-secondary text-sm">Talep bulunamadı.</div>
          ) : (
            <div className="divide-y divide-divider">
              {tickets.map((ticket) => (
                <button
                  key={ticket.id}
                  onClick={() => setSelectedTicket(ticket)}
                  className={`w-full text-left p-4 transition-colors ${
                    selectedTicket?.id === ticket.id
                      ? "bg-primary/10"
                      : "hover:bg-background"
                  }`}
                >
                  <div className="flex justify-between items-start mb-1">
                    <span className="font-semibold text-text-primary truncate max-w-[150px]">
                      {ticket.profiles?.full_name || "Bilinmeyen Kullanıcı"}
                    </span>
                    <span className="text-xs text-text-secondary whitespace-nowrap ml-2">
                      {new Date(ticket.created_at).toLocaleTimeString("tr-TR", { hour: "2-digit", minute: "2-digit" })}
                    </span>
                  </div>
                  <div className="text-xs text-text-secondary flex justify-between items-center mt-2">
                    <span>Talep No: {ticket.id.substring(0, 5)}</span>
                    <span className={`px-2 py-0.5 rounded-md ${
                      ticket.status === "open" ? "bg-success/10 text-success" : "bg-text-secondary/10 text-text-secondary"
                    }`}>
                      {ticket.status === "open" ? "Açık" : "Kapalı"}
                    </span>
                  </div>
                </button>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Right Pane - Chat */}
      <div className="flex-1 flex flex-col bg-background h-full">
        {selectedTicket ? (
          <>
            {/* Chat Header */}
            <div className="h-16 border-b border-divider bg-surface flex items-center justify-between px-6 shrink-0">
              <div className="flex items-center">
                <div className="w-9 h-9 rounded-full bg-primary/10 flex items-center justify-center mr-3">
                  <User className="w-5 h-5 text-primary" />
                </div>
                <div>
                  <div className="font-semibold text-text-primary">
                    {selectedTicket.profiles?.full_name || "Kullanıcı"}
                  </div>
                  <div className="text-xs text-text-secondary">Talep ID: {selectedTicket.id}</div>
                </div>
              </div>
              
              {selectedTicket.status !== "resolved" && selectedTicket.status !== "closed" && (
                <button 
                  onClick={resolveTicket}
                  className="flex items-center gap-2 px-4 py-2 bg-error/10 text-error text-sm font-medium rounded-lg hover:bg-error/20 transition-colors"
                >
                  <CheckCircle className="w-4 h-4" />
                  Talebi Kapat
                </button>
              )}
            </div>

            {/* Messages */}
            <div className="flex-1 overflow-y-auto p-6 space-y-4">
              {messages.length === 0 ? (
                <div className="h-full flex items-center justify-center text-text-secondary text-sm">
                  Henüz mesaj yok.
                </div>
              ) : (
                messages.map((msg) => {
                  const isMe = msg.sender_id === currentUser?.id;
                  return (
                    <div key={msg.id} className={`flex ${isMe ? "justify-end" : "justify-start"}`}>
                      <div
                        className={`max-w-[70%] rounded-2xl px-4 py-2.5 shadow-sm ${
                          isMe
                            ? "bg-primary text-white rounded-br-none"
                            : "bg-surface border border-divider text-text-primary rounded-bl-none"
                        }`}
                      >
                        <div className="text-sm whitespace-pre-wrap">{msg.message}</div>
                        <div className={`text-[10px] mt-1 text-right ${isMe ? "text-white/70" : "text-text-secondary"}`}>
                          {new Date(msg.created_at).toLocaleTimeString("tr-TR", { hour: "2-digit", minute: "2-digit" })}
                        </div>
                      </div>
                    </div>
                  );
                })
              )}
              <div ref={messagesEndRef} className="h-1" />
            </div>

            {/* Input */}
            <div className="p-4 bg-surface border-t border-divider shrink-0">
              {selectedTicket.status === "resolved" || selectedTicket.status === "closed" ? (
                <div className="text-center py-2 text-sm text-text-secondary bg-background rounded-lg border border-divider">
                  Bu talep kapatıldığı için yeni mesaj gönderilemez.
                </div>
              ) : (
                <form onSubmit={sendMessage} className="flex gap-3">
                  <input
                    type="text"
                    value={inputText}
                    onChange={(e) => setInputText(e.target.value)}
                    placeholder="Mesajınızı yazın..."
                    className="flex-1 bg-background border border-divider rounded-full px-5 py-3 focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary text-sm shadow-inner"
                  />
                  <button
                    type="submit"
                    disabled={!inputText.trim()}
                    className="w-12 h-12 rounded-full bg-primary text-white flex items-center justify-center disabled:opacity-50 transition-opacity shadow-md hover:shadow-lg"
                  >
                    <Send className="w-5 h-5 -ml-1" />
                  </button>
                </form>
              )}
            </div>
          </>
        ) : (
          <div className="flex-1 flex flex-col items-center justify-center text-text-secondary bg-background">
            <div className="w-20 h-20 rounded-full bg-surface border border-divider flex items-center justify-center mb-4 shadow-sm">
              <Headset className="w-10 h-10 text-divider" />
            </div>
            <p className="text-lg font-medium text-text-primary">Destek Masası</p>
            <p className="text-sm mt-1">Görüntülemek için sol taraftan bir talep seçin</p>
          </div>
        )}
      </div>
    </div>
  );
}
