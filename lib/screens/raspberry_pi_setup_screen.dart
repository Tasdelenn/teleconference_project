import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teleconference_app/services/config_service.dart';
import 'package:teleconference_app/widgets/platform_adaptive_ui.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RaspberryPiSetupScreen extends StatefulWidget {
  const RaspberryPiSetupScreen({Key? key}) : super(key: key);

  @override
  _RaspberryPiSetupScreenState createState() => _RaspberryPiSetupScreenState();
}

class _RaspberryPiSetupScreenState extends State<RaspberryPiSetupScreen> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isConnected = false;
  Map<String, dynamic>? _serverInfo;
  String? _errorMessage;
  
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
    
    // Sunucu URL'sini yükle
    final serverUrl = configService.serverUrl;
    
    // ws://192.168.1.41:8080 formatından IP ve port bilgilerini çıkar
    if (serverUrl.startsWith('ws://')) {
      final uri = Uri.parse(serverUrl.replaceFirst('ws://', 'http://'));
      _ipController.text = uri.host;
      _portController.text = uri.port.toString();
    }
    
    // Varsayılan kullanıcı adı ve şifre
    _usernameController.text = 'haqan';
    _passwordController.text = '0hata0';
    
    setState(() {
      _isLoading = false;
    });
    
    // Sunucu durumunu kontrol et
    await _checkServerStatus();
  }
  
  Future<void> _checkServerStatus() async {
    if (_ipController.text.isEmpty || _portController.text.isEmpty) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final response = await http.get(
        Uri.parse('http://${_ipController.text}:${_portController.text}/info'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        setState(() {
          _isConnected = true;
          _serverInfo = json.decode(response.body);
        });
      } else {
        setState(() {
          _isConnected = false;
          _errorMessage = 'Sunucu yanıt verdi ancak durum kodu: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isConnected = false;
        _errorMessage = 'Sunucuya bağlanılamadı: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _saveSettings() async {
    if (_ipController.text.isEmpty || _portController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('IP adresi ve port gereklidir')),
      );
      return;
    }
    
    final configService = Provider.of<ConfigService>(context, listen: false);
    final serverUrl = 'ws://${_ipController.text}:${_portController.text}';
    
    await configService.setServerUrl(serverUrl);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sunucu ayarları kaydedildi')),
    );
    
    await _checkServerStatus();
  }
  
  Future<void> _restartServer() async {
    if (_ipController.text.isEmpty || _portController.text.isEmpty ||
        _usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tüm alanları doldurun')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Bu kısım gerçek uygulamada SSH ile Raspberry Pi'ye bağlanıp
      // sunucuyu yeniden başlatacak bir işlem yapabilir
      
      // Simülasyon için biraz bekleyelim
      await Future.delayed(const Duration(seconds: 2));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sunucu yeniden başlatıldı')),
      );
      
      // Sunucu durumunu kontrol et
      await Future.delayed(const Duration(seconds: 1));
      await _checkServerStatus();
    } catch (e) {
      setState(() {
        _errorMessage = 'Sunucu yeniden başlatılamadı: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raspberry Pi Ayarları'),
      ),
      body: _isLoading
          ? Center(child: PlatformAdaptiveUI.loadingIndicator())
          : SingleChildScrollView(
              padding: PlatformAdaptiveUI.getPadding(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sunucu durumu
                  _buildServerStatusSection(),
                  
                  const Divider(height: 32),
                  
                  // Sunucu ayarları
                  _buildServerSettingsSection(),
                  
                  const Divider(height: 32),
                  
                  // SSH ayarları
                  _buildSSHSettingsSection(),
                  
                  const Divider(height: 32),
                  
                  // Sunucu yönetimi
                  _buildServerManagementSection(),
                ],
              ),
            ),
    );
  }
  
  Widget _buildServerStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sunucu Durumu',
          style: TextStyle(
            fontSize: PlatformAdaptiveUI.getFontSize(baseSize: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Durum:'),
                    Row(
                      children: [
                        Icon(
                          _isConnected ? Icons.check_circle : Icons.error,
                          color: _isConnected ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isConnected ? 'Çevrimiçi' : 'Çevrimdışı',
                          style: TextStyle(
                            color: _isConnected ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_serverInfo != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Odalar:'),
                      Text(_serverInfo!['rooms'].toString()),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Bağlı Kullanıcılar:'),
                      Text(_serverInfo!['clients'].toString()),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Çalışma Süresi:'),
                      Text('${(_serverInfo!['uptime'] as num).toStringAsFixed(2)} saniye'),
                    ],
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 16),
                PlatformAdaptiveUI.button(
                  text: 'Durumu Yenile',
                  icon: Icons.refresh,
                  onPressed: _checkServerStatus,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildServerSettingsSection() {
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
          controller: _ipController,
          labelText: 'IP Adresi',
          hintText: '192.168.1.41',
        ),
        const SizedBox(height: 16),
        PlatformAdaptiveUI.textField(
          controller: _portController,
          labelText: 'Port',
          hintText: '8080',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PlatformAdaptiveUI.button(
              text: 'Varsayılana Sıfırla',
              onPressed: () {
                _ipController.text = '192.168.1.41';
                _portController.text = '8080';
              },
            ),
            const SizedBox(width: 16),
            PlatformAdaptiveUI.button(
              text: 'Kaydet',
              onPressed: _saveSettings,
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildSSHSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SSH Ayarları',
          style: TextStyle(
            fontSize: PlatformAdaptiveUI.getFontSize(baseSize: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        PlatformAdaptiveUI.textField(
          controller: _usernameController,
          labelText: 'Kullanıcı Adı',
          hintText: 'haqan',
        ),
        const SizedBox(height: 16),
        PlatformAdaptiveUI.textField(
          controller: _passwordController,
          labelText: 'Şifre',
          obscureText: true,
        ),
      ],
    );
  }
  
  Widget _buildServerManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sunucu Yönetimi',
          style: TextStyle(
            fontSize: PlatformAdaptiveUI.getFontSize(baseSize: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: PlatformAdaptiveUI.button(
                text: 'Sunucuyu Başlat',
                icon: Icons.play_arrow,
                onPressed: _restartServer,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: PlatformAdaptiveUI.button(
                text: 'Sunucuyu Durdur',
                icon: Icons.stop,
                onPressed: () {
                  // Sunucuyu durdurma işlemi
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bu özellik henüz uygulanmadı')),
                  );
                },
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        PlatformAdaptiveUI.button(
          text: 'Sunucuyu Yeniden Başlat',
          icon: Icons.refresh,
          onPressed: _restartServer,
          color: Colors.orange,
        ),
      ],
    );
  }
  
  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}