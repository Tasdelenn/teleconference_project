import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:teleconference_app/services/config_service.dart';
import 'package:teleconference_app/services/platform_service.dart';
import 'package:teleconference_app/widgets/platform_adaptive_ui.dart';
import 'package:teleconference_app/screens/conference_screen.dart';
import 'package:teleconference_app/screens/device_settings_screen.dart';
import 'package:teleconference_app/screens/platform_info_screen.dart';
import 'package:teleconference_app/screens/raspberry_pi_setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _roomController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _loadSettings();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
    ].request();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Yapılandırma ve platform servislerinin başlatılmasını bekle
      final configService = Provider.of<ConfigService>(context, listen: false);
      if (!configService.isInitialized) {
        await configService.initialize();
      }

      final platformService = Provider.of<PlatformService>(context, listen: false);
      await platformService.initialize();

      // Kullanıcı adını SharedPreferences'dan yükle
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString('user_name');
      if (savedName != null && savedName.isNotEmpty) {
        _nameController.text = savedName;
      }
    } catch (e) {
      print('Ayarlar yüklenirken hata: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveUserName() async {
    if (_nameController.text.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', _nameController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final configService = Provider.of<ConfigService>(context);
    final platformService = Provider.of<PlatformService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Telekonferans Uygulaması'),
        actions: [
          // Platform bilgileri butonu
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PlatformInfoScreen(),
                ),
              );
            },
            tooltip: 'Platform Bilgileri',
          ),
          // Cihaz ayarları butonu
          IconButton(
            icon: const Icon(Icons.devices),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeviceSettingsScreen(),
                ),
              );
            },
            tooltip: 'Cihaz Ayarları',
          ),
          // Raspberry Pi ayarları butonu
          IconButton(
            icon: const Icon(Icons.settings_remote),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RaspberryPiSetupScreen(),
                ),
              );
            },
            tooltip: 'Raspberry Pi Ayarları',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: PlatformAdaptiveUI.loadingIndicator())
          : SingleChildScrollView(
              padding: PlatformAdaptiveUI.getPadding(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo veya uygulama adı
                  const SizedBox(height: 32),
                  Icon(
                    Icons.video_call,
                    size: PlatformAdaptiveUI.getIconSize(baseSize: 80),
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Telekonferans Uygulaması',
                    style: TextStyle(
                      fontSize: PlatformAdaptiveUI.getFontSize(baseSize: 24),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Çoklu platform desteği ile gerçek zamanlı görüntülü görüşme',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: PlatformAdaptiveUI.getFontSize(baseSize: 16),
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Cihaz ve bağlantı bilgileri
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Cihaz:'),
                              Text('${_getDeviceTypeName(configService.deviceType)} (${_getPlatformName(configService.platformType)})'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Bağlantı:'),
                              Row(
                                children: [
                                  Icon(
                                    _getConnectionIcon(platformService.connectionType),
                                    size: 16,
                                    color: _getConnectionColor(platformService.connectionType),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(_getConnectionTypeName(platformService.connectionType)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Sunucu:'),
                              Text(configService.serverUrl),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Kullanıcı adı ve oda girişi
                  PlatformAdaptiveUI.textField(
                    controller: _nameController,
                    labelText: 'İsminiz',
                    hintText: 'İsminizi girin',
                  ),
                  const SizedBox(height: 16),
                  PlatformAdaptiveUI.textField(
                    controller: _roomController,
                    labelText: 'Oda Adı',
                    hintText: 'Oda adını girin veya yeni oda oluşturun',
                  ),
                  const SizedBox(height: 24),

                  // Butonlar
                  Row(
                    children: [
                      Expanded(
                        child: PlatformAdaptiveUI.button(
                          text: 'Odaya Katıl',
                          icon: Icons.login,
                          onPressed: () async {
                            if (_nameController.text.isNotEmpty && _roomController.text.isNotEmpty) {
                              await _saveUserName();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ConferenceScreen(
                                    roomId: _roomController.text,
                                    userName: _nameController.text,
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Lütfen isim ve oda adı girin')),
                              );
                            }
                          },
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: PlatformAdaptiveUI.button(
                          text: 'Yeni Oda Oluştur',
                          icon: Icons.add_circle_outline,
                          onPressed: () {
                            if (_nameController.text.isNotEmpty) {
                              final roomId = const Uuid().v4().substring(0, 8);
                              _roomController.text = roomId;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Yeni oda oluşturuldu: $roomId')),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Lütfen önce isminizi girin')),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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

  @override
  void dispose() {
    _roomController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}