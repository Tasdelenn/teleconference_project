# Telekonferans Uygulaması

Çoklu platform desteği ve düşük güçlü cihaz optimizasyonu ile gerçek zamanlı telekonferans uygulaması.

## Özellikler

- WebRTC tabanlı gerçek zamanlı video ve ses iletişimi
- Gürültü engelleme ve yankı iptali
- Konuşma tanıma ve altyazı desteği
- Ekran paylaşımı
- Metin tabanlı sohbet
- Oda paylaşımı (QR kod ve bağlantı)
- Çoklu platform desteği (Windows, Linux, Android, iOS)
- Düşük güçlü cihaz optimizasyonu
- Raspberry Pi sinyal sunucusu

## Desteklenen Platformlar

- **Windows**: Geliştirme ve masaüstü kullanım
- **Fedora Silverblue**: Linux masaüstü kullanım
- **Raspberry Pi**: Sinyal sunucusu olarak kullanım
- **Android/iOS**: Mobil kullanım

## Kurulum

### Geliştirme Ortamı

1. Flutter SDK'yı kurun
2. Bağımlılıkları yükleyin:
   ```
   flutter pub get
   ```
3. Uygulamayı çalıştırın:
   ```
   flutter run
   ```

### Raspberry Pi Sinyal Sunucusu

1. Node.js ve npm'i kurun
2. Sunucu dizinine gidin:
   ```
   cd server
   ```
3. Bağımlılıkları yükleyin:
   ```
   npm install
   ```
4. Sunucuyu başlatın:
   ```
   npm start
   ```

Alternatif olarak, `deploy_to_raspberry.sh` betiğini kullanarak sunucuyu Raspberry Pi'ye dağıtabilirsiniz:
```
chmod +x deploy_to_raspberry.sh
./deploy_to_raspberry.sh
```

## Mimari

Uygulama aşağıdaki bileşenlerden oluşur:

- **Flutter UI**: Kullanıcı arayüzü
- **WebRTC Servisi**: Peer-to-peer bağlantı yönetimi
- **Ses Servisi**: Ses işleme ve gürültü engelleme
- **Konuşma Servisi**: Konuşma tanıma ve altyazı oluşturma
- **Platform Servisi**: Cihaz özelliklerine göre optimizasyon
- **Yapılandırma Servisi**: Farklı platformlar için ayarlar
- **Node.js Sinyal Sunucusu**: WebRTC sinyal iletimi

## Performans Optimizasyonu

Uygulama, farklı cihaz türleri için otomatik olarak performans optimizasyonu yapar:

- **Düşük güçlü cihazlar**: Düşük çözünürlük ve kare hızı
- **Mobil cihazlar**: Orta çözünürlük ve pil optimizasyonu
- **Masaüstü cihazlar**: Yüksek çözünürlük ve kalite

## X. Faz: Çoklu Platform Entegrasyonu ve Test

Bu fazda, uygulama farklı platformlarda test edilmiş ve optimize edilmiştir:

### X.1. Raspberry Pi Sinyal Sunucusu İyileştirmeleri

- Otomatik başlatma ve yeniden başlatma mekanizması eklendi
- Sunucu durumu izleme ve raporlama özellikleri geliştirildi
- Düşük kaynak kullanımı için optimizasyonlar yapıldı
- Güvenlik iyileştirmeleri ve SSL desteği eklendi

### X.2. Mobil Cihaz Optimizasyonları

- Huawei P40 Lite için özel kamera ve mikrofon ayarları
- Pil tasarrufu modu ve arka plan optimizasyonları
- Mobil veri kullanımını azaltmak için akıllı kalite ayarları
- Kesintisiz bağlantı için otomatik yeniden bağlanma mekanizması

### X.3. Fedora Silverblue Entegrasyonu

- Flatpak paketi oluşturuldu
- Immutable OS yapısına uygun yapılandırma yönetimi
- Wayland ve X11 desteği iyileştirildi
- Sistem kaynaklarını verimli kullanmak için optimizasyonlar

### X.4. Çapraz Platform Test Sonuçları

- Windows-Android arası iletişim testleri
- Fedora-Raspberry Pi arası iletişim testleri
- Düşük bant genişliği senaryoları için dayanıklılık testleri
- Farklı ağ koşullarında performans ölçümleri

### X.5. Gelecek Geliştirmeler

- Uçtan uca şifreleme
- Oda moderasyon özellikleri
- Dosya paylaşımı
- Toplantı kaydetme ve bulut depolama entegrasyonu

## Lisans

Bu proje MIT lisansı altında lisanslanmıştır.