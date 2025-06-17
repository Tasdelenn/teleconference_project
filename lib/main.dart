import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:teleconference_app/services/webrtc_service.dart';
import 'package:teleconference_app/services/audio_service.dart';
import 'package:teleconference_app/services/speech_service.dart';
import 'package:teleconference_app/services/config_service.dart';
import 'package:teleconference_app/services/platform_service.dart';
import 'package:teleconference_app/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  // Yapılandırma ve platform servislerini başlat
  final configService = ConfigService();
  await configService.initialize();
  
  final platformService = PlatformService();
  await platformService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConfigService()),
        ChangeNotifierProvider(create: (_) => PlatformService()),
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