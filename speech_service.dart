import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:teleconference_app/ffi.dart';

class SpeechService extends ChangeNotifier {
  bool _isInitialized = false;
  bool _isRecognizing = false;
  final Map<String, String> _subtitles = {};
  final List<double> _audioBuffer = [];
  Timer? _recognitionTimer;
  String _currentText = '';
  final int _recognitionInterval = 2000; // 2 saniyede bir tanıma yap

  bool get isInitialized => _isInitialized;
  bool get isRecognizing => _isRecognizing;
  Map<String, String> get subtitles => _subtitles;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Rust konuşma tanıma modülünü başlat
    final result = await api.initializeSpeechRecognizer();
    if (!result) {
      throw Exception('Konuşma tanıma modülü başlatılamadı');
    }

    // Periyodik konuşma tanıma zamanlayıcısını başlat
    _startRecognitionTimer();

    _isInitialized = true;
    notifyListeners();
  }

  void _startRecognitionTimer() {
    _recognitionTimer = Timer.periodic(
      Duration(milliseconds: _recognitionInterval),
      (_) async {
        await recognizeSpeech();
      },
    );
  }

  void addAudioData(List<double> audioData) {
    if (!_isInitialized) return;

    // Ses verisini tampona ekle
    _audioBuffer.addAll(audioData);
    
    // Tampon boyutu sınırını aşarsa, eski verileri kaldır
    while (_audioBuffer.length > 48000 * 5) { // 5 saniyelik tampon (48kHz)
      _audioBuffer.removeRange(0, 48000);
    }
  }

  Future<String?> recognizeSpeech() async {
    if (!_isInitialized || _audioBuffer.isEmpty || _isRecognizing) {
      return null;
    }

    _isRecognizing = true;
    notifyListeners();

    try {
      // Rust FFI üzerinden konuşma tanıma
      final result = await api.recognizeSpeech();
      
      if (result != null && result.isNotEmpty) {
        // Yeni tanınan metni mevcut metne ekle
        if (_currentText.isEmpty) {
          _currentText = result;
        } else {
          _currentText += ' ' + result;
        }
        
        // Yerel altyazıyı güncelle
        _subtitles['Sen'] = _currentText;
        notifyListeners();
        
        return result;
      }
      
      return null;
    } finally {
      _isRecognizing = false;
      notifyListeners();
    }
  }

  void addRemoteSubtitle(String userId, String userName, String text) {
    _subtitles[userName] = text;
    notifyListeners();
  }

  void clearSubtitles() {
    _subtitles.clear();
    _currentText = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _recognitionTimer?.cancel();
    super.dispose();
  }
}
