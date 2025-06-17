import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teleconference_app/services/config_service.dart';
import 'package:teleconference_app/services/platform_service.dart';
import 'package:teleconference_app/widgets/platform_adaptive_ui.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class DeviceSettingsScreen extends StatefulWidget {
  const DeviceSettingsScreen({Key? key}) : super(key: key);

  @override
  _DeviceSettingsScreenState createState() => _DeviceSettingsScreenState();
}

class _DeviceSettingsScreenState extends State<DeviceSettingsScreen> {
  final TextEditingController _serverUrlController = TextEditingController();
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    final configService = Provider.of<ConfigService>(context, listen: false);
    
    // Yapılandırma servisinin başlatılmasını bekle
    if (!configService.isInitialized) {
      await configService.initialize();
    }
    
    // Platform servisinin başlatılmasını bekle
    final platformService = Provider.of<PlatformService>(context, listen: false);
    await platformService.initialize();
    
    // Sunucu URL'sini yükle
    _serverUrlController.text = configService.serverUrl;
    
    setState(() {
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cihaz Ayarları'),
      ),
      body: _isLoading
          ? Center(child: PlatformAdaptiveUI.loadingIndicator())
          : SingleChildScrollView(
              padding: PlatformAdaptiveUI.getPadding(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cihaz bilgileri
                  _buildDeviceInfoSection(),
                  
                  const Divider(height: 32),
                  
                  // Sunucu ayarları
                  _buildServerSettingsSection(),
                  
                  const Divider(height: 32),
                  
                  // Performans ayarları
                  _buildPerformanceSettingsSection(),
                  
                  const Divider(height: 32),
                  
                  // Bağlantı bilgileri
                  _buildConnectionInfoSection(),
                ],
              ),
            ),
    );
  }
  
  Widget _buildDeviceInfoSection() {
    final configService = Provider.of<ConfigService>(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cihaz Bilgileri',
          style: TextStyle(
            fontSize: PlatformAdaptiveUI.getFontSize(baseSize: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          'Platform',
          _getPlatformName(configService.platformType),
        ),
        _buildInfoRow(
          'Cihaz Tipi',
          _getDeviceTypeName(configService.deviceType),
        ),
        _buildInfoRow(
          'Düşük Güçlü Cihaz',
          configService.isLowPowerDevice ? 'Evet' : 'Hayır',
        ),
      ],
    );
  }
  
  Widget _buildServerSettingsSection() {
    final configService = Provider.of<ConfigService>(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sunucu Ayarları',
          style: TextStyle(
            fontSize: PlatformAdaptiveUI.getFontSize(baseSize: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        PlatformAdaptiveUI.textField(
          controller: _serverUrlController,
          labelText: 'Sinyal Sunucusu URL',
          hintText: 'ws://192.168.1.41:8080',
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PlatformAdaptiveUI.button(
              text: 'Varsayılana Sıfırla',
              onPressed: () {
                _serverUrlController.text = 'ws://192.168.1.41:8080';
              },
            ),
            const SizedBox(width: 16),
            PlatformAdaptiveUI.button(
              text: 'Kaydet',
              onPressed: () async {
                if (_serverUrlController.text.isNotEmpty) {
                  await configService.setServerUrl(_serverUrlController.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sunucu URL\'si kaydedildi')),
                  );
                }
              },
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildPerformanceSettingsSection() {
    final platformService = Provider.of<PlatformService>(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performans Ayarları',
          style: TextStyle(
            fontSize: PlatformAdaptiveUI.getFontSize(baseSize: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          title: const Text('Ekranı Açık Tut'),
          subtitle: const Text('Toplantı sırasında ekranın kapanmasını engelle'),
          trailing: PlatformAdaptiveUI.switchWidget(
            value: platformService.isWakeLockEnabled,
            onChanged: (value) {
              if (value) {
                platformService.enableWakeLock();
              } else {
                platformService.disableWakeLock();
              }
            },
          ),
        ),
        const SizedBox(height: 8),
        ListTile(
          title: const Text('Otomatik Kalite Ayarı'),
          subtitle: const Text('Bağlantı ve pil durumuna göre video kalitesini otomatik ayarla'),
          trailing: PlatformAdaptiveUI.switchWidget(
            value: true, // Bu özellik şu an için her zaman açık
            onChanged: (value) {
              // Bu özellik şu an için değiştirilemez
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildConnectionInfoSection() {
    final platformService = Provider.of<PlatformService>(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bağlantı Bilgileri',
          style: TextStyle(
            fontSize: PlatformAdaptiveUI.getFontSize(baseSize: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          'Bağlantı Tipi',
          _getConnectionTypeName(platformService.connectionType),
        ),
        if (platformService.isOnWifi && platformService.wifiIP != null)
          _buildInfoRow('WiFi IP', platformService.wifiIP!),
        _buildInfoRow(
          'Batarya Seviyesi',
          '${platformService.batteryLevel}%',
        ),
        _buildInfoRow(
          'Düşük Pil Modu',
          platformService.isBatterySavingEnabled ? 'Açık' : 'Kapalı',
        ),
      ],
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
  
  String _getPlatformName(PlatformType platformType) {
    switch (platformType) {
      case PlatformType.windows:
        return 'Windows';
      case PlatformType.linux:
        return 'Linux';
      case PlatformType.macOS:
        return 'macOS';
      case PlatformType.android:
        return 'Android';
      case PlatformType.iOS:
        return 'iOS';
      case PlatformType.web:
        return 'Web';
      default:
        return 'Bilinmeyen';
    }
  }
  
  String _getDeviceTypeName(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.desktop:
        return 'Masaüstü';
      case DeviceType.mobile:
        return 'Mobil';
      case DeviceType.tablet:
        return 'Tablet';
      case DeviceType.web:
        return 'Web';
      case DeviceType.raspberryPi:
        return 'Raspberry Pi';
      default:
        return 'Bilinmeyen';
    }
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
    _serverUrlController.dispose();
    super.dispose();
  }
}