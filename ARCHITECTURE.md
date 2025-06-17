# Telekonferans Uygulaması Mimari Dokümantasyonu

Bu doküman, telekonferans uygulamasının mimari yapısını, bileşenlerini ve veri akışını detaylı olarak açıklar.

## Genel Mimari Şeması

```
+----------------------------------+
|          Flutter UI              |
+----------------------------------+
              |
              v
+----------------------------------+
|        Servis Katmanı            |
|----------------------------------|
| WebRTC | Audio | Speech | Config |
| Service| Service| Service| Service|
+----------------------------------+
              |
              v
+----------------------------------+
|      İletişim Katmanı            |
|----------------------------------|
|  WebSocket  |      WebRTC        |
+----------------------------------+
              |
              v
+----------------------------------+
|      Sinyal Sunucusu             |
|      (Raspberry Pi)              |
+----------------------------------+
```

## Bileşenler

### 1. Flutter UI Katmanı

#### 1.1. Ekranlar
- **HomeScreen**: Ana giriş ekranı, oda oluşturma ve katılma
- **ConferenceScreen**: Konferans görüşme ekranı
- **DeviceSettingsScreen**: Cihaz ayarları ekranı
- **PlatformInfoScreen**: Platform bilgileri ekranı
- **RaspberryPiSetupScreen**: Raspberry Pi ayarları ekranı

#### 1.2. Widget'lar
- **ParticipantView**: Katılımcı video görüntüsü
- **ControlPanel**: Konferans kontrol paneli
- **SubtitleDisplay**: Altyazı gösterimi
- **ChatPanel**: Sohbet paneli
- **ScreenShareButton**: Ekran paylaşımı butonu
- **ShareRoomDialog**: Oda paylaşım diyaloğu
- **MeetingSettingsDialog**: Toplantı ayarları diyaloğu
- **PlatformAdaptiveUI**: Platform uyumlu UI bileşenleri

### 2. Servis Katmanı

#### 2.1. WebRTC Servisi
- Peer-to-peer bağlantı yönetimi
- Medya akışı yönetimi
- Sinyal mesajları işleme
- Katılımcı yönetimi

#### 2.2. Ses Servisi
- Mikrofon yönetimi
- Ses işleme (gürültü engelleme, yankı iptali)
- Ses kalitesi optimizasyonu
- Ses seviyesi kontrolü

#### 2.3. Konuşma Servisi
- Konuşma tanıma
- Altyazı oluşturma
- Altyazı senkronizasyonu
- Dil desteği

#### 2.4. Yapılandırma Servisi
- Platform algılama
- Cihaz tipi belirleme
- Ayarları yönetme
- Performans optimizasyonu

#### 2.5. Platform Servisi
- Cihaz özelliklerine erişim
- Batarya durumu izleme
- Ağ bağlantısı izleme
- Ekran açık tutma

### 3. İletişim Katmanı

#### 3.1. WebSocket
- Sinyal sunucusu ile iletişim
- Oda yönetimi mesajları
- Katılımcı bilgileri
- Sohbet mesajları

#### 3.2. WebRTC
- Peer-to-peer ses ve video iletişimi
- ICE adayları değişimi
- SDP teklif/cevap değişimi
- Veri kanalı iletişimi

### 4. Sinyal Sunucusu

#### 4.1. Node.js Sunucu
- WebSocket bağlantı yönetimi
- Oda yönetimi
- Sinyal mesajı iletimi
- Durum izleme

## Veri Akışı

### 1. Konferansa Katılma Akışı

```
+-------------+     +-------------+     +-------------+     +-------------+
|             |     |             |     |             |     |             |
|  HomeScreen |---->| WebRTCService|---->|  WebSocket  |---->|  Sinyal     |
|             |     |             |     |  İstemci    |     |  Sunucusu   |
+-------------+     +-------------+     +-------------+     +-------------+
                          |                                       |
                          v                                       v
                    +-------------+                         +-------------+
                    |             |                         |             |
                    | Conference  |<------------------------|  Diğer      |
                    | Screen      |                         |  Katılımcılar|
                    +-------------+                         +-------------+
```

### 2. Ses ve Video Akışı

```
+-------------+     +-------------+     +-------------+
|             |     |             |     |             |
| AudioService |---->| WebRTCService|---->|  Diğer      |
|             |     |             |     |  Katılımcılar|
+-------------+     +-------------+     +-------------+
      ^                    ^                  |
      |                    |                  |
+-------------+     +-------------+           |
|             |     |             |           |
| Mikrofon    |     | Kamera      |           |
|             |     |             |           v
+-------------+     +-------------+     +-------------+
                                        |             |
                                        | Hoparlör/   |
                                        | Ekran       |
                                        +-------------+
```

### 3. Konuşma Tanıma ve Altyazı Akışı

```
+-------------+     +-------------+     +-------------+     +-------------+
|             |     |             |     |             |     |             |
| AudioService |---->| SpeechService|---->| WebRTCService|---->|  Diğer      |
|             |     |             |     |             |     |  Katılımcılar|
+-------------+     +-------------+     +-------------+     +-------------+
                          |                                       |
                          v                                       v
                    +-------------+                         +-------------+
                    |             |                         |             |
                    | Subtitle    |                         | Subtitle    |
                    | Display     |                         | Display     |
                    +-------------+                         +-------------+
```

## Platform Özel Optimizasyonlar

### 1. Windows

- DirectX donanım hızlandırma
- Yüksek çözünürlük desteği
- Çoklu monitör desteği
- Ekran paylaşımı optimizasyonu

### 2. Fedora Silverblue

- Wayland desteği
- Flatpak izolasyonu
- Immutable OS uyumluluğu
- PipeWire ses sistemi entegrasyonu

### 3. Raspberry Pi

- Düşük kaynak kullanımı
- Systemd servis yönetimi
- Otomatik başlatma ve kurtarma
- Uzaktan yönetim API'si

### 4. Huawei P40 Lite

- EMUI pil optimizasyonu
- Kamera API optimizasyonu
- Arka plan çalışma kısıtlamaları yönetimi
- Mobil veri tasarrufu

## Güvenlik Mimarisi

### 1. Bağlantı Güvenliği
- WebSocket için SSL/TLS
- DTLS-SRTP (WebRTC için)
- ICE/STUN/TURN güvenliği

### 2. Veri Güvenliği
- Geçici oda anahtarları
- Katılımcı kimlik doğrulama
- Oturum yönetimi

### 3. Uygulama Güvenliği
- İzin yönetimi
- Güvenli depolama
- Hata ayıklama koruması

## Ölçeklenebilirlik

### 1. Yatay Ölçekleme
- Çoklu sinyal sunucusu desteği
- Yük dengeleme
- Coğrafi dağıtım

### 2. Dikey Ölçekleme
- Kaynak kullanımı optimizasyonu
- Önbellek stratejileri
- Verimli kodlama

## Gelecek Mimari Geliştirmeler

### 1. Uçtan Uca Şifreleme
- Anahtar değişimi protokolü
- Şifreleme algoritmaları
- Güvenlik denetimi

### 2. Federasyon Desteği
- Farklı sunucular arası iletişim
- Standart protokol desteği
- Kimlik federasyonu

### 3. Eklenti Mimarisi
- Dinamik özellik yükleme
- Üçüncü taraf entegrasyonları
- API genişletme