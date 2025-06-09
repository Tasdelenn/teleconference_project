# VoidAgent Telekonferans Sistemi

Bu proje çoklu cihazlardan (mobil telefonlar, sunucular ve Linux/Raspberry Pi cihazlar) katılabilen bir telekonferans sistemi geliştirmek amacıyla kurulmuş bir yapay zeka projesidir. Proje adı `voidagent`'tir. Kodlama `Rust` ve `Flutter` dilleriyle eş zamanlı yapılmaktadır.

## 📁 Klasör Yapısı

```
teleconference_project/
├── .gitignore
├── README.md
├── Cargo.toml
├── lib.rs                  <-- ✅ Ana Rust kütüphanesi (burada sunucu kodu var)
├── main.rs                 <-- Rust backend giriş noktası (henüz boş)
├── Cargo.lock
├── pubspec.lock
├── build/                  <-- Uygulama yapılarında oluşturulan çıktılar
├── core_api/               <-- Temel API yapıları için kaynaklar klasörü
│   ├── mod.rs              <-- Modül exports'ları
│   ├── teleconference.rs   <-- Temel arayüzler
│   ├── teleconference_impl.rs <-- Gerçek API implementasyonu
│   └── message.rs          <-- İstemci-sunucu mesaj yapıları
├── pubspec.yaml            <-- <-- Flutter projeye ait bağımlılıkların ve ayarların bulunduğu dosya
└── lib/                    <-- Flutter frontend kaynakları
    └── main.dart
```

## 🚀 Mevcut Geliştirme Adımları

Şu ana kadar gerçekleştirilen çalışmalar:

### 🌳 `voidagent` branch oluşturma ve yapılandırması
- `git checkout -b voidagent` komutu ile yeni bir branch açıldı
- `.gitignore` dosyası yapılandırıldı:
  - Rust ve Flutter bağımlılıkları hariç tutuldu (`Cargo.lock`, `pubspec.lock`)
  - Derleme çıktıları hariç tutuldu (`build/`)
  - Ortam dosyaları hariç tutuldu (`.env`)
  - Editör ve işletim sistemine özel dosyalar hariç tutuldu

### 📦 Core API yapısı oluşturuldu

`core_api/` klasöründe temel API yapıları kuruldu:
- `teleconference.rs`: `TeleconferenceCore` trait ve bu trait'i destekleyen yapıların tanımları
  - Çoklu cihaz desteği: Mobil, sunucu, Raspberry Pi, Linux box
  - Ağ kapasiteleri, katılımcı özellikleri
  - Dinamik kalite değerlendirme, adaptif bit-rate kontrolü
- `teleconference_impl.rs`: `VoidAgentTeleconference` implementasyonu
  - Mutex tabanlı senkronizasyon
  - Gerçek zamanlı kalite ayarlaması ve cihaz uyumluluğu kontrolü
- `mod.rs`: Modül exports ve kolay erişim tanımları

### 🏢 Sunucu tarafı iskelet yapı kuruldu

`lib.rs` dosyasında başlangıç sunucu implementasyonu yapıldı:
```rust
pub struct VoidAgentServer {
    address: String,
    port: u16,
    is_running: bool,
    active_sessions: u32,
}

impl VoidAgentServer {
    pub fn new(address: &str, port: u16) -> Self { ... }
    pub fn start(&mut self) -> TeleconferenceResult<()> { ... }
    pub fn stop(&mut self) -> TeleconferenceResult<()> { ... }
    pub fn is_running(&self) -> bool { ... }
    pub fn version(&self) -> &str { ... }
}
```

## 📚 Kütüphane Gereksinimleri

### Rust Bağımlılıkları
- [uuid](https://crates.io/crates/uuid): Cihaz ve kullanıcı kimlikleri için evrensel benzersiz kimlik (UUID) oluşturmak için kullanılır

### Linux Setup (sunucu)
- PulseAudio gelişim başlıkları (`libpulse-dev`)
- ALSA gelişim başlıkları (`libasound2-dev`)
- Opus gelişim başlıkları (`libopus-dev`)

### Windows Gereksinimleri
- DirectX başlıklar için ses desteği
- MSVC++ derleme araçları

### Mobil Gereksinimler (Android/iOS)
- Android NDK (Native Development Kit)
- Xcode ile komut satırı araçları (iOS)

////////////////////////////////////////////

# Telekonferans Uygulaması

Gelişmiş ses işleme özellikleri ile donatılmış, çoklu platform destekli bir telekonferans uygulaması.

## Özellikler

- **Gelişmiş Ses İşleme**:
  - Gürültü azaltma
  - Yankı iptali
  - Ses yükseltme
  - Tam çift yönlü iletişim

- **360° Ses Alma**:
  - Çok yönlü mikrofon desteği
  - Farklı mikrofon modları

- **9 Seviyeli Ses Kontrolü**:
  - Hassas ses seviyesi ayarı
  - Görsel gösterge

- **USB Bağlantı Desteği**:
  - USB-C ve USB-A adaptör desteği
  - Otomatik cihaz algılama

- **Gizlilik Koruması**:
  - Mikrofon ve hoparlör sessize alma
  - Tam gizlilik modu

## Kurulum

### Gereksinimler

- Flutter SDK (en az 2.19.0 sürümü)
- Rust (en güncel sürüm)
- Cargo (Rust paket yöneticisi)
- Android Studio veya VS Code (Flutter eklentisi ile)

### Adımlar

1. Depoyu klonlayın:
git clone https://github.com/kullaniciadi/teleconference_app.git
cd teleconference_app


2. Flutter bağımlılıklarını yükleyin:
flutter pub get


3. Uygulamayı çalıştırın:
flutter run


## Geliştirme

### Proje Yapısı

- `lib/`: Flutter uygulama kodları
  - `services/`: Servis sınıfları
  - `widgets/`: UI bileşenleri
  - `models/`: Veri modelleri
- `rust/`: Rust kütüphanesi
  - `src/`: Kaynak kodlar
  - `build.rs`: Derleme betikleri

### Katkıda Bulunma

1. Bu depoyu fork edin
2. Yeni bir branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Değişikliklerinizi commit edin (`git commit -m 'Add some amazing feature'`)
4. Branch'inizi push edin (`git push origin feature/amazing-feature`)
5. Pull Request açın

## Lisans

Bu proje MIT lisansı altında lisanslanmıştır - detaylar için [LICENSE](LICENSE) dosyasına bakın.

