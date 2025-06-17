import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:teleconference_app/services/webrtc_service.dart';
import 'package:teleconference_app/services/audio_service.dart';
import 'package:teleconference_app/services/speech_service.dart';
import 'package:teleconference_app/services/platform_service.dart';
import 'package:teleconference_app/widgets/participant_view.dart';
import 'package:teleconference_app/widgets/control_panel.dart';
import 'package:teleconference_app/widgets/subtitle_display.dart';
import 'package:teleconference_app/widgets/screen_share_button.dart';
import 'package:teleconference_app/widgets/share_room_dialog.dart';
import 'package:teleconference_app/widgets/chat_panel.dart';
import 'package:teleconference_app/widgets/meeting_settings_dialog.dart';
import 'package:teleconference_app/widgets/platform_adaptive_ui.dart';
import 'package:teleconference_app/screens/device_settings_screen.dart';

class ConferenceScreen extends StatefulWidget {
  final String roomId;
  final String userName;

  const ConferenceScreen({
    Key? key,
    required this.roomId,
    required this.userName,
  }) : super(key: key);

  @override
  _ConferenceScreenState createState() => _ConferenceScreenState();
}

class _ConferenceScreenState extends State<ConferenceScreen> with WidgetsBindingObserver {
  late WebRTCService _webRTCService;
  late AudioService _audioService;
  late SpeechService _speechService;
  late PlatformService _platformService;
  bool _isConnecting = true;
  String? _errorMessage;
  final List<ChatMessage> _chatMessages = [];
  bool _isInBackground = false;
  Timer? _reconnectTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initServices();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Uygulama arka plana geçtiğinde veya ön plana döndüğünde
    if (state == AppLifecycleState.paused) {
      _isInBackground = true;
      _handleAppBackground();
    } else if (state == AppLifecycleState.resumed && _isInBackground) {
      _isInBackground = false;
      _handleAppForeground();
    }
  }

  void _handleAppBackground() {
    // Arka planda video akışını durdur (pil tasarrufu)
    if (_webRTCService.isVideoEnabled) {
      _webRTCService.toggleVideo();
    }
    
    // Bağlantıyı canlı tutmak için periyodik ping gönder
    _reconnectTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _webRTCService.sendPing();
    });
  }

  void _handleAppForeground() {
    // Ön plana döndüğünde video akışını tekrar başlat
    if (!_webRTCService.isVideoEnabled) {
      _webRTCService.toggleVideo();
    }
    
    // Ping zamanlayıcısını iptal et
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  Future<void> _initServices() async {
    _webRTCService = Provider.of<WebRTCService>(context, listen: false);
    _audioService = Provider.of<AudioService>(context, listen: false);
    _speechService = Provider.of<SpeechService>(context, listen: false);
    _platformService = Provider.of<PlatformService>(context, listen: false);

    try {
      // Ekranı açık tut
      await _platformService.enableWakeLock();
      
      // Ses işleme ve konuşma tanıma servislerini başlat
      await _audioService.initialize();
      await _speechService.initialize();

      // Cihaz tipine göre optimizasyon yap
      final videoConstraints = _platformService.getOptimizedVideoConstraints();
      final audioConstraints = _platformService.getOptimizedAudioConstraints();

      // WebRTC servisini başlat ve odaya katıl
      await _webRTCService.initialize(
        videoConstraints: videoConstraints,
        audioConstraints: audioConstraints,
      );
      
      await _webRTCService.joinRoom(
        roomId: widget.roomId,
        userName: widget.userName,
        onSubtitleReceived: _speechService.addRemoteSubtitle,
        onChatMessageReceived: _handleChatMessage,
      );

      // Ses işleme ve konuşma tanıma döngüsünü başlat
      _startAudioProcessingLoop();

      setState(() {
        _isConnecting = false;
      });
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _errorMessage = 'Bağlantı hatası: $e';
      });
    }
  }

  void _startAudioProcessingLoop() {
    Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (!mounted || _isInBackground) {
        return;
      }

      // Mikrofon verisini al ve işle
      final audioData = await _audioService.captureAudio();
      if (audioData != null) {
        // Ses işleme uygula (gürültü engelleme, yankı engelleme)
        final processedAudio = await _audioService.processAudio(audioData);
        
        // İşlenmiş sesi WebRTC üzerinden gönder
        _webRTCService.sendAudio(processedAudio);
        
        // Konuşma tanıma için ses verisini ekle
        _speechService.addAudioData(processedAudio);
      }

      // Konuşma tanıma yap ve altyazı oluştur
      final subtitle = await _speechService.recognizeSpeech();
      if (subtitle != null) {
        // Altyazıyı diğer katılımcılara gönder
        _webRTCService.sendSubtitle(subtitle);
      }
    });
  }

  // Sohbet mesajı alındığında çağrılacak fonksiyon
  void _handleChatMessage(String senderId, String senderName, String message, DateTime timestamp) {
    setState(() {
      _chatMessages.add(ChatMessage(
        senderId: senderId,
        senderName: senderName,
        message: message,
        timestamp: timestamp,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isConnecting) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bağlanıyor...')),
        body: Center(child: PlatformAdaptiveUI.loadingIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hata')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!),
              const SizedBox(height: 16),
              PlatformAdaptiveUI.button(
                text: 'Tekrar Dene',
                onPressed: () {
                  setState(() {
                    _isConnecting = true;
                    _errorMessage = null;
                  });
                  _initServices();
                },
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Oda: ${widget.roomId}'),
        actions: [
          // Ekran paylaşımı butonu
          const ScreenShareButton(),
          
          // Oda bilgisi butonu
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Oda Bilgisi'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Oda ID: ${widget.roomId}'),
                      Text('Kullanıcı: ${widget.userName}'),
                      Text('Katılımcı Sayısı: ${_webRTCService.participants.length}'),
                      const SizedBox(height: 8),
                      Consumer<PlatformService>(
                        builder: (context, platformService, child) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Bağlantı: ${_getConnectionTypeName(platformService.connectionType)}'),
                              if (platformService.batteryLevel < 100)
                                Text('Batarya: ${platformService.batteryLevel}%'),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Kapat'),
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Oda paylaşım butonu
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => ShareRoomDialog(
                  roomId: widget.roomId,
                  serverUrl: 'https://teleconference-app.example.com',
                ),
              );
            },
            tooltip: 'Odayı Paylaş',
          ),
          
          // Ayarlar butonu
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const MeetingSettingsDialog(),
              );
            },
            tooltip: 'Toplantı Ayarları',
          ),
          
          // Cihaz ayarları butonu
          IconButton(
            icon: const Icon(Icons.devices),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeviceSettingsScreen(),
                ),
              );
            },
            tooltip: 'Cihaz Ayarları',
          ),
        ],
      ),
      body: Column(
        children: [
          // Katılımcı görüntüleri
          Expanded(
            child: Consumer<WebRTCService>(
              builder: (context, webRTCService, child) {
                return GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3/4,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                  ),
                  itemCount: webRTCService.participants.length,
                  itemBuilder: (context, index) {
                    final participant = webRTCService.participants[index];
                    return ParticipantView(
                      participant: participant,
                      isLocal: participant.id == webRTCService.localParticipantId,
                    );
                  },
                );
              },
            ),
          ),
          
          // Altyazı gösterimi
          Consumer<SpeechService>(
            builder: (context, speechService, child) {
              return SubtitleDisplay(
                subtitles: speechService.subtitles,
              );
            },
          ),
          
          // Sohbet paneli
          const ChatPanel(),
          
          // Kontrol paneli
          ControlPanel(
            onToggleMute: _webRTCService.toggleMute,
            onToggleVideo: _webRTCService.toggleVideo,
            onToggleSpeaker: _webRTCService.toggleSpeaker,
            onLeaveRoom: () {
              _webRTCService.leaveRoom();
              _platformService.disableWakeLock();
              Navigator.pop(context);
            },
            isMuted: _webRTCService.isMuted,
            isVideoEnabled: _webRTCService.isVideoEnabled,
            isSpeakerOn: _webRTCService.isSpeakerOn,
          ),
        ],
      ),
    );
  }

  String _getConnectionTypeName(ConnectivityResult connectionType) {
    switch (connectionType) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobil Veri';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.none:
        return 'Bağlantı Yok';
      default:
        return 'Bilinmeyen';
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reconnectTimer?.cancel();
    _webRTCService.leaveRoom();
    _audioService.dispose();
    _speechService.dispose();
    _platformService.disableWakeLock();
    super.dispose();
  }
}