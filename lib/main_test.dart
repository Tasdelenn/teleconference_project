import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teleconference_app/services/audio_service.dart';
import 'package:teleconference_app/widgets/control_panel.dart';

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
      ],
      child: MaterialApp(
        title: 'Telekonferans Test',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const TestScreen(),
      ),
    );
  }
}

class TestScreen extends StatelessWidget {
  const TestScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Telekonferans Test'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Text(
                'Telekonferans Test Uygulaması',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          ControlPanel(
            onToggleMute: () {},
            onToggleVideo: () {},
            onToggleSpeaker: () {},
            onLeaveRoom: () {},
            isMuted: false,
            isVideoEnabled: true,
            isSpeakerOn: true,
          ),
        ],
      ),
    );
  }
}
