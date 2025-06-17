#!/bin/bash

# Raspberry Pi'ye sinyal sunucusunu dağıtma betiği

# Değişkenler
PI_USER="haqan"
PI_HOST="192.168.1.41"
PI_PASSWORD="0hata0"
REMOTE_DIR="/home/haqan/teleconference_server"

# Gerekli dosyaları sıkıştır
echo "Dosyalar sıkıştırılıyor..."
tar -czf server.tar.gz signaling_server.js package.json

# Uzak dizini oluştur
echo "Uzak dizin oluşturuluyor..."
sshpass -p "$PI_PASSWORD" ssh $PI_USER@$PI_HOST "mkdir -p $REMOTE_DIR"

# Dosyaları kopyala
echo "Dosyalar kopyalanıyor..."
sshpass -p "$PI_PASSWORD" scp server.tar.gz $PI_USER@$PI_HOST:$REMOTE_DIR/

# Dosyaları aç ve bağımlılıkları yükle
echo "Dosyalar açılıyor ve bağımlılıklar yükleniyor..."
sshpass -p "$PI_PASSWORD" ssh $PI_USER@$PI_HOST "cd $REMOTE_DIR && tar -xzf server.tar.gz && npm install"

# Servis dosyası oluştur
echo "Systemd servis dosyası oluşturuluyor..."
cat > teleconference.service << EOF
[Unit]
Description=Teleconference Signaling Server
After=network.target

[Service]
Type=simple
User=$PI_USER
WorkingDirectory=$REMOTE_DIR
ExecStart=/usr/bin/node $REMOTE_DIR/signaling_server.js
Restart=on-failure
Environment=PORT=8080

[Install]
WantedBy=multi-user.target
EOF

# Servis dosyasını kopyala
echo "Servis dosyası kopyalanıyor..."
sshpass -p "$PI_PASSWORD" scp teleconference.service $PI_USER@$PI_HOST:/tmp/

# Servis dosyasını yükle ve etkinleştir
echo "Servis yükleniyor ve etkinleştiriliyor..."
sshpass -p "$PI_PASSWORD" ssh $PI_USER@$PI_HOST "sudo mv /tmp/teleconference.service /etc/systemd/system/ && sudo systemctl daemon-reload && sudo systemctl enable teleconference.service && sudo systemctl start teleconference.service"

# Temizlik
echo "Geçici dosyalar temizleniyor..."
rm server.tar.gz teleconference.service

echo "Dağıtım tamamlandı! Sunucu http://$PI_HOST:8080 adresinde çalışıyor."
echo "Servis durumunu kontrol etmek için: ssh $PI_USER@$PI_HOST 'sudo systemctl status teleconference.service'"