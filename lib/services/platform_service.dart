import 'dart:io';
import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:teleconference_app/services/config_service.dart';

class PlatformService extends ChangeNotifier {
  final ConfigService _configService = ConfigService();
  final Battery _battery = Battery();
  final Connectivity _connectivity = Connectivity();
  final NetworkInfo _networkInfo = NetworkInfo();
  
  bool _isLowBattery = false;
  bool _isBatterySavingEnabled = false;
  bool _isWakeLockEnabled = false;
  ConnectivityResult _connectionType = ConnectivityResult.none;
  String? _wifiIP;
  int _batteryLevel = 100;
  
  // Getter'lar
  bool get isLowBattery => _isLowBattery;
  bool get isBatterySavingEnabled => _isBatterySavingEnabled;
  bool get isWakeLockEnabled => _isWakeLockEnabled;
  ConnectivityResult get connectionType => _connectionType;
  String? get wifiIP => _wifiIP;
  int get batteryLevel => _batteryLevel;
  bool get isOnMobileData => _connectionType == ConnectivityResult.mobile;
  bool get isOnWifi => _connectionType == ConnectivityResult.wifi;
  bool get isConnected => _connectionType != ConnectivityResult.none;
  
  // Singleton pattern
  static final PlatformService _instance = PlatformService._internal();
  
  factory PlatformService() {
    return _instance;
  }
  
  PlatformService._internal();
  
  // Servisi başlat
  Future<void> initialize() async {
    // Yapılandırma servisinin başlatılmasını bekle
    if (!_configService.isInitialized) {
      await _configService.initialize();
    }
    
    // Platform özelliklerini kontrol et
    if (Platform.isAndroid || Platform.isIOS) {
      // Batarya durumunu kontrol et
      _batteryLevel = await _battery.batteryLevel;
      _isLowBattery = _batteryLevel < 20;
      
      // Batarya tasarruf modunu kontrol et (Android)
      if (Platform.isAndroid) {
        _isBatterySavingEnabled = await _battery.isInBatterySaveMode;
      }
      
      // Batarya durumu değişikliklerini dinle
      _battery.onBatteryStateChanged.listen((BatteryState state) async {
        _batteryLevel = await _battery.batteryLevel;
        _isLowBattery = _batteryLevel < 20;
        
        if (Platform.isAndroid) {
          _isBatterySavingEnabled = await _battery.isInBatterySaveMode;
        }
        
        notifyListeners();
      });
    }
    
    // Bağlantı durumunu kontrol et
    _connectionType = await _connectivity.checkConnectivity();
    
    // WiFi IP adresini al
    if (_connectionType == ConnectivityResult.wifi) {
      _wifiIP = await _networkInfo.getWifiIP();
    }
    
    // Bağlantı değişikliklerini dinle
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) async {
      _connectionType = result;
      
      if (result == ConnectivityResult.wifi) {
        _wifiIP = await _networkInfo.getWifiIP();
      } else {
        _wifiIP = null;
      }
      
      notifyListeners();
    });
  }
  
  // Ekranı açık tut
  Future<void> enableWakeLock() async {
    if (!_isWakeLockEnabled) {
      await WakelockPlus.enable();
      _isWakeLockEnabled = true;
      notifyListeners();
    }
  }
  
  // Ekran açık tutmayı kapat
  Future<void> disableWakeLock() async {
    if (_isWakeLockEnabled) {
      await WakelockPlus.disable();
      _isWakeLockEnabled = false;
      notifyListeners();
    }
  }
  
  // Cihaz tipine göre video kalitesini optimize et
  Map<String, dynamic> getOptimizedVideoConstraints() {
    final baseConstraints = _configService.getVideoConstraints();
    
    // Düşük pil durumunda veya mobil veri kullanılıyorsa kaliteyi düşür
    if (_isLowBattery || _isBatterySavingEnabled || _connectionType == ConnectivityResult.mobile) {
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
    }
    
    return baseConstraints;
  }
  
  // Cihaz tipine göre ses kalitesini optimize et
  Map<String, dynamic> getOptimizedAudioConstraints() {
    final baseConstraints = _configService.getAudioConstraints();
    
    // Düşük pil durumunda veya mobil veri kullanılıyorsa kaliteyi düşür
    if (_isLowBattery || _isBatterySavingEnabled || _connectionType == ConnectivityResult.mobile) {
      return {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
        'sampleRate': 22050,
        'channelCount': 1,
      };
    }
    
    return baseConstraints;
  }
  
  // Cihaz durumuna göre önerilen ayarları al
  Map<String, dynamic> getRecommendedSettings() {
    return {
      'videoEnabled': !_isLowBattery && _batteryLevel > 30,
      'audioProcessingLevel': _isLowBattery ? 'low' : 'high',
      'useHardwareAcceleration': !_isLowBattery && !_isBatterySavingEnabled,
      'enableBackgroundBlur': !_isLowBattery && !_isBatterySavingEnabled && _batteryLevel > 50,
      'enableNoiseReduction': true,
      'enableEchoCancellation': true,
      'enableAutoGainControl': true,
    };
  }
  
  // Kaynakları temizle
  @override
  void dispose() {
    disableWakeLock();
    super.dispose();
  }
}