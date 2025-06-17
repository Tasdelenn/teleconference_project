import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ShareRoomDialog extends StatelessWidget {
  final String roomId;
  final String serverUrl;

  const ShareRoomDialog({
    Key? key,
    required this.roomId,
    required this.serverUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final joinUrl = '$serverUrl/join?room=$roomId';

    return AlertDialog(
      title: const Text('Odayı Paylaş'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Oda bilgisi
            ListTile(
              title: const Text('Oda ID'),
              subtitle: Text(roomId),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () => _copyToClipboard(context, roomId),
                tooltip: 'Kopyala',
              ),
            ),
            
            const SizedBox(height: 16),
            
            // QR kod
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: QrImageView(
                data: joinUrl,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Bağlantı
            ListTile(
              title: const Text('Bağlantı'),
              subtitle: Text(joinUrl, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () => _copyToClipboard(context, joinUrl),
                tooltip: 'Kopyala',
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Paylaş butonu
        TextButton.icon(
          icon: const Icon(Icons.share),
          label: const Text('Paylaş'),
          onPressed: () => _shareRoom(context, joinUrl),
        ),
        
        // Kapat butonu
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Kapat'),
        ),
      ],
    );
  }

  // Panoya kopyala
  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Panoya kopyalandı')),
    );
  }

  // Paylaş
  void _shareRoom(BuildContext context, String joinUrl) {
    Share.share(
      'Telekonferans odama katıl: $joinUrl',
      subject: 'Telekonferans Daveti',
    );
  }
}