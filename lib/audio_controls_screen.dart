import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teleconference_app/services/audio_service.dart';

class AudioControlsScreen extends StatelessWidget {
  const AudioControlsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioService>(
      builder: (context, audioService, child) {
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
                  value: audioService.signalQuality,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    audioService.signalQuality > 0.8 ? Colors.green : 
                    audioService.signalQuality > 0.6 ? Colors.yellow : Colors.red
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    audioService.signalQuality > 0.8 ? 'Mükemmel' : 
                    audioService.signalQuality > 0.6 ? 'İyi' : 'Zayıf',
                    style: TextStyle(
                      color: audioService.signalQuality > 0.8 ? Colors.green : 
                      audioService.signalQuality > 0.6 ? Colors.orange : Colors.red,
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
                        value: audioService.volumeLevel.toDouble(),
                        min: 1,
                        max: 9,
                        divisions: 8,
                        label: audioService.volumeLevel.toString(),
                        onChanged: (value) {
                          audioService.setVolumeLevel(value.toInt());
                        },
                      ),
                    ),
                    Text(audioService.volumeLevel.toString(), style: const TextStyle(fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Mikrofon modu
                const Text('Mikrofon Modu:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                DropdownButton<MicrophoneMode>(
                  value: audioService.microphoneMode,
                  isExpanded: true,
                  onChanged: (value) {
                    if (value != null) {
                      audioService.setMicrophoneMode(value);
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: MicrophoneMode.directional, child: Text('Yönlü')),
                    DropdownMenuItem(value: MicrophoneMode.omnidirectional, child: Text('360° (Çok Yönlü)')),
                    DropdownMenuItem(value: MicrophoneMode.cardioid, child: Text('Kardioid')),
                    DropdownMenuItem(value: MicrophoneMode.beamforming, child: Text('Işın Şekillendirme')),
                  ],
                ),
                const SizedBox(height: 20),
                
                // İşleme modu
                const Text('Ses İşleme Modu:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                DropdownButton<AudioProcessingMode>(
                  value: audioService.processingMode,
                  isExpanded: true,
                  onChanged: (value) {
                    if (value != null) {
                      audioService.setProcessingMode(value);
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: AudioProcessingMode.standard, child: Text('Standart')),
                    DropdownMenuItem(value: AudioProcessingMode.noiseReduction, child: Text('Gürültü Azaltma')),
                    DropdownMenuItem(value: AudioProcessingMode.voiceEnhancement, child: Text('Ses Yükseltme')),
                    DropdownMenuItem(value: AudioProcessingMode.fullDuplex, child: Text('Tam Çift Yönlü')),
                    DropdownMenuItem(value: AudioProcessingMode.custom, child: Text('Özel')),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Yankı iptali
                SwitchListTile(
                  title: const Text('Yankı İptali'),
                  value: audioService.echoCancel,
                  onChanged: (_) => audioService.toggleEchoCancel(),
                ),
                
                // Gürültü azaltma
                SwitchListTile(
                  title: const Text('Gürültü Azaltma'),
                  value: audioService.noiseReduction,
                  onChanged: (_) => audioService.toggleNoiseReduction(),
                ),
                
                // Otomatik kazanç kontrolü
                SwitchListTile(
                  title: const Text('Otomatik Ses Seviyesi'),
                  value: audioService.autoGainControl,
                  onChanged: (_) => audioService.toggleAutoGainControl(),
                ),
                
                // Gizlilik modu
                SwitchListTile(
                  title: const Text('Gizlilik Modu'),
                  subtitle: const Text('Mikrofon ve hoparlörü tamamen devre dışı bırakır'),
                  value: audioService.privacyMode,
                  onChanged: (_) => audioService.togglePrivacyMode(),
                ),
                
                const SizedBox(height: 20),
                
                // USB cihaz bilgisi
                if (audioService.isUsbConnected)
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
                        Text('USB ${audioService.connectedDeviceType} Bağlı', 
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
                      icon: audioService.isMuted ? Icons.mic_off : Icons.mic,
                      label: audioService.isMuted ? 'Mikrofonu Aç' : 'Mikrofonu Kapat',
                      color: audioService.isMuted ? Colors.red : Colors.blue,
                      onPressed: () => audioService.toggleMute(),
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
      },
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
