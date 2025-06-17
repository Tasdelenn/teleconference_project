import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teleconference_app/services/audio_service.dart';
import 'package:teleconference_app/services/webrtc_service.dart';
import 'package:teleconference_app/audio_controls_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AudioService()),
        ChangeNotifierProvider(create: (_) => WebRTCService()),
      ],
      child: MaterialApp(
        title: 'Telekonferans Uygulaması',
        theme: ThemeData(
          primarySwatch: Colors.blue,
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
  bool _isInitializing = true;
  String? _errorMessage;
  final TextEditingController _roomIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      final audioService = Provider.of<AudioService>(context, listen: false);
      await audioService.initialize();
      
      final webrtcService = Provider.of<WebRTCService>(context, listen: false);
      await webrtcService.initialize();
      
      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Telekonferans Uygulaması'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Hata'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _initializeServices,
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: TextField(
                controller: _roomIdController,
                decoration: const InputDecoration(
                  labelText: 'Oda ID',
                  hintText: 'Katılmak istediğiniz odanın ID\'sini girin',
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final roomId = _roomIdController.text.trim();
                if (roomId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lütfen bir oda ID\'si girin')),
                  );
                  return;
                }
                
                final webrtcService = Provider.of<WebRTCService>(context, listen: false);
                webrtcService.connect('ws://127.0.0.1:8080/ws', roomId);
                
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AudioControlsScreen()),
                );
              },
              child: const Text('Odaya Katıl'),
            ),
            const SizedBox(height: 20),
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
  
  @override
  void dispose() {
    _roomIdController.dispose();
    super.dispose();
  }
}
