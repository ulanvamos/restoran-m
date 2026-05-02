# LuxeDine (Restoranım) - High-End Fine Dining Uygulaması

Bu proje, üst düzey (fine dining) restoranlar için tasarlanmış, lüks kullanıcı deneyimini (UX) ön planda tutan bir dijital rezervasyon ve restoran içi operasyon (Phygital) uygulamasıdır. Hem iOS hem de Android için tek bir kod tabanından (Flutter) derlenmektedir.

## 📱 Proje Özeti
Müşteriler, bu uygulama üzerinden yüksek çözünürlüklü görsellerle restoranı keşfedebilir, masa/saat bazlı rezervasyon yapabilir ve ön sipariş verebilirler. Restorana geldiklerinde ise masadaki QR kodu okutarak "Restorandayım" modülüne giriş yaparlar. Bu modül üzerinden dijital garson çağırma, canlı hesap takibi ve masa başında ödeme işlemleri gerçekleştirilebilir.

## 🛠 Teknoloji Yığını (Tech Stack)

### 1. Frontend (İstemci)
- **Framework:** Flutter (Dart)
- **State Management (Durum Yönetimi):** Riverpod (`flutter_riverpod`)
- **Mimari:** Clean Architecture (Feature-first modüler klasör yapısı)
- **UI/UX Kütüphaneleri:** 
  - `flutter_animate` (Zarif animasyonlar ve geçişler için)
  - `google_fonts` (Inter ve Manrope lüks tipografi için)
  - `shimmer` (Yükleme iskeletleri için)
  - `cached_network_image` (Yüksek çözünürlüklü görsellerin önbelleklenmesi için)

### 2. Backend (Sunucu & Veritabanı)
- **BaaS (Backend as a Service):** Supabase
- **Veritabanı:** PostgreSQL (İlişkisel şema, RLS politikaları ile üst düzey güvenlik)
- **Kimlik Doğrulama:** Supabase Auth (E-posta, Google, Apple)
- **Gerçek Zamanlı İletişim:** Supabase Realtime (Garson çağırma ve sipariş durumları için)
- **Serverless Fonksiyonlar:** Supabase Edge Functions (Iyzico/Stripe ödeme entegrasyonu ve FCM bildirimleri için)

## 📁 Klasör Yapısı (Clean Architecture)

```text
lib/
├── core/                       # Proje genelinde kullanılan ortak yapılar
│   ├── constants/              # Renkler, Fontlar, API Keyler
│   ├── network/                # Supabase ve HTTP istemcileri
│   ├── theme/                  # Uygulama genel tema ayarları (Material 3)
│   └── utils/                  # Yardımcı fonksiyonlar (Tarih formatlama vb.)
├── features/                   # Modüler özellikler (Her feature kendi içinde bağımsızdır)
│   ├── splash/                 # Açılış (Splash) ekranı modülü
│   ├── auth/                   # Kimlik doğrulama modülü
│   ├── discover/               # Restoran ve menü keşfi
│   ├── reservation/            # Masa ve saat rezervasyonu
│   └── in_restaurant/          # QR menü, garson çağırma ve canlı hesap
└── main.dart                   # Uygulama giriş noktası (Riverpod ProviderScope)
```

## 🔐 Güvenlik ve İş Kuralları
- **Row Level Security (RLS):** Supabase üzerinde, kullanıcıların sadece kendi rezervasyonlarını ve verilerini görmesini sağlayan sıkı RLS politikaları yazılmıştır.
- **Conflict Prevention (Çifte Rezervasyon Koruması):** PostgreSQL'in Range Types ve `EXCLUDE` kısıtlamaları kullanılarak, bir masanın aynı saat diliminde iki farklı kullanıcıya rezerve edilmesi veritabanı seviyesinde tamamen engellenmiştir.

## 🚀 Çalıştırma Talimatları

1. Gerekli bağımlılıkları indirin:
   ```bash
   flutter pub get
   ```
2. Uygulamayı başlatın (Android, iOS veya Web):
   ```bash
   flutter run
   ```
   *(Not: Windows masaüstü derlemesinde MSBuild kaynaklı uzun dosya yolu hataları alabilirsiniz. Eğer C++ derleme hataları çıkarsa, testleri `flutter run -d chrome` ile web üzerinde veya doğrudan bir Android Emülatörü üzerinde yapmanız tavsiye edilir.)*

## 🗺 Geliştirme Yol Haritası (Roadmap)
- **Faz 1:** Proje iskeleti, tema, Splash ekranı ve Supabase entegrasyonu (Tamamlandı).
- **Faz 2:** Giriş (Auth) ekranları ve Restoran Keşif (Discover) modülü.
- **Faz 3:** Rezervasyon akışı ve Ön Sipariş sistemi.
- **Faz 4:** Masadaki QR ile eşleşme ve Canlı Garson (Realtime) sistemi.
- **Faz 5:** Ödeme (Edge Functions) ve Canlıya Alım.
