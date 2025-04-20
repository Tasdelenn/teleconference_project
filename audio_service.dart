import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:teleconference_app/ffi.dart';

class AudioService extends ChangeNotifier {
  bool _isInitialized = false;
  bool _isProcessing = false;
  late FlutterSoundRecorder _recorder;
  late FlutterSoundPlayer _player;
  StreamSubscription? _recorderSubscription;
  final List<double> _audioBuffer = [];
  final int _sampleRate = 48000;
  final int _bufferSize = 4096;

  bool get isInitialized => _isInitialized;
  bool get isProcessing => _isProcessing;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // İzinleri kontrol et
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw Exception('Mikrofon izni reddedildi');
    }

    // Rust ses işleme modülünü başlat
    final result = await api.initializeAudioProcessor();
    if (!result) {
      throw Exception('Ses işleme modülü başlatılamadı');
    }

    // Flutter Sound kaydedici ve oynatıcıyı başlat
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
    
    await _recorder.openRecorder();
    await _player.openPlayer();

    // Kaydedici aboneliği oluştur
    await startRecording();

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> startRecording() async {
    if (!_recorder.isOpen()) {
      await _recorder.openRecorder();
    }

    await _recorder.startRecorder(
      toStream: true,
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: _sampleRate,
    );

    _recorderSubscription = _recorder.onProgress!.listen((event) {
      if (event.decibels != null) {
        // Ses seviyesi değişikliklerini bildir
        notifyListeners();
      }
    });
  }

  Future<void> stopRecording() async {
    await _recorderSubscription?.cancel();
    await _recorder.stopRecorder();
  }

  Future<List<double>?> captureAudio() async {
    if (!_isInitialized || !_recorder.isRecording) {
      return null;
    }

    // Ses verilerini al (gerçek uygulamada bu, kaydediciden gelen verileri işleyecek)
    // Şimdilik örnek ses verileri oluşturuyoruz
    final audioData = List<double>.filled(_bufferSize, 0.0);
    for (int i = 0; i < _bufferSize; i++) {
      audioData[i] = (i % 100) / 100.0; // Örnek ses dalgası
    }

    return audioData;
  }

  Future<List<double>> processAudio(List<double> audioData) async {
    if (!_isInitialized) {
      throw Exception('Ses işleme modülü başlatılmadı');
    }

    _isProcessing = true;
    notifyListeners();

    try {
      // Rust FFI üzerinden ses işleme
      final processedData = await api.processAudio(audioData);
      
      // İşlenmiş ses verisini tampona ekle
      _audioBuffer.addAll(processedData);
      
      // Tampon boyutu sınırını aşarsa, eski verileri kaldır
      while (_audioBuffer.length > _sampleRate * 5) { // 5 saniyelik tampon
        _audioBuffer.removeRange(0, _sampleRate);
      }
      
      return processedData;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> playProcessedAudio() async {
    if (!_isInitialized || _audioBuffer.isEmpty) {
      return;
    }

    // Float ses verisini Int16 formatına dönüştür
    final Int16List pcmData = Int16List(_audioBuffer.length);
    for (int i = 0; i < _audioBuffer.length; i++) {
      // -1.0 ile 1.0 arasındaki float değerlerini -32768 ile 32767 arasına dönüştür
      pcmData[i] = (_audioBuffer[i] * 32767).toInt();
    }

    // PCM verilerini oynat
    await _player.startPlayer(
      fromDataBuffer: pcmData.buffer.asUint8List(),
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: _sampleRate,
    );
  }

  Future<List<double>> analyzeFrequency(List<double> audioData) async {
    if (!_isInitialized) {
      throw Exception('Ses işleme modülü başlatılmadı');
    }

    // Rust FFI üzerinden frekans analizi
    return await api.analyzeFrequency(audioData);
  }

  @override
  void dispose() {
    _recorderSubscription?.cancel();
    _recorder.closeRecorder();
    _player.closePlayer();
    super.dispose();
  }
}
