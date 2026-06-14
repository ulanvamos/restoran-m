# Sistem Mimarisi, Entegre Teknolojiler ve Otonom Yapay Zeka Destekli Geliştirme Süreci

"Restoranım" projesi; Endüstri Mühendisliği disiplininin temel odak noktalarından olan operasyonel verimlilik, süreç optimizasyonu ve veri odaklı karar alma mekanizmalarını dijital bir ekosisteme taşımak amacıyla geliştirilmiştir. Yüksek performans, ölçeklenebilirlik ve kesintisiz kullanıcı deneyimi (UX) gereksinimlerini karşılamak üzere sistem mühendisliği (systems engineering) prensipleriyle karmaşık bir dağıtık sistem (distributed system) mimarisi halinde tasarlanmıştır. Bu bağlamda proje; çoklu platform destekli istemciler (mobil ve web arayüzleri), reaktif durum yönetimi, bulut tabanlı sunucusuz (serverless) veritabanı altyapısı ve geliştirme döngüsünü uçtan uca otonom olarak optimize eden yapay zeka ajanlarının (Agentic AI) entegre çalıştığı hibrit bir teknoloji yığınına sahiptir. Geliştirilen bu sistem, bir restoranın sipariş, rezervasyon ve kaynak (masa/personel) yönetimi süreçlerindeki darboğazları (bottlenecks) tespit edip en aza indirmeyi hedefleyen Endüstri Mühendisliği vizyonunun yazılım mühendisliği pratikleriyle birleştiği modern bir vaka çalışmasıdır.

---

# 1. Bölüm: İstemci (Frontend) Katmanı ve Arayüz Mimarisi

Sistemin kullanıcılarla etkileşime giren ön yüzü (frontend), tek bir kod tabanından natif (native) makine koduna derlenebilen ve saniyede 60-120 kare (fps) arayüz çizimi yapabilen **Flutter** framework'ü ile **Dart** programlama dili kullanılarak geliştirilmiştir. 

Yazılımın yaşam döngüsünü uzatmak, bakımını (maintenance) kolaylaştırmak ve modülerliği artırmak amacıyla, Bağımlılıkların Tersine Çevrilmesi (Dependency Inversion) prensibine dayanan **Clean Architecture** (Temiz Mimari) benimsenmiştir. Bu bağlamda proje yapısı sunum (presentation), iş mantığı (domain) ve veri (data) katmanlarına kesin çizgilerle ayrılmış; her bir modül ("Feature-first" yaklaşımıyla) kendi içinde bağımsız bir yapıya kavuşturulmuştur.

## 1.1. Reaktif Durum Yönetimi: Riverpod
Uygulama içerisindeki asenkron veri akışlarının (API istekleri, veritabanı dinlemeleri), bellek yönetiminin ve kullanıcı arayüzü durumlarının (state) yönetimi için, modern ve derleme zamanı (compile-time) güvenliğine sahip **Riverpod** kütüphanesi entegre edilmiştir.

* **Bellek Optimizasyonu (Memory Leak Önleme):** Riverpod, klasik durum yönetimi çözümlerinin aksine global değişkenlerin yaratabileceği bellek sızıntılarını önler. 
* **Gereksiz Çizimlerin (Widget Rebuild) Engellenmesi:** Sadece verisi değişen bileşenlerin yeniden çizilmesi sağlanarak cihaz işlemcisi (CPU) üzerindeki yük minimize edilmiştir.
* **AsyncNotifier ve StreamProvider:** Özellikle "Canlı Destek" gibi modüllerde anlık soket bağlantılarının arayüze yansıması için `StreamProvider` kullanılırken, karmaşık iş kuralları içeren "Günlük Analiz" panosundaki veri hesaplamaları (doluluk oranları, ortalama harcamalar) asenkron veriyi önbellekleyerek (caching) sunan `AsyncNotifierProvider` ile yönetilmiştir.

---

# 2. Bölüm: Sunucu (Backend) Altyapısı ve Veritabanı Yönetimi

Projenin arka plan (backend) ve veritabanı mimarisi, geleneksel monolitik sunucular yerine bulut tabanlı, ölçeklenebilir ve sunucusuz (serverless) bir Backend-as-a-Service (BaaS) platformu olan **Supabase** üzerine inşa edilmiştir. Temel veritabanı motoru olarak **PostgreSQL** kullanılmıştır.

## 2.1. İlişkisel Veritabanı Bütünlüğü
Veritabanı tablolarında (örneğin; `users`, `reservations`, `orders`, `tables`) veri güvenilirliğini garantilemek adına katı Yabancı Anahtar (Foreign Key) ilişkileri, kısıtlamalar (Constraints) ve benzersiz tanımlayıcılar (UUIDv4) kullanılmıştır. 

## 2.2. PL/pgSQL Fonksiyonları ve Veritabanı Tetikleyicileri (Triggers)
Sistemde asenkron iş yükünü istemcilerden (client) alıp veritabanı katmanına taşımak için güçlü bir otonom yapı oluşturulmuştur. Özel PL/pgSQL (Procedural Language/PostgreSQL) fonksiyonları ve trigger mekanizmaları kullanılmıştır.
* **Örnek Senaryo:** Sisteme yeni bir rezervasyon eklendiğinde, `reservations` tablosuna bağlı bir `AFTER INSERT` (ekleme sonrası) tetikleyicisi (`trigger_new_reservation`) anında devreye girer. Bu tetikleyici arka planda `notify_new_reservation()` adlı bir prosedürü çalıştırarak, otonom bir şekilde yöneticilere gönderilecek bildirim paketini (`guest_count` ve `start_time` gibi değerleri birleştirerek) oluşturup `notifications` tablosuna kaydeder.

## 2.3. Supabase Realtime (WebSockets)
Sisteme entegre edilen "Canlı Destek", sipariş hazırlık süreçlerinin takibi ve dijital garson çağrı sistemleri, standart HTTP (REST) mimarisi yerine çift yönlü (bidirectional) **WebSocket** protokolünü kullanan **Supabase Realtime** altyapısına geçirilmiştir. Tablolardaki herhangi bir mutasyon (INSERT, UPDATE, DELETE), milisaniyeler içinde doğrudan istemci arayüzündeki Riverpod akışlarına (Stream) aktarılmaktadır.

## 2.4. Storage (Bulut Depolama) ve Bucket Mantığı
Restoranın görsel medyaları (yemek fotoğrafları, menüler) ve kullanıcı profil resimleri (Avatar) gibi ikili (Binary/BLOB) devasa veriler, ilişkisel veritabanında saklanmak yerine **Supabase Storage** üzerindeki **Bucket**'larda (Depolama Kovaları) organize edilmiştir. 
Bucket mimarisinde, dosyaların MIME tiplerine göre doğrulanması sağlanır ve statik dosyalar küresel İçerik Dağıtım Ağları (CDN) uç (edge) sunucularında önbelleklenerek, son kullanıcıya en düşük gecikmeyle (low-latency) sunulur.

---

# 3. Bölüm: Güvenlik ve Kimlik Doğrulama (Auth & RLS)

Sistemin yetkilendirme altyapısında **Supabase Auth** entegre edilmiş ve JSON Web Token (JWT) temelli oturum (session) yönetimi kullanılmıştır.

**Satır Bazlı Güvenlik (Row Level Security - RLS):**
Veritabanı güvenliği uygulama katmanında değil, doğrudan veritabanı motoru katmanında çözülmüştür. RLS politikaları sayesinde, sunucuya gelen her SQL sorgusu otomatik olarak oturum açmış kullanıcının JWT bilgisindeki `auth.uid()` parametresi ile eşleştirilir. Bu bağlamda bir müşteri, sorgu nasıl yazılırsa yazılsın, veritabanı seviyesindeki kısıtlamalardan ötürü başka bir müşterinin rezervasyonuna teknik olarak erişemez veya değişiklik yapamaz.

---

# 4. Bölüm: Otonom Yapay Zeka Entegrasyonları ve Geliştirme İş Akışı (Agentic AI)

"Restoranım" projesini klasik mobil/web projelerinden ayıran en temel unsur; yazılım geliştirme döngüsünün (SDLC) neredeyse tamamının birbiriyle doğrudan haberleşebilen yapay zeka ajanları (Agentic AI) tarafından otonom olarak yönlendirilmiş olmasıdır.

### Üretken Tasarım (Generative UI) ve Antigravity IDE
Müşteri deneyimi (UX) ve kullanıcı arayüzü (UI) tasarımları ilk aşamada **Google Stitch AI** teknolojisi kullanılarak üretken yapay zekaya (Generative AI) yaptırılmıştır. Çıkan prototipler ve kod bileşenleri, Google'ın gelişmiş Otonom Yapay Zeka destekli geliştirme ortamı olan **Antigravity IDE**'ye aktarılmış; yapay zeka ajanları bu tasarımları çözümleyerek soyut sözdizimi ağaçlarını (AST - Abstract Syntax Tree) oluşturmuş ve doğrudan Flutter kodlarına entegre etmiştir.

### Supabase MCP (Model Context Protocol) ile Veritabanı Yönetimi
Yapay zeka asistanının veritabanı şemalarını çözümleyebilmesi için projeye **Supabase MCP (Model Context Protocol)** eklentisi tanımlanmıştır. 
Bu teknoloji sayesinde yapay zeka; PostgreSQL şemalarını (`information_schema`) tarayabilmiş, trigger'lardaki (tetikleyiciler) veya kolonlardaki uyuşmazlıkları (örneğin eksik bir `guest_name` kolonu) saptayabilmiştir. Tespit edilen uyuşmazlıklar için gerekli `ALTER TABLE` veya PL/pgSQL fonksiyon güncellemeleri yapay zeka yardımıyla üretilmiş, böylece veritabanı güncellemeleri ve PostgREST önbelleklerinin (`NOTIFY pgrst, 'reload schema'`) temizlenmesi süreci hızlandırılmıştır.

### Bağlam İndeksleme: Fallow ve MemPalace MCP
Next.js (TypeScript) ile yazılmış Süper Admin paneli ve Flutter (Dart) ile yazılmış müşteri istemcilerinden oluşan geniş ve çok dilli kod tabanında (codebase), LLM (Büyük Dil Modelleri) ajanlarının bağlamı (context window) kaybetmemesi kritik bir problemdir.
Bu sorunu çözmek için **Fallow** ve **MemPalace MCP** araçları kullanılmıştır:
* **Fallow:** Kod tabanını soyut sözdizimi ağaçları (AST) düzeyinde analiz ederek anlamsal bir indeks (semantic index) çıkarır ve farklı dillerdeki dosyalar arası bağımlılıkların takip edilmesini kolaylaştırır.
* **MemPalace MCP:** Oturumlar arası silinmeyen bir **Anlamsal Bilgi Grafiği (Semantic Knowledge Graph)** inşa eder. Bu "kalıcı hafıza (persistent memory)" yapısı sayesinde, veritabanı şemasındaki iş mantığı (business logic) ve arayüz entegrasyonları arasındaki bağ kopmadan sürdürülebilmiştir.

---

# 5. Bölüm: Açık Kaynak Harita ve Konumlandırma
Prototip aşamasında mekanın fiziksel konumu, yol tarifi ve şube tespiti gibi fonksiyonlar için maliyetleri düşürmek adına, kapalı ve ücretli harita API'leri yerine **OpenStreetMap** servisi kullanılmıştır. Flutter üzerinde `flutter_map` ve uzamsal hesaplamalar yapan (iki nokta arası uzaklık ölçümü, projeksiyon hesaplamaları vb.) `latlong2` kütüphanesi tercih edilmiştir.

---

# 6. Bölüm: CI/CD Süreçleri ve Dağıtım (Deployment) Mimarisi
Projenin derleme ve canlı ortama alınma süreçleri modern DevOps pratiklerine uygun olarak otomatikleştirilmiştir. 
* **GitHub Actions:** Mobil uygulamaların (iOS ve Android) derlenme süreçleri GitHub Actions ile kurulan CI/CD boru hatları (pipeline) üzerinden yürütülmüştür. Bu sayede kod tabanına yapılan güncellemeler bulut üzerinde otomatik olarak derlenerek test edilebilir paketlere (APK/AAB ve IPA) dönüştürülmüştür.
* **Vercel:** Next.js kullanılarak geliştirilen Süper Admin Paneli, yüksek erişilebilirlik (high availability) ve sunucusuz (serverless) altyapı avantajları nedeniyle **Vercel** platformuna dağıtılmıştır (deploy). Vercel'in sağladığı kenar (edge) ağı sayesinde admin panelinin dünya çapındaki yüklenme süreleri optimize edilmiştir.

---

# 7. Bölüm: Endüstri Mühendisliği Perspektifinden Değer Önerisi ve Sistem Optimizasyonu

Endüstri Mühendisliği disiplini temelde insan, malzeme, bilgi ve makineden oluşan sistemlerin tasarımını, iyileştirilmesini ve optimizasyonunu hedefler. Geliştirilen "Restoranım" projesi de salt bir yazılım uygulaması olmanın ötesinde, bir işletmenin tüm operasyonel süreçlerini iyileştiren dijital bir sistem tasarımı olarak kurgulanmıştır.

* **Kapasite Planlama ve Kaynak Ataması (Capacity & Resource Planning):** Sistemin sağladığı merkezi rezervasyon ve sipariş veritabanı, ileriye dönük kapasite tahminleri yapmayı mümkün kılar. Restoranın hangi saat dilimlerinde tam kapasiteye ulaşacağının önceden analiz edilmesi, iş gücü kaynağının (garson, mutfak ekibi) optimum seviyede planlanmasını sağlayarak boş bekleme maliyetlerini düşürür ve personel eksikliğinden kaynaklanabilecek müşteri memnuniyetsizliğini önler.
* **Kuyruk Teorisi (Queueing Theory) ve Bekleme Sürelerinin Azaltılması:** Sipariş aşaması ve servis süreçleri, hizmet sektöründeki en kritik darboğazları (bottlenecks) oluşturur. WebSocket tabanlı anlık "Canlı Destek" ve "Dijital Garson" özellikleri, işlem sürelerini (service time) minimize ederek kuyrukların uzamasını engeller. Bu durum, sirkülasyon hızını (throughput) artırır ve restoran verimliliğini maksimize eder.
* **Veri Odaklı Karar Alma ve Yalın Yönetim (Data-Driven Decision Making):** Günlük Analiz panelinde sunulan 'Doluluk Oranı', 'Ortalama Sepet Tutarı' ve 'Yoğun Saat Dağılımı' gibi metrikler, Endüstri Mühendisliğinde kullanılan Temel Performans Göstergelerinin (KPI) dijital ortamdaki karşılığıdır. İşletme yönetimi bu veriler ışığında Sürekli İyileştirme (Kaizen) prensiplerini uygulayabilir ve talebi önceden tahmin ederek gıda israfını (waste) minimize eden Yalın Yönetim stratejileri geliştirebilir.
* **İş Akışı Standardizasyonu:** Geliştirilen Çoklu İstemci (Multi-Client) mimarisi sayesinde mutfak, garson ve müşteri arasındaki bilgi akışındaki gecikmeler ortadan kaldırılarak sistem asimetrisi çözülmüş ve standart bir operasyonel iş akışı oluşturulmuştur.

---

# 8. Bölüm: Sonuç
"Restoranım" projesi; Clean Architecture prensipleriyle ölçeklenmiş Flutter istemcisi, WebSocket (Realtime) ve RLS mimarileriyle güçlendirilmiş Supabase PostgreSQL sunucu katmanı, otonom yapay zeka protokolleri (MCP, Fallow) ve Endüstri Mühendisliği optimizasyon prensiplerinin (Kapasite Planlama, Kuyruk Teorisi, Veri Analitiği) birleşimiyle hayata geçirilmiş modern bir vizyon projesidir.
