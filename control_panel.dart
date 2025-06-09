import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teleconference_app/services/audio_service.dart';

class ControlPanel extends StatelessWidget {
  final VoidCallback onToggleMute;
  final VoidCallback onToggleVideo;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onLeaveRoom;
  final bool isMuted;
  final bool isVideoEnabled;
  final bool isSpeakerOn;

  const ControlPanel({
    Key? key,
    required this.onToggleMute,
    required this.onToggleVideo,
    required this.onToggleSpeaker,
    required this.onLeaveRoom,
    required this.isMuted,
    required this.isVideoEnabled,
    required this.isSpeakerOn,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final audioService = Provider.of<AudioService>(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ses seviyesi kontrolü
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Ses Seviyesi: '),
              Slider(
                value: audioService.volumeLevel.toDouble(),
                min: 1,
                max: 9,
                divisions: 8,
                label: audioService.volumeLevel.toString(),
                onChanged: (value) {
                  audioService.setVolumeLevel(value.toInt());
                },
              ),
              Text(audioService.volumeLevel.toString()),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Ana kontrol butonları
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Mikrofon butonu
              IconButton(
                icon: Icon(isMuted ? Icons.mic_off : Icons.mic),
                onPressed: onToggleMute,
                color: isMuted ? Colors.red : Colors.blue,
                tooltip: isMuted ? 'Mikrofonu Aç' : 'Mikrofonu Kapat',
              ),
              
              // Video butonu
              IconButton(
                icon: Icon(isVideoEnabled ? Icons.videocam : Icons.videocam_off),
                onPressed: onToggleVideo,
                color: isVideoEnabled ? Colors.blue : Colors.red,
                tooltip: isVideoEnabled ? 'Videoyu Kapat' : 'Videoyu Aç',
              ),
              
              // Hoparlör butonu
              IconButton(
                icon: Icon(isSpeakerOn ? Icons.volume_up : Icons.volume_off),
                onPressed: onToggleSpeaker,
                color: isSpeakerOn ? Colors.blue : Colors.red,
                tooltip: isSpeakerOn ? 'Hoparlörü Kapat' : 'Hoparlörü Aç',
              ),
              
              // Çıkış butonu
              IconButton(
                icon: const Icon(Icons.call_end),
                onPressed: onLeaveRoom,
                color: Colors.red,
                tooltip: 'Görüşmeyi Sonlandır',
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Gelişmiş ses kontrolleri
          ExpansionTile(
            title: const Text('Gelişmiş Ses Ayarları'),
            children: [
              // İşleme modu seçimi
              ListTile(
                title: const Text('Ses İşleme Modu'),
                trailing: DropdownButton<AudioProcessingMode>(
                  value: audioService.processingMode,
                  onChanged: (mode) {
                    if (mode != null) {
                      audioService.setProcessingMode(mode);
                    }
                  },
                  items: AudioProcessingMode.values.map((mode) {
                    String modeName = '';
                    switch (mode) {
                      case AudioProcessingMode.standard:
                        modeName = 'Standart';
                        break;
                      case AudioProcessingMode.noiseReduction:
                        modeName = 'Gürültü Azaltma';
                        break;
                      case AudioProcessingMode.voiceEnhancement:
                        modeName = 'Ses Yükseltme';
                        break;
                      case AudioProcessingMode.fullDuplex:
                        modeName = 'Tam Çift Yönlü';
                        break;
                      case AudioProcessingMode.custom:
                        modeName = 'Özel';
                        break;
                    }
                    return DropdownMenuItem(
                      value: mode,
                      child: Text(modeName),
                    );
                  }).toList(),
                ),
              ),
              
              // Mikrofon modu seçimi
              ListTile(
                title: const Text('Mikrofon Modu'),
                trailing: DropdownButton<MicrophoneMode>(
                  value: audioService.microphoneMode,
                  onChanged: (mode) {
                    if (mode != null) {
                      audioService.setMicrophoneMode(mode);
                    }
                  },
                  items: MicrophoneMode.values.map((mode) {
                    String modeName = '';
                    switch (mode) {
                      case MicrophoneMode.directional:
                        modeName = 'Yönlü';
                        break;
                      case MicrophoneMode.omnidirectional:
                        modeName = '360° (Çok Yönlü)';
                        break;
                      case MicrophoneMode.cardioid:
                        modeName = 'Kardioid';
                        break;
                      case MicrophoneMode.beamforming:
                        modeName = 'Işın Şekillendirme';
                        break;
                    }
                    return DropdownMenuItem(
                      value: mode,
                      child: Text(modeName),
                    );
                  }).toList(),
                ),
              ),
              
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
            ],
          ),
          
          // USB cihaz bilgisi
          if (audioService.isUsbConnected)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.usb, color: Colors.green),
                  const SizedBox(width: 8),
                  Text('USB ${audioService.connectedDeviceType} Bağlı', 
                    style: const TextStyle(color: Colors.green)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
