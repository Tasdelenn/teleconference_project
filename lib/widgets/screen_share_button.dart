import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teleconference_app/services/webrtc_service.dart';

class ScreenShareButton extends StatefulWidget {
  const ScreenShareButton({Key? key}) : super(key: key);

  @override
  _ScreenShareButtonState createState() => _ScreenShareButtonState();
}

class _ScreenShareButtonState extends State<ScreenShareButton> {
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(_isSharing ? Icons.stop_screen_share : Icons.screen_share),
      onPressed: () => _toggleScreenShare(context),
      color: _isSharing ? Colors.red : Colors.blue,
      tooltip: _isSharing ? 'Ekran Paylaşımını Durdur' : 'Ekran Paylaş',
    );
  }

  Future<void> _toggleScreenShare(BuildContext context) async {
    final webRTCService = Provider.of<WebRTCService>(context, listen: false);
    
    setState(() {
      _isSharing = !_isSharing;
    });
    
    if (_isSharing) {
      try {
        // Ekran paylaşımını başlat
        await webRTCService.startScreenSharing();
        
        // Başarılı mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ekran paylaşımı başlatıldı')),
        );
      } catch (e) {
        // Hata durumunda paylaşımı iptal et
        setState(() {
          _isSharing = false;
        });
        
        // Hata mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ekran paylaşımı başlatılamadı: $e')),
        );
      }
    } else {
      // Ekran paylaşımını durdur
      await webRTCService.stopScreenSharing();
      
      // Bilgi mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ekran paylaşımı durduruldu')),
      );
    }
  }
}