import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:teleconference_app/models/room.dart';
import 'package:teleconference_app/models/participant.dart';
import 'package:teleconference_app/services/webrtc_service.dart';
import 'package:teleconference_app/services/audio_service.dart';
import 'package:teleconference_app/services/speech_service.dart';
import 'package:teleconference_app/widgets/participant_view.dart';
import 'package:teleconference_app/widgets/control_panel.dart';
import 'package:teleconference_app/widgets/subtitle_display.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WebRTCService()),
        ChangeNotifierProvider(create: (_) => AudioService()),
        ChangeNotifierProvider(create: (_) => SpeechService()),
      ],
      child: MaterialApp(
        title: 'Telekonferans Uygulaması',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _roomController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
    ].request();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Telekonferans Uygulaması'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'İsminiz',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _roomController,
              decoration: const InputDecoration(
                labelText: 'Oda Adı',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty && _roomController.text.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ConferenceScreen(
                        roomId: _roomController.text,
                        userName: _nameController.text,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lütfen isim ve oda adı girin')),
                  );
                }
              },
              child: const Text('Odaya Katıl'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty) {
                  final roomId = const Uuid().v4().substring(0, 8);
                  _roomController.text = roomId;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Yeni oda oluşturuldu: $roomId')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lütfen önce isminizi girin')),
                  );
                }
              },
              child: const Text('Yeni Oda Oluştur'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _roomController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}

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

class _ConferenceScreenState extends State<ConferenceScreen> {
  late WebRTCService _webRTCService;
  late AudioService _audioService;
  late SpeechService _speechService;
  bool _isConnecting = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    _webRTCService = Provider.of<WebRTCService>(context, listen: false);
    _audioService = Provider.of<AudioService>(context, listen: false);
    _speechService = Provider.of<SpeechService>(context, listen: false);

    try {
      // Ses işleme ve konuşma tanıma servislerini başlat
      await _audioService.initialize();
      await _speechService.initialize();

      // WebRTC servisini başlat ve odaya katıl
      await _webRTCService.initialize();
      await _webRTCService.joinRoom(
        roomId: widget.roomId,
        userName: widget.userName,
        onSubtitleReceived: _speechService.addRemoteSubtitle,
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
      if (!mounted) {
        timer.cancel();
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

  @override
  Widget build(BuildContext context) {
    if (_isConnecting) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bağlanıyor...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hata')),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Oda: ${widget.roomId}'),
        actions: [
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
          
          // Kontrol paneli
          ControlPanel(
            onToggleMute: _webRTCService.toggleMute,
            onToggleVideo: _webRTCService.toggleVideo,
            onToggleSpeaker: _webRTCService.toggleSpeaker,
            onLeaveRoom: () {
              _webRTCService.leaveRoom();
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

  @override
  void dispose() {
    _webRTCService.leaveRoom();
    _audioService.dispose();
    _speechService.dispose();
    super.dispose();
  }
}
