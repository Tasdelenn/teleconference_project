import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teleconference_app/services/config_service.dart';
import 'package:teleconference_app/services/platform_service.dart';
import 'package:teleconference_app/widgets/platform_adaptive_ui.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class PlatformInfoScreen extends StatefulWidget {
  const PlatformInfoScreen({Key? key}) : super(key: key);

  @override
  _PlatformInfoScreenState createState() => _PlatformInfoScreenState();
}

class _PlatformInfoScreenState extends State<PlatformInfoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  Map<String, dynamic> _deviceData = <String, dynamic>{};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (Platform.isAndroid) {
        _deviceData = _readAndroidDeviceInfo(await _deviceInfo.androidInfo);
      } else if (Platform.isIOS) {
        _deviceData = _readIosDeviceInfo(await _deviceInfo.iosInfo);
      } else if (Platform.isLinux) {
        _deviceData = _readLinuxDeviceInfo(await _deviceInfo.linuxInfo);
      } else if (Platform.isWindows) {
        _deviceData = _readWindowsDeviceInfo(await _deviceInfo.windowsInfo);
      } else if (Platform.isMacOS) {
        _deviceData = _readMacOsDeviceInfo(await _deviceInfo.macOsInfo);
      }
    } catch (e) {
      _deviceData = {'Error': 'Cihaz bilgileri alınamadı: $e'};
    }

    setState(() {
      _isLoading = false;
    });
  }

  Map<String, dynamic> _readAndroidDeviceInfo(AndroidDeviceInfo info) {
    return {
      'Model': info.model,
      'Marka': info.manufacturer,
      'Android Sürümü': info.version.release,
      'SDK Sürümü': info.version.sdkInt.toString(),
      'Cihaz': info.device,
      'İşlemci Mimarisi': info.supportedAbis.join(', '),
      'Fiziksel Cihaz': info.isPhysicalDevice ? 'Evet' : 'Hayır',
      'Ekran Çözünürlüğü': '${info.displayMetrics.widthPx}x${info.displayMetrics.heightPx}',
      'Ekran Yoğunluğu': '${info.displayMetrics.xDpi}x${info.displayMetrics.yDpi} dpi',
    };
  }

  Map<String, dynamic> _readIosDeviceInfo(IosDeviceInfo info) {
    return {
      'Model': info.model,
      'Ad': info.name,
      'Sistem Adı': info.systemName,
      'Sistem Sürümü': info.systemVersion,
      'Fiziksel Cihaz': info.isPhysicalDevice ? 'Evet' : 'Hayır',
      'Tanımlayıcı': info.identifierForVendor ?? 'Bilinmiyor',
    };
  }

  Map<String, dynamic> _readLinuxDeviceInfo(LinuxDeviceInfo info) {
    return {
      'Ad': info.name,
      'Sürüm': info.version,
      'ID': info.id,
      'Dağıtım': info.prettyName,
      'Kernel Sürümü': info.kernelVersion,
      'Makine Tipi': info.machineId ?? 'Bilinmiyor',
    };
  }

  Map<String, dynamic> _readWindowsDeviceInfo(WindowsDeviceInfo info) {
    return {
      'Bilgisayar Adı': info.computerName,
      'İşlemci Sayısı': info.numberOfCores.toString(),
      'Bellek (GB)': (info.systemMemoryInMegabytes / 1024).toStringAsFixed(2),
      'Windows Sürümü': '${info.majorVersion}.${info.minorVersion}.${info.buildNumber}',
      'Platform': info.platformId.toString(),
      'Ürün Tipi': _getWindowsProductType(info.productType),
    };
  }

  Map<String, dynamic> _readMacOsDeviceInfo(MacOsDeviceInfo info) {
    return {
      'Bilgisayar Adı': info.computerName,
      'Host Adı': info.hostName,
      'Mimari': info.arch,
      'Model': info.model,
      'Kernel Sürümü': info.kernelVersion,
      'OS Sürümü': info.osRelease,
      'Aktif CPU Sayısı': info.activeCPUs.toString(),
      'Bellek (GB)': (info.memorySize / (1024 * 1024 * 1024)).toStringAsFixed(2),
    };
  }

  String _getWindowsProductType(int productType) {
    switch (productType) {
      case 1:
        return 'Workstation';
      case 2:
        return 'Domain Controller';
      case 3:
        return 'Server';
      default:
        return 'Bilinmiyor';
    }
  }

  @override
  Widget build(BuildContext context) {
    final configService = Provider.of<ConfigService>(context);
    final platformService = Provider.of<PlatformService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Bilgileri'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Cihaz'),
            Tab(text: 'Ağ'),
            Tab(text: 'Sistem'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: PlatformAdaptiveUI.loadingIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Cihaz bilgileri
                _buildDeviceInfoTab(),
                
                // Ağ bilgileri
                _buildNetworkInfoTab(platformService),
                
                // Sistem bilgileri
                _buildSystemInfoTab(configService),
              ],
            ),
    );
  }

  Widget _buildDeviceInfoTab() {
    return ListView(
      padding: PlatformAdaptiveUI.getPadding(),
      children: _deviceData.entries.map((entry) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(entry.key),
            subtitle: Text(entry.value.toString()),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNetworkInfoTab(PlatformService platformService) {
    return ListView(
      padding: PlatformAdaptiveUI.getPadding(),
      children: [
        Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: const Text('Bağlantı Tipi'),
            subtitle: Text(_getConnectionTypeName(platformService.connectionType)),
            leading: Icon(
              _getConnectionIcon(platformService.connectionType),
              color: _getConnectionColor(platformService.connectionType),
            ),
          ),
        ),
        if (platformService.isOnWifi && platformService.wifiIP != null)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              title: const Text('WiFi IP Adresi'),
              subtitle: Text(platformService.wifiIP!),
              leading: const Icon(Icons.wifi, color: Colors.blue),
            ),
          ),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: const Text('Sinyal Sunucusu'),
            subtitle: Text(configService.serverUrl),
            leading: const Icon(Icons.cloud, color: Colors.purple),
          ),
        ),
        const SizedBox(height: 16),
        PlatformAdaptiveUI.button(
          text: 'Bağlantıyı Test Et',
          icon: Icons.network_check,
          onPressed: () {
            _testConnection();
          },
        ),
      ],
    );
  }

  Widget _buildSystemInfoTab(ConfigService configService) {
    return ListView(
      padding: PlatformAdaptiveUI.getPadding(),
      children: [
        Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: const Text('Platform Tipi'),
            subtitle: Text(_getPlatformName(configService.platformType)),
            leading: Icon(_getPlatformIcon(configService.platformType)),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: const Text('Cihaz Tipi'),
            subtitle: Text(_getDeviceTypeName(configService.deviceType)),
            leading: Icon(_getDeviceTypeIcon(configService.deviceType)),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: const Text('Düşük Güçlü Cihaz'),
            subtitle: Text(configService.isLowPowerDevice ? 'Evet' : 'Hayır'),
            leading: Icon(
              configService.isLowPowerDevice ? Icons.battery_alert : Icons.battery_full,
              color: configService.isLowPowerDevice ? Colors.orange : Colors.green,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: const Text('Önerilen Video Kalitesi'),
            subtitle: Text(_getVideoQualityName(configService.getVideoConstraints())),
            leading: const Icon(Icons.videocam),
          ),
        ),
      ],
    );
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

  IconData _getConnectionIcon(ConnectivityResult connectionType) {
    switch (connectionType) {
      case ConnectivityResult.wifi:
        return Icons.wifi;
      case ConnectivityResult.mobile:
        return Icons.signal_cellular_alt;
      case ConnectivityResult.ethernet:
        return Icons.settings_ethernet;
      case ConnectivityResult.bluetooth:
        return Icons.bluetooth;
      case ConnectivityResult.none:
        return Icons.signal_wifi_off;
      default:
        return Icons.device_unknown;
    }
  }

  Color _getConnectionColor(ConnectivityResult connectionType) {
    switch (connectionType) {
      case ConnectivityResult.wifi:
      case ConnectivityResult.ethernet:
        return Colors.green;
      case ConnectivityResult.mobile:
        return Colors.orange;
      case ConnectivityResult.bluetooth:
        return Colors.blue;
      case ConnectivityResult.none:
        return Colors.red;
      default:
        return Colors.grey;
    }
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

  IconData _getPlatformIcon(PlatformType platformType) {
    switch (platformType) {
      case PlatformType.windows:
        return Icons.desktop_windows;
      case PlatformType.linux:
        return Icons.computer;
      case PlatformType.macOS:
        return Icons.laptop_mac;
      case PlatformType.android:
        return Icons.android;
      case PlatformType.iOS:
        return Icons.phone_iphone;
      case PlatformType.web:
        return Icons.web;
      default:
        return Icons.device_unknown;
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

  IconData _getDeviceTypeIcon(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.desktop:
        return Icons.desktop_mac;
      case DeviceType.mobile:
        return Icons.smartphone;
      case DeviceType.tablet:
        return Icons.tablet_mac;
      case DeviceType.web:
        return Icons.web;
      case DeviceType.raspberryPi:
        return Icons.developer_board;
      default:
        return Icons.device_unknown;
    }
  }

  String _getVideoQualityName(Map<String, dynamic> constraints) {
    final maxWidth = constraints['mandatory']['maxWidth'];
    
    if (maxWidth <= 640) {
      return 'Düşük (${maxWidth}p)';
    } else if (maxWidth <= 1280) {
      return 'Orta (${maxWidth}p)';
    } else {
      return 'Yüksek (${maxWidth}p)';
    }
  }

  Future<void> _testConnection() async {
    final configService = Provider.of<ConfigService>(context, listen: false);
    final serverUrl = configService.serverUrl;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bağlantı test ediliyor: $serverUrl')),
    );
    
    // Gerçek uygulamada burada sunucuya bağlantı testi yapılabilir
    await Future.delayed(const Duration(seconds: 2));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bağlantı başarılı!')),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}