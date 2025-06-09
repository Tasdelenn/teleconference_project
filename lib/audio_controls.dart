// lib\audio_controls.dart
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ses Kontrolleri',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AudioControlsScreen(),
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
                      setState(() {
                        _volumeLevel = value.toInt();
                      });
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
                setState(() {
                  _microphoneMode = value!;
                });
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
                setState(() {
                  _processingMode = value!;
                });
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
              onChanged: (value) {
                setState(() {
                  _echoCancel = value;
                });
              },
            ),
            
            // Gürültü azaltma
            SwitchListTile(
              title: const Text('Gürültü Azaltma'),
              value: _noiseReduction,
              onChanged: (value) {
                setState(() {
                  _noiseReduction = value;
                });
              },
            ),
            
            // Otomatik kazanç kontrolü
            SwitchListTile(
              title: const Text('Otomatik Ses Seviyesi'),
              value: _autoGainControl,
              onChanged: (value) {
                setState(() {
                  _autoGainControl = value;
                });
              },
            ),
            
            // Gizlilik modu
            SwitchListTile(
              title: const Text('Gizlilik Modu'),
              subtitle: const Text('Mikrofon ve hoparlörü tamamen devre dışı bırakır'),
              value: _privacyMode,
              onChanged: (value) {
                setState(() {
                  _privacyMode = value;
                });
              },
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
                  onPressed: () {
                    setState(() {
                      _isMuted = !_isMuted;
                    });
                  },
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
                  onPressed: () {},
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
