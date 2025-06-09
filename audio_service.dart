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

enum AudioProcessingMode {
  standard,
  noiseReduction,
  voiceEnhancement,
  fullDuplex,
  custom
}

enum MicrophoneMode {
  directional,
  omnidirectional, // 360° ses alma
  cardioid,
  beamforming
}

class AudioService extends ChangeNotifier {
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _isMuted = false;
  late FlutterSoundRecorder _recorder;
  late FlutterSoundPlayer _player;
  StreamSubscription? _recorderSubscription;
  final List<double> _audioBuffer = [];
  final int _sampleRate = 48000;
  final int _bufferSize = 4096;
  
  // Yeni özellikler
  AudioProcessingMode _processingMode = AudioProcessingMode.standard;
  MicrophoneMode _microphoneMode = MicrophoneMode.omnidirectional;
  int _volumeLevel = 5; // 1-9 arası ses seviyesi
  bool _echoCancel = true;
  bool _noiseReduction = true;
  bool _autoGainControl = true;
  bool _privacyMode = false;
  
  // USB cihaz yönetimi
  String? _connectedDeviceId;
  String? _connectedDeviceType;
  bool _isUsbConnected = false;

  bool get isInitialized => _isInitialized;
  bool get isProcessing => _isProcessing;
  bool get isMuted => _isMuted;
  AudioProcessingMode get processingMode => _processingMode;
  MicrophoneMode get microphoneMode => _microphoneMode;
  int get volumeLevel => _volumeLevel;
  bool get echoCancel => _echoCancel;
  bool get noiseReduction => _noiseReduction;
  bool get autoGainControl => _autoGainControl;
  bool get privacyMode => _privacyMode;
  bool get isUsbConnected => _isUsbConnected;
  String? get connectedDeviceId => _connectedDeviceId;
  String? get connectedDeviceType => _connectedDeviceType;

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
    
    // USB cihazları algıla
    await _detectAudioDevices();

    _isInitialized = true;
    notifyListeners();
  }

  // USB ve diğer ses cihazlarını algıla
  Future<void> _detectAudioDevices() async {
    try {
      // Burada platform-specific kod kullanarak USB cihazları algılayabiliriz
      // Örnek olarak, bir USB cihaz bağlandığını varsayalım
      _isUsbConnected = true;
      _connectedDeviceId = "usb-audio-device-1";
      _connectedDeviceType = "USB-C";
      
      // Cihaz özelliklerini ayarla
      await api.configureAudioDevice(_connectedDeviceId!, _connectedDeviceType!);
      
      notifyListeners();
    } catch (e) {
      print("Ses cihazı algılama hatası: $e");
    }
  }

  Future<void> startRecording() async {
    if (!_recorder.isOpen()) {
      await _recorder.openRecorder();
    }

    await _recorder.startRecorder(
      toStream: true,
      codec: Codec.pcm16,
      numChannels: _microphoneMode == MicrophoneMode.omnidirectional ? 2 : 1, // 360° mod için stereo
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
    if (!_isInitialized || !_recorder.isRecording || _isMuted || _privacyMode) {
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
      // İşleme moduna göre parametreleri ayarla
      final processingParams = {
        'mode': _processingMode.index,
        'echoCancel': _echoCancel,
        'noiseReduction': _noiseReduction,
        'autoGainControl': _autoGainControl,
        'microphoneMode': _microphoneMode.index,
        'volumeLevel': _volumeLevel,
      };
      
      // Rust FFI üzerinden gelişmiş ses işleme
      final processedData = await api.processAudioAdvanced(
        audioData, 
        processingParams['mode'] as int,
        processingParams['echoCancel'] as bool,
        processingParams['noiseReduction'] as bool,
        processingParams['autoGainControl'] as bool,
        processingParams['microphoneMode'] as int,
        processingParams['volumeLevel'] as int,
      );
      
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

  // Ses seviyesini ayarla (1-9 arası)
  Future<void> setVolumeLevel(int level) async {
    if (level < 1) level = 1;
    if (level > 9) level = 9;
    
    _volumeLevel = level;
    await api.setVolumeLevel(level);
    notifyListeners();
  }
  
  // İşleme modunu değiştir
  Future<void> setProcessingMode(AudioProcessingMode mode) async {
    _processingMode = mode;
    await api.setAudioProcessingMode(mode.index);
    notifyListeners();
  }
  
  // Mikrofon modunu değiştir
  Future<void> setMicrophoneMode(MicrophoneMode mode) async {
    _microphoneMode = mode;
    await api.setMicrophoneMode(mode.index);
    notifyListeners();
  }
  
  // Yankı iptalini aç/kapat
  Future<void> toggleEchoCancel() async {
    _echoCancel = !_echoCancel;
    await api.setEchoCancel(_echoCancel);
    notifyListeners();
  }
  
  // Gürültü azaltmayı aç/kapat
  Future<void> toggleNoiseReduction() async {
    _noiseReduction = !_noiseReduction;
    await api.setNoiseReduction(_noiseReduction);
    notifyListeners();
  }
  
  // Otomatik kazanç kontrolünü aç/kapat
  Future<void> toggleAutoGainControl() async {
    _autoGainControl = !_autoGainControl;
    await api.setAutoGainControl(_autoGainControl);
    notifyListeners();
  }
  
  // Gizlilik modunu aç/kapat
  Future<void> togglePrivacyMode() async {
    _privacyMode = !_privacyMode;
    if (_privacyMode) {
      await stopRecording();
    } else {
      await startRecording();
    }
    notifyListeners();
  }
  
  // Mikrofonu sessize al/aç
  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    notifyListeners();
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
