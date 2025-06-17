# Telekonferans Uygulaması Kurulum Rehberi

Bu rehber, telekonferans uygulamasının farklı platformlarda kurulumu ve yapılandırılması için adım adım talimatlar içerir.

## İçindekiler

1. [Gereksinimler](#gereksinimler)
2. [Windows Kurulumu](#windows-kurulumu)
3. [Fedora Silverblue Kurulumu](#fedora-silverblue-kurulumu)
4. [Raspberry Pi Sinyal Sunucusu Kurulumu](#raspberry-pi-sinyal-sunucusu-kurulumu)
5. [Android Kurulumu](#android-kurulumu)
6. [Yapılandırma](#yapılandırma)
7. [Sorun Giderme](#sorun-giderme)

## Gereksinimler

### Geliştirme Ortamı
- Flutter SDK 3.0.0 veya üzeri
- Dart SDK 2.17.0 veya üzeri
- Git

### Sinyal Sunucusu
- Node.js 14.0.0 veya üzeri
- npm 6.0.0 veya üzeri

### Desteklenen Platformlar
- Windows 10/11
- Fedora Silverblue 36 veya üzeri
- Raspberry Pi OS (Bullseye veya üzeri)
- Android 8.0 veya üzeri

## Windows Kurulumu

### 1. Flutter SDK Kurulumu

1. Flutter SDK'yı [resmi web sitesinden](https://flutter.dev/docs/get-started/install/windows) indirin
2. ZIP dosyasını istediğiniz bir konuma çıkarın (örn. `C:\flutter`)
3. Flutter'ı PATH ortam değişkeninize ekleyin:
   - Sistem Özellikleri > Gelişmiş > Ortam Değişkenleri
   - Path değişkenine `C:\flutter\bin` ekleyin
4. Kurulumu doğrulayın:
   ```
   flutter doctor
   ```

### 2. Proje Kurulumu

1. Projeyi klonlayın veya indirin:
   ```
   git clone https://github.com/username/teleconference_project.git
   cd teleconference_project
   ```

2. Bağımlılıkları yükleyin:
   ```
   flutter pub get
   ```

3. `.env` dosyasını oluşturun:
   ```
   SERVER_URL=ws://192.168.1.41:8080
   STUN_SERVER=stun:stun.l.google.com:19302
   ```

4. Uygulamayı çalıştırın:
   ```
   flutter run -d windows
   ```

## Fedora Silverblue Kurulumu

### 1. Flutter SDK Kurulumu

1. Gerekli paketleri yükleyin:
   ```
   rpm-ostree install clang cmake ninja-build gtk3-devel
   ```

2. Flutter SDK'yı indirin:
   ```
   curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.0.0-stable.tar.xz
   tar xf flutter_linux_3.0.0-stable.tar.xz
   ```

3. Flutter'ı PATH'e ekleyin:
   ```
   echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
   source ~/.bashrc
   ```

4. Kurulumu doğrulayın:
   ```
   flutter doctor
   ```

### 2. Proje Kurulumu

1. Projeyi klonlayın:
   ```
   git clone https://github.com/username/teleconference_project.git
   cd teleconference_project
   ```

2. Bağımlılıkları yükleyin:
   ```
   flutter pub get
   ```

3. `.env` dosyasını oluşturun:
   ```
   SERVER_URL=ws://192.168.1.41:8080
   STUN_SERVER=stun:stun.l.google.com:19302
   ```

4. Uygulamayı çalıştırın:
   ```
   flutter run -d linux
   ```

## Raspberry Pi Sinyal Sunucusu Kurulumu

### 1. Raspberry Pi OS Kurulumu

1. [Raspberry Pi Imager](https://www.raspberrypi.org/software/) uygulamasını indirin
2. Raspberry Pi OS Lite'ı SD karta yazın
3. SSH'ı etkinleştirmek için boot bölümünde boş bir `ssh` dosyası oluşturun
4. SD kartı Raspberry Pi'ye takın ve açın
5. IP adresini bulun:
   ```
   ping raspberrypi.local
   ```
   veya router'ınızın DHCP istemci listesine bakın

### 2. Gerekli Paketleri Yükleme

1. SSH ile Raspberry Pi'ye bağlanın:
   ```
   ssh pi@192.168.1.41
   ```
   Varsayılan şifre: `raspberry`

2. Sistemi güncelleyin:
   ```
   sudo apt update
   sudo apt upgrade -y
   ```

3. Node.js ve npm'i yükleyin:
   ```
   curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
   sudo apt install -y nodejs
   ```

4. Git'i yükleyin:
   ```
   sudo apt install -y git
   ```

### 3. Sinyal Sunucusu Kurulumu

1. Projeyi klonlayın:
   ```
   git clone https://github.com/username/teleconference_project.git
   cd teleconference_project/server
   ```

2. Bağımlılıkları yükleyin:
   ```
   npm install
   ```

3. Sunucuyu başlatın:
   ```
   npm start
   ```

### 4. Systemd Servisi Olarak Yapılandırma

1. Servis dosyası oluşturun:
   ```
   sudo nano /etc/systemd/system/teleconference.service
   ```

2. Aşağıdaki içeriği ekleyin:
   ```
   [Unit]
   Description=Teleconference Signaling Server
   After=network.target

   [Service]
   Type=simple
   User=pi
   WorkingDirectory=/home/pi/teleconference_project/server
   ExecStart=/usr/bin/node /home/pi/teleconference_project/server/signaling_server.js
   Restart=on-failure
   Environment=PORT=8080

   [Install]
   WantedBy=multi-user.target
   ```

3. Servisi etkinleştirin ve başlatın:
   ```
   sudo systemctl daemon-reload
   sudo systemctl enable teleconference.service
   sudo systemctl start teleconference.service
   ```

4. Durumu kontrol edin:
   ```
   sudo systemctl status teleconference.service
   ```

## Android Kurulumu

### 1. Geliştirme Ortamı Hazırlama

1. Android Studio'yu [resmi web sitesinden](https://developer.android.com/studio) indirin ve kurun
2. Android SDK'yı kurun:
   - Android Studio > Tools > SDK Manager
   - SDK Platforms sekmesinde Android 8.0 (API level 26) veya üzerini seçin
   - SDK Tools sekmesinde Android SDK Build-Tools'u seçin
   - Apply'a tıklayın ve indirmeyi bekleyin

3. Flutter'ı yapılandırın:
   ```
   flutter config --android-sdk <android-sdk-path>
   ```

### 2. Fiziksel Cihazda Çalıştırma

1. Android cihazınızda geliştirici seçeneklerini etkinleştirin:
   - Ayarlar > Telefon hakkında > Yazılım bilgisi
   - "Derleme numarası" üzerine 7 kez dokunun
   - Ayarlar > Geliştirici seçenekleri > USB hata ayıklamayı etkinleştirin

2. Cihazı bilgisayara bağlayın ve izin verin

3. Cihazın tanındığını doğrulayın:
   ```
   flutter devices
   ```

4. Uygulamayı çalıştırın:
   ```
   flutter run
   ```

### 3. APK Oluşturma

1. APK oluşturun:
   ```
   flutter build apk --release
   ```

2. APK dosyasını bulun:
   ```
   build/app/outputs/flutter-apk/app-release.apk
   ```

3. APK'yı Android cihazınıza yükleyin

## Yapılandırma

### .env Dosyası

Uygulamanın kök dizininde bir `.env` dosyası oluşturun:

```
# Sinyal sunucusu URL'si
SERVER_URL=ws://192.168.1.41:8080

# ICE sunucuları
STUN_SERVER=stun:stun.l.google.com:19302
TURN_SERVER=
TURN_USERNAME=
TURN_PASSWORD=

# Ses işleme ayarları
AUDIO_SAMPLE_RATE=48000
AUDIO_CHANNELS=2
NOISE_REDUCTION_LEVEL=0.7
ECHO_CANCELLATION_LEVEL=0.8

# Video ayarları
DEFAULT_VIDEO_QUALITY=720p
MAX_VIDEO_BITRATE=1500000
MIN_VIDEO_BITRATE=150000

# Geliştirme ayarları
DEBUG_MODE=true
LOG_LEVEL=info
```

### Sunucu Yapılandırması

Sinyal sunucusu için `server/.env` dosyası oluşturun:

```
# Sunucu ayarları
PORT=8080
HOST=0.0.0.0

# SSL ayarları (opsiyonel)
USE_SSL=false
SSL_KEY_PATH=/path/to/key.pem
SSL_CERT_PATH=/path/to/cert.pem

# Güvenlik ayarları
ALLOW_CORS=true
CORS_ORIGIN=*

# Loglama
LOG_LEVEL=info
```

## Sorun Giderme

### Bağlantı Sorunları

1. Sinyal sunucusunun çalıştığını doğrulayın:
   ```
   curl http://192.168.1.41:8080/info
   ```

2. Güvenlik duvarı ayarlarını kontrol edin:
   ```
   # Raspberry Pi'de
   sudo ufw status
   ```

3. WebSocket bağlantısını test edin:
   ```
   # Windows'ta
   wscat -c ws://192.168.1.41:8080
   ```

### Flutter Sorunları

1. Flutter kurulumunu doğrulayın:
   ```
   flutter doctor
   ```

2. Bağımlılıkları temizleyin ve yeniden yükleyin:
   ```
   flutter clean
   flutter pub get
   ```

3. Önbelleği temizleyin:
   ```
   flutter pub cache repair
   ```

### Sinyal Sunucusu Sorunları

1. Sunucu loglarını kontrol edin:
   ```
   # Raspberry Pi'de
   journalctl -u teleconference.service -n 100
   ```

2. Sunucuyu manuel olarak başlatın:
   ```
   cd ~/teleconference_project/server
   node signaling_server.js
   ```

3. Sunucuyu yeniden başlatın:
   ```
   sudo systemctl restart teleconference.service
   ```

### Mobil Cihaz Sorunları

1. USB hata ayıklama modunun açık olduğunu doğrulayın
2. Farklı bir USB kablosu deneyin
3. Cihazı yeniden başlatın
4. Flutter'ı yeniden başlatın:
   ```
   flutter devices
   ```

## Yardım ve Destek

Daha fazla yardım için:

- GitHub sorunları: https://github.com/username/teleconference_project/issues
- E-posta desteği: support@teleconference-app.example.com