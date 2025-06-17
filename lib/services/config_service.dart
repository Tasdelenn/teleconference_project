import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum DeviceType {
  desktop,
  mobile,
  tablet,
  web,
  raspberryPi,
  unknown
}

enum PlatformType {
  windows,
  linux,
  macOS,
  android,
  iOS,
  web,
  unknown
}

class ConfigService extends ChangeNotifier {
  late SharedPreferences _prefs;
  late DeviceType _deviceType;
  late PlatformType _platformType;
  late bool _isLowPowerDevice;
  String _serverUrl = '';
  bool _isInitialized = false;
  
  // Getter'lar
  DeviceType get deviceType => _deviceType;
  PlatformType get platformType => _platformType;
  bool get isLowPowerDevice => _isLowPowerDevice;
  String get serverUrl => _serverUrl;
  bool get isInitialized => _isInitialized;
  
  // Singleton pattern
  static final ConfigService _instance = ConfigService._internal();
  
  factory ConfigService() {
    return _instance;
  }
  
  ConfigService._internal();
  
  // Servisi başlat
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // SharedPreferences'ı başlat
      _prefs = await SharedPreferences.getInstance();
      
      // Platform ve cihaz tipini belirle
      await _detectPlatformAndDevice();
      
      // Sunucu URL'sini yükle
      await _loadServerUrl();
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('ConfigService başlatılamadı: $e');
      rethrow;
    }
  }
  
  // Platform ve cihaz tipini belirle
  Future<void> _detectPlatformAndDevice() async {
    final deviceInfo = DeviceInfoPlugin();
    
    // Platform tipini belirle
    if (Platform.isWindows) {
      _platformType = PlatformType.windows;
    } else if (Platform.isLinux) {
      _platformType = PlatformType.linux;
    } else if (Platform.isMacOS) {
      _platformType = PlatformType.macOS;
    } else if (Platform.isAndroid) {
      _platformType = PlatformType.android;
    } else if (Platform.isIOS) {
      _platformType = PlatformType.iOS;
    } else {
      _platformType = PlatformType.unknown;
    }
    
    // Cihaz tipini belirle
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      final screenSize = androidInfo.displayMetrics.widthPx * androidInfo.displayMetrics.heightPx;
      final isTablet = screenSize > 1000000; // 1 milyon piksel üzeri tablet kabul et
      
      _deviceType = isTablet ? DeviceType.tablet : DeviceType.mobile;
      
      // Düşük güçlü cihaz kontrolü
      _isLowPowerDevice = androidInfo.supportedAbis.contains('armeabi-v7a') && 
                          !androidInfo.supportedAbis.contains('arm64-v8a');
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      final isTablet = iosInfo.model.toLowerCase().contains('ipad');
      
      _deviceType = isTablet ? DeviceType.tablet : DeviceType.mobile;
      _isLowPowerDevice = false; // iOS cihazlar genelde yeterince güçlü
    } else if (Platform.isLinux) {
      final linuxInfo = await deviceInfo.linuxInfo;
      
      // Raspberry Pi kontrolü
      if (linuxInfo.prettyName.toLowerCase().contains('raspberry')) {
        _deviceType = DeviceType.raspberryPi;
        _isLowPowerDevice = true;
      } else {
        _deviceType = DeviceType.desktop;
        _isLowPowerDevice = false;
      }
    } else {
      _deviceType = DeviceType.desktop;
      _isLowPowerDevice = false;
    }
  }
  
  // Sunucu URL'sini yükle
  Future<void> _loadServerUrl() async {
    // Önce SharedPreferences'dan yükle
    _serverUrl = _prefs.getString('server_url') ?? '';
    
    // Eğer boşsa .env dosyasından yükle
    if (_serverUrl.isEmpty) {
      _serverUrl = dotenv.env['SERVER_URL'] ?? '';
    }
    
    // Hala boşsa varsayılan değeri kullan
    if (_serverUrl.isEmpty) {
      _serverUrl = 'ws://192.168.1.41:8080';
    }
  }
  
  // Sunucu URL'sini ayarla
  Future<void> setServerUrl(String url) async {
    _serverUrl = url;
    await _prefs.setString('server_url', url);
    notifyListeners();
  }
  
  // Cihaz tipine göre video kalitesi ayarları
  Map<String, dynamic> getVideoConstraints() {
    if (_isLowPowerDevice) {
      // Düşük güçlü cihazlar için düşük kalite
      return {
        'mandatory': {
          'minWidth': 320,
          'minHeight': 240,
          'maxWidth': 640,
          'maxHeight': 480,
          'minFrameRate': 15,
          'maxFrameRate': 24,
        }
      };
    } else if (_deviceType == DeviceType.mobile || _deviceType == DeviceType.tablet) {
      // Mobil cihazlar için orta kalite
      return {
        'mandatory': {
          'minWidth': 640,
          'minHeight': 480,
          'maxWidth': 1280,
          'maxHeight': 720,
          'minFrameRate': 24,
          'maxFrameRate': 30,
        }
      };
    } else {
      // Masaüstü cihazlar için yüksek kalite
      return {
        'mandatory': {
          'minWidth': 1280,
          'minHeight': 720,
          'maxWidth': 1920,
          'maxHeight': 1080,
          'minFrameRate': 30,
          'maxFrameRate': 60,
        }
      };
    }
  }
  
  // Cihaz tipine göre ses kalitesi ayarları
  Map<String, dynamic> getAudioConstraints() {
    if (_isLowPowerDevice) {
      // Düşük güçlü cihazlar için temel ses ayarları
      return {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
        'sampleRate': 22050,
        'channelCount': 1,
      };
    } else {
      // Güçlü cihazlar için yüksek kalite ses ayarları
      return {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
        'sampleRate': 48000,
        'channelCount': 2,
      };
    }
  }
  
  // Cihaz tipine göre UI ölçekleme faktörü
  double getUIScaleFactor() {
    switch (_deviceType) {
      case DeviceType.mobile:
        return 0.85;
      case DeviceType.tablet:
        return 1.0;
      case DeviceType.desktop:
        return 1.1;
      case DeviceType.raspberryPi:
        return 1.2;
      default:
        return 1.0;
    }
  }
}