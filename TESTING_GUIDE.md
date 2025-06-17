# Telekonferans Uygulaması Test Rehberi

Bu rehber, telekonferans uygulamasını farklı cihazlarda test etmek için adım adım talimatlar içerir.

## Test Ortamı Şeması

```
+----------------+                   +----------------+
|                |                   |                |
|  Windows PC    |<----------------->| Raspberry Pi   |
| (Geliştirme)   |                   | (Sinyal Sunucu)|
|                |                   |                |
+----------------+                   +----------------+
        ^                                    ^
        |                                    |
        v                                    v
+----------------+                   +----------------+
|                |                   |                |
| Fedora         |<----------------->| Huawei P40 Lite|
| Silverblue     |                   | (Mobil Test)   |
| (Linux Test)   |                   |                |
+----------------+                   +----------------+
```

## 1. Raspberry Pi Sinyal Sunucusu Kurulumu

### 1.1. Gereksinimler
- Raspberry Pi 4 (en az 2GB RAM)
- Micro SD kart (en az 16GB)
- Güç adaptörü
- Ethernet kablosu veya WiFi bağlantısı

### 1.2. İşletim Sistemi Kurulumu
1. Raspberry Pi OS Lite'ı indirin ve SD karta yazın
2. SSH'ı etkinleştirin
3. Raspberry Pi'yi ağa bağlayın ve IP adresini not edin (örn. 192.168.1.41)

### 1.3. Sunucu Kurulumu
1. SSH ile Raspberry Pi'ye bağlanın:
   ```
   ssh haqan@192.168.1.41
   ```
   Şifre: `0hata0`

2. Node.js ve npm'i kurun:
   ```
   sudo apt update
   sudo apt install -y nodejs npm
   ```

3. Windows PC'den sunucu dosyalarını Raspberry Pi'ye kopyalayın:
   ```
   # Windows PC'de çalıştırın
   cd c:\Dev\teleconference_project\teleconference_project
   chmod +x server/deploy_to_raspberry.sh
   ./server/deploy_to_raspberry.sh
   ```

4. Sunucunun çalıştığını doğrulayın:
   ```
   # Raspberry Pi'de çalıştırın
   systemctl status teleconference.service
   ```

## 2. Windows PC'de Geliştirme ve Test

### 2.1. Gereksinimler
- Flutter SDK
- Android Studio veya VS Code
- Git

### 2.2. Uygulama Kurulumu
1. Projeyi klonlayın veya açın:
   ```
   cd c:\Dev\teleconference_project
   ```

2. Bağımlılıkları yükleyin:
   ```
   flutter pub get
   ```

3. `.env` dosyasını düzenleyin:
   ```
   SERVER_URL=ws://192.168.1.41:8080
   ```

4. Uygulamayı çalıştırın:
   ```
   flutter run -d windows
   ```

### 2.3. Test Senaryoları
1. **Oda Oluşturma Testi**:
   - Uygulamayı başlatın
   - İsminizi girin
   - "Yeni Oda Oluştur" butonuna tıklayın
   - Oda ID'sini not edin

2. **Ekran Paylaşımı Testi**:
   - Konferans ekranında "Ekran Paylaşımı" butonuna tıklayın
   - Paylaşılacak pencereyi seçin
   - Paylaşımı durdurun

3. **Cihaz Ayarları Testi**:
   - "Cihaz Ayarları" ekranına gidin
   - Sunucu URL'sini kontrol edin
   - Bağlantı durumunu kontrol edin

## 3. Fedora Silverblue'da Test

### 3.1. Gereksinimler
- Fedora Silverblue yüklü laptop
- Flutter SDK
- Flatpak

### 3.2. Uygulama Kurulumu
1. Flutter SDK'yı kurun:
   ```
   rpm-ostree install flutter
   ```

2. Projeyi klonlayın:
   ```
   git clone https://your-repo-url/teleconference_project.git
   cd teleconference_project
   ```

3. Bağımlılıkları yükleyin:
   ```
   flutter pub get
   ```

4. `.env` dosyasını düzenleyin:
   ```
   SERVER_URL=ws://192.168.1.41:8080
   ```

5. Uygulamayı çalıştırın:
   ```
   flutter run -d linux
   ```

### 3.3. Test Senaryoları
1. **Odaya Katılma Testi**:
   - Uygulamayı başlatın
   - İsminizi girin
   - Windows PC'de oluşturduğunuz Oda ID'sini girin
   - "Odaya Katıl" butonuna tıklayın

2. **Ses ve Video Testi**:
   - Mikrofonunuzun çalıştığını doğrulayın
   - Kameranızın çalıştığını doğrulayın
   - Ses ve video kontrollerini test edin

3. **Platform Bilgileri Testi**:
   - "Platform Bilgileri" ekranına gidin
   - Linux ve cihaz bilgilerinin doğru gösterildiğini kontrol edin

## 4. Huawei P40 Lite'da Test

### 4.1. Gereksinimler
- Huawei P40 Lite
- USB kablo
- Flutter SDK (Windows PC'de)

### 4.2. Uygulama Kurulumu
1. Telefonunuzda geliştirici seçeneklerini etkinleştirin
2. USB hata ayıklamayı açın
3. Telefonu Windows PC'ye bağlayın
4. Uygulamayı telefona yükleyin:
   ```
   # Windows PC'de çalıştırın
   flutter run -d <device-id>
   ```

### 4.3. Test Senaryoları
1. **Mobil Ağ Testi**:
   - WiFi'ı kapatın ve mobil veriyi açın
   - Uygulamayı başlatın ve bir odaya katılın
   - Video kalitesinin otomatik olarak düşürüldüğünü gözlemleyin

2. **Pil Optimizasyonu Testi**:
   - Telefonu düşük pil moduna alın
   - Uygulamayı başlatın ve bir odaya katılın
   - Pil tasarrufu özelliklerinin devreye girdiğini doğrulayın

3. **Arka Plan Testi**:
   - Bir konferansa katılın
   - Ana ekrana dönün (uygulamayı arka plana alın)
   - 30 saniye bekleyin ve uygulamaya geri dönün
   - Bağlantının hala aktif olduğunu doğrulayın

## 5. Çapraz Platform Test Senaryoları

### 5.1. Windows PC ve Huawei P40 Lite Arası Test
1. Windows PC'de bir oda oluşturun
2. Huawei P40 Lite ile odaya katılın
3. Ses, video ve sohbet özelliklerini test edin
4. Ekran paylaşımını test edin

### 5.2. Fedora Silverblue ve Raspberry Pi Arası Test
1. Fedora Silverblue'da bir oda oluşturun
2. Raspberry Pi'nin sinyal sunucusu olarak çalıştığını doğrulayın
3. Sunucu loglarını kontrol edin:
   ```
   # Raspberry Pi'de çalıştırın
   journalctl -u teleconference.service -f
   ```

### 5.3. Dört Cihazlı Konferans Testi
1. Tüm cihazlarla (Windows PC, Fedora Silverblue, Huawei P40 Lite) aynı odaya katılın
2. Her cihazdan ses ve video iletimini test edin
3. Sohbet mesajlarının tüm cihazlara ulaştığını doğrulayın
4. Ekran paylaşımını test edin
5. Altyazı özelliğini test edin

## 6. Performans ve Dayanıklılık Testleri

### 6.1. Düşük Bant Genişliği Testi
1. Ağ hızını sınırlandırın (örn. NetLimiter veya benzeri bir araç kullanarak)
2. Konferansa katılın ve performansı gözlemleyin
3. Video kalitesinin otomatik olarak düşürüldüğünü doğrulayın

### 6.2. Uzun Süreli Çalışma Testi
1. En az 1 saatlik bir konferans başlatın
2. Bellek kullanımını izleyin
3. Performans düşüşü olup olmadığını kontrol edin

### 6.3. Bağlantı Kesintisi Testi
1. Konferansa katılın
2. Ağ bağlantısını geçici olarak kesin (WiFi'ı kapatın veya Ethernet kablosunu çıkarın)
3. 10 saniye bekleyin ve bağlantıyı tekrar açın
4. Uygulamanın otomatik olarak yeniden bağlanıp bağlanmadığını kontrol edin

## 7. Hata Ayıklama ve Sorun Giderme

### 7.1. Sunucu Sorunları
- Sunucu çalışmıyorsa:
  ```
  # Raspberry Pi'de çalıştırın
  sudo systemctl restart teleconference.service
  ```

- Sunucu loglarını kontrol edin:
  ```
  journalctl -u teleconference.service -n 100
  ```

### 7.2. Uygulama Sorunları
- Flutter hata ayıklama konsolu çıktılarını kontrol edin
- `.env` dosyasındaki sunucu URL'sinin doğru olduğunu doğrulayın
- Cihaz ayarları ekranından sunucu bağlantısını test edin

### 7.3. Ağ Sorunları
- Raspberry Pi'nin IP adresine ping atın:
  ```
  ping 192.168.1.41
  ```
- 8080 portuna telnet bağlantısı deneyin:
  ```
  telnet 192.168.1.41 8080
  ```
- Güvenlik duvarı ayarlarını kontrol edin:
  ```
  # Raspberry Pi'de çalıştırın
  sudo ufw status
  ```

## 8. Test Sonuçlarını Belgeleme

Her test senaryosu için aşağıdaki bilgileri kaydedin:

1. Test tarihi ve saati
2. Test edilen cihazlar ve işletim sistemleri
3. Test senaryosu adı ve açıklaması
4. Beklenen sonuç
5. Gerçek sonuç
6. Karşılaşılan hatalar veya sorunlar
7. Ekran görüntüleri veya videolar
8. Performans ölçümleri (varsa)

Bu belgeleme, uygulamanın farklı platformlarda nasıl performans gösterdiğini anlamak ve gelecekteki geliştirmeler için yol gösterici olacaktır.