import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teleconference_app/services/audio_service.dart';
import 'package:teleconference_app/services/webrtc_service.dart';
import 'package:teleconference_app/services/speech_service.dart';

class MeetingSettingsDialog extends StatefulWidget {
  const MeetingSettingsDialog({Key? key}) : super(key: key);

  @override
  _MeetingSettingsDialogState createState() => _MeetingSettingsDialogState();
}

class _MeetingSettingsDialogState extends State<MeetingSettingsDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _autoJoinAudio = true;
  bool _autoStartVideo = true;
  bool _showSubtitles = true;
  bool _enableNoiseReduction = true;
  bool _enableEchoCancellation = true;
  bool _enableAutoGainControl = true;
  String _selectedLanguage = 'Türkçe';
  String _selectedVideoQuality = 'Orta (480p)';
  String _selectedTheme = 'Sistem';
  
  final List<String> _languages = ['Türkçe', 'English', 'Español', 'Deutsch', 'Français'];
  final List<String> _videoQualities = ['Düşük (240p)', 'Orta (480p)', 'Yüksek (720p)', 'Çok Yüksek (1080p)'];
  final List<String> _themes = ['Sistem', 'Açık', 'Koyu'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Mevcut ayarları yükle
    _loadCurrentSettings();
  }
  
  void _loadCurrentSettings() {
    final audioService = Provider.of<AudioService>(context, listen: false);
    
    setState(() {
      _enableNoiseReduction = audioService.noiseReduction;
      _enableEchoCancellation = audioService.echoCancel;
      _enableAutoGainControl = audioService.autoGainControl;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Başlık
            const Text(
              'Toplantı Ayarları',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tab bar
            TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              tabs: const [
                Tab(text: 'Genel'),
                Tab(text: 'Ses'),
                Tab(text: 'Video'),
              ],
            ),
            
            // Tab içerikleri
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Genel ayarlar
                  _buildGeneralSettings(),
                  
                  // Ses ayarları
                  _buildAudioSettings(),
                  
                  // Video ayarları
                  _buildVideoSettings(),
                ],
              ),
            ),
            
            // Butonlar
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saveSettings,
                  child: const Text('Kaydet'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGeneralSettings() {
    return ListView(
      children: [
        // Dil seçimi
        ListTile(
          title: const Text('Dil'),
          trailing: DropdownButton<String>(
            value: _selectedLanguage,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedLanguage = value;
                });
              }
            },
            items: _languages.map((lang) {
              return DropdownMenuItem(
                value: lang,
                child: Text(lang),
              );
            }).toList(),
          ),
        ),
        
        // Tema seçimi
        ListTile(
          title: const Text('Tema'),
          trailing: DropdownButton<String>(
            value: _selectedTheme,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedTheme = value;
                });
              }
            },
            items: _themes.map((theme) {
              return DropdownMenuItem(
                value: theme,
                child: Text(theme),
              );
            }).toList(),
          ),
        ),
        
        // Altyazı gösterimi
        SwitchListTile(
          title: const Text('Altyazıları Göster'),
          subtitle: const Text('Konuşma tanıma ile oluşturulan altyazıları göster'),
          value: _showSubtitles,
          onChanged: (value) {
            setState(() {
              _showSubtitles = value;
            });
          },
        ),
        
        // Otomatik ses katılımı
        SwitchListTile(
          title: const Text('Otomatik Ses Katılımı'),
          subtitle: const Text('Toplantıya katılırken sesi otomatik olarak aç'),
          value: _autoJoinAudio,
          onChanged: (value) {
            setState(() {
              _autoJoinAudio = value;
            });
          },
        ),
        
        // Otomatik video başlatma
        SwitchListTile(
          title: const Text('Otomatik Video Başlatma'),
          subtitle: const Text('Toplantıya katılırken videoyu otomatik olarak aç'),
          value: _autoStartVideo,
          onChanged: (value) {
            setState(() {
              _autoStartVideo = value;
            });
          },
        ),
      ],
    );
  }
  
  Widget _buildAudioSettings() {
    final audioService = Provider.of<AudioService>(context);
    
    return ListView(
      children: [
        // Ses seviyesi
        ListTile(
          title: const Text('Ses Seviyesi'),
          subtitle: Slider(
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
        
        // İşleme modu
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
        
        // Mikrofon modu
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
          subtitle: const Text('Ses yankılarını otomatik olarak filtrele'),
          value: _enableEchoCancellation,
          onChanged: (value) {
            setState(() {
              _enableEchoCancellation = value;
            });
          },
        ),
        
        // Gürültü azaltma
        SwitchListTile(
          title: const Text('Gürültü Azaltma'),
          subtitle: const Text('Arka plan gürültüsünü azalt'),
          value: _enableNoiseReduction,
          onChanged: (value) {
            setState(() {
              _enableNoiseReduction = value;
            });
          },
        ),
        
        // Otomatik kazanç kontrolü
        SwitchListTile(
          title: const Text('Otomatik Ses Seviyesi'),
          subtitle: const Text('Ses seviyesini otomatik olarak ayarla'),
          value: _enableAutoGainControl,
          onChanged: (value) {
            setState(() {
              _enableAutoGainControl = value;
            });
          },
        ),
      ],
    );
  }
  
  Widget _buildVideoSettings() {
    return ListView(
      children: [
        // Video kalitesi
        ListTile(
          title: const Text('Video Kalitesi'),
          subtitle: const Text('Daha yüksek kalite daha fazla bant genişliği kullanır'),
          trailing: DropdownButton<String>(
            value: _selectedVideoQuality,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedVideoQuality = value;
                });
              }
            },
            items: _videoQualities.map((quality) {
              return DropdownMenuItem(
                value: quality,
                child: Text(quality),
              );
            }).toList(),
          ),
        ),
        
        // Arka plan bulanıklaştırma
        SwitchListTile(
          title: const Text('Arka Plan Bulanıklaştırma'),
          subtitle: const Text('Video arka planını bulanıklaştır (daha fazla işlemci gücü gerektirir)'),
          value: false,
          onChanged: (value) {
            // Bu özellik henüz uygulanmadı
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bu özellik henüz uygulanmadı')),
            );
          },
        ),
        
        // Ayna modu
        SwitchListTile(
          title: const Text('Ayna Modu'),
          subtitle: const Text('Kendi video görüntünü aynalı göster'),
          value: true,
          onChanged: (value) {
            // Bu özellik henüz uygulanmadı
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bu özellik henüz uygulanmadı')),
            );
          },
        ),
        
        // Düşük ışık geliştirme
        SwitchListTile(
          title: const Text('Düşük Işık Geliştirme'),
          subtitle: const Text('Düşük ışık koşullarında video kalitesini artır'),
          value: false,
          onChanged: (value) {
            // Bu özellik henüz uygulanmadı
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bu özellik henüz uygulanmadı')),
            );
          },
        ),
      ],
    );
  }
  
  void _saveSettings() {
    final audioService = Provider.of<AudioService>(context, listen: false);
    
    // Ses ayarlarını kaydet
    audioService.setEchoCancel(_enableEchoCancellation);
    audioService.setNoiseReduction(_enableNoiseReduction);
    audioService.setAutoGainControl(_enableAutoGainControl);
    
    // Diğer ayarlar için SharedPreferences kullanılabilir
    
    // Dialog'u kapat
    Navigator.pop(context);
    
    // Bilgi mesajı göster
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ayarlar kaydedildi')),
    );
  }
}