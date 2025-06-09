// lib\simple_test.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Telekonferans Uygulaması',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final micStatus = await Permission.microphone.request();
    setState(() {
      _permissionsGranted = micStatus == PermissionStatus.granted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Telekonferans Uygulaması'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Telekonferans Uygulaması',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            if (!_permissionsGranted)
              ElevatedButton(
                onPressed: _checkPermissions,
                child: const Text('Mikrofon İzni Ver'),
              )
            else
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AudioControlsScreen()),
                  );
                },
                child: const Text('Ses Kontrollerini Aç'),
              ),
          ],
        ),
      ),
    );
  }
}

class AudioControlsScreen extends StatefulWidget {
  const AudioControlsScreen({Key? key}) : super(key: key);

  @override
  _AudioControlsScreenState createState() => _AudioControlsScreenState();
}

class _AudioControlsScreenState extends State<AudioControlsScreen> {
  int _volumeLevel = 5;
  bool _echoCancel = true;
  bool _noiseReduction = true;
  bool _autoGainControl = true;
  bool _privacyMode = false;
  int _microphoneMode = 1; // 0: directional, 1: omnidirectional, 2: cardioid, 3: beamforming
  int _processingMode = 0; // 0: standard, 1: noiseReduction, 2: voiceEnhancement, 3: fullDuplex, 4: custom
  bool _isMuted = false;
  bool _isUsbConnected = true;
  String _connectedDeviceType = "USB-C";
  
  // Ses kalitesi göstergesi
  double _signalQuality = 0.85; // 0.0 - 1.0 arası
  Timer? _qualityTimer;
  
  @override
  void initState() {
    super.initState();
    // Ses kalitesini periyodik olarak güncelle
    _qualityTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _updateSignalQuality();
    });
    
    // USB cihazlarını algıla
    _detectAudioDevices();
  }
  
  @override
  void dispose() {
    _qualityTimer?.cancel();
    super.dispose();
  }
  
  // Ses kalitesini güncelle
  void _updateSignalQuality() {
    setState(() {
      // Gerçek uygulamada bu değer ses işleme modülünden gelecek
      // Şimdilik rastgele bir değer üretiyoruz
      _signalQuality = 0.7 + (DateTime.now().millisecondsSinceEpoch % 300) / 1000;
    });
  }
  
  // USB cihazlarını algıla
  Future<void> _detectAudioDevices() async {
    // Gerçek uygulamada platform-specific kod kullanarak USB cihazları algılanacak
    // Şimdilik varsayılan değerler kullanıyoruz
    setState(() {
      _isUsbConnected = true;
      _connectedDeviceType = "USB-C";
    });
  }
  
  // Ses seviyesini ayarla
  void _setVolumeLevel(int level) {
    setState(() {
      _volumeLevel = level;
    });
    // Gerçek uygulamada ses seviyesi ayarlanacak
    print('Ses seviyesi ayarlandı: $_volumeLevel');
  }
  
  // Mikrofon modunu değiştir
  void _setMicrophoneMode(int mode) {
    setState(() {
      _microphoneMode = mode;
    });
    // Gerçek uygulamada mikrofon modu değiştirilecek
    print('Mikrofon modu değiştirildi: $_microphoneMode');
  }
  
  // İşleme modunu değiştir
  void _setProcessingMode(int mode) {
    setState(() {
      _processingMode = mode;
    });
    // Gerçek uygulamada işleme modu değiştirilecek
    print('İşleme modu değiştirildi: $_processingMode');
  }
  
  // Yankı iptalini aç/kapat
  void _toggleEchoCancel() {
    setState(() {
      _echoCancel = !_echoCancel;
    });
    // Gerçek uygulamada yankı iptali açılıp/kapatılacak
    print('Yankı iptali: $_echoCancel');
  }
  
  // Gürültü azaltmayı aç/kapat
  void _toggleNoiseReduction() {
    setState(() {
      _noiseReduction = !_noiseReduction;
    });
    // Gerçek uygulamada gürültü azaltma açılıp/kapatılacak
    print('Gürültü azaltma: $_noiseReduction');
  }
  
  // Otomatik kazanç kontrolünü aç/kapat
  void _toggleAutoGainControl() {
    setState(() {
      _autoGainControl = !_autoGainControl;
    });
    // Gerçek uygulamada otomatik kazanç kontrolü açılıp/kapatılacak
    print('Otomatik kazanç kontrolü: $_autoGainControl');
  }
  
  // Gizlilik modunu aç/kapat
  void _togglePrivacyMode() {
    setState(() {
      _privacyMode = !_privacyMode;
      if (_privacyMode) {
        _isMuted = true;
      }
    });
    // Gerçek uygulamada gizlilik modu açılıp/kapatılacak
    print('Gizlilik modu: $_privacyMode');
  }
  
  // Mikrofonu sessize al/aç
  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    // Gerçek uygulamada mikrofon sessize alınıp/açılacak
    print('Mikrofon sessize alma: $_isMuted');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ses Kontrolleri'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ses kalitesi göstergesi
            const Text('Ses Kalitesi:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            LinearProgressIndicator(
              value: _signalQuality,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _signalQuality > 0.8 ? Colors.green : 
                _signalQuality > 0.6 ? Colors.yellow : Colors.red
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                _signalQuality > 0.8 ? 'Mükemmel' : 
                _signalQuality > 0.6 ? 'İyi' : 'Zayıf',
                style: TextStyle(
                  color: _signalQuality > 0.8 ? Colors.green : 
                  _signalQuality > 0.6 ? Colors.orange : Colors.red,
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Ses seviyesi kontrolü
            const Text('Ses Seviyesi:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _volumeLevel.toDouble(),
                    min: 1,
                    max: 9,
                    divisions: 8,
                    label: _volumeLevel.toString(),
                    onChanged: (value) {
                      _setVolumeLevel(value.toInt());
                    },
                  ),
                ),
                Text(_volumeLevel.toString(), style: const TextStyle(fontSize: 18)),
              ],
            ),
            const SizedBox(height: 20),
            
            // Mikrofon modu
            const Text('Mikrofon Modu:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            DropdownButton<int>(
              value: _microphoneMode,
              isExpanded: true,
              onChanged: (value) {
                if (value != null) {
                  _setMicrophoneMode(value);
                }
              },
              items: const [
                DropdownMenuItem(value: 0, child: Text('Yönlü')),
                DropdownMenuItem(value: 1, child: Text('360° (Çok Yönlü)')),
                DropdownMenuItem(value: 2, child: Text('Kardioid')),
                DropdownMenuItem(value: 3, child: Text('Işın Şekillendirme')),
              ],
            ),
            const SizedBox(height: 20),
            
            // İşleme modu
            const Text('Ses İşleme Modu:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            DropdownButton<int>(
              value: _processingMode,
              isExpanded: true,
              onChanged: (value) {
                if (value != null) {
                  _setProcessingMode(value);
                }
              },
              items: const [
                DropdownMenuItem(value: 0, child: Text('Standart')),
                DropdownMenuItem(value: 1, child: Text('Gürültü Azaltma')),
                DropdownMenuItem(value: 2, child: Text('Ses Yükseltme')),
                DropdownMenuItem(value: 3, child: Text('Tam Çift Yönlü')),
                DropdownMenuItem(value: 4, child: Text('Özel')),
              ],
            ),
            const SizedBox(height: 20),
            
            // Yankı iptali
            SwitchListTile(
              title: const Text('Yankı İptali'),
              value: _echoCancel,
              onChanged: (_) => _toggleEchoCancel(),
            ),
            
            // Gürültü azaltma
            SwitchListTile(
              title: const Text('Gürültü Azaltma'),
              value: _noiseReduction,
              onChanged: (_) => _toggleNoiseReduction(),
            ),
            
            // Otomatik kazanç kontrolü
            SwitchListTile(
              title: const Text('Otomatik Ses Seviyesi'),
              value: _autoGainControl,
              onChanged: (_) => _toggleAutoGainControl(),
            ),
            
            // Gizlilik modu
            SwitchListTile(
              title: const Text('Gizlilik Modu'),
              subtitle: const Text('Mikrofon ve hoparlörü tamamen devre dışı bırakır'),
              value: _privacyMode,
              onChanged: (_) => _togglePrivacyMode(),
            ),
            
            const SizedBox(height: 20),
            
            // USB cihaz bilgisi
            if (_isUsbConnected)
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.usb, color: Colors.green),
                    const SizedBox(width: 8),
                    Text('USB $_connectedDeviceType Bağlı', 
                      style: const TextStyle(color: Colors.green)),
                  ],
                ),
              ),
            
            const SizedBox(height: 20),
            
            // Kontrol butonları
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: _isMuted ? Icons.mic_off : Icons.mic,
                  label: _isMuted ? 'Mikrofonu Aç' : 'Mikrofonu Kapat',
                  color: _isMuted ? Colors.red : Colors.blue,
                  onPressed: _toggleMute,
                ),
                _buildControlButton(
                  icon: Icons.videocam,
                  label: 'Video',
                  onPressed: () {},
                ),
                _buildControlButton(
                  icon: Icons.volume_up,
                  label: 'Hoparlör',
                  onPressed: () {},
                ),
                _buildControlButton(
                  icon: Icons.call_end,
                  label: 'Kapat',
                  color: Colors.red,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color color = Colors.blue,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.2),
          ),
          child: IconButton(
            icon: Icon(icon),
            color: color,
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
