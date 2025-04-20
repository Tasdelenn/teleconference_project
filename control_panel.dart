import 'package:flutter/material.dart';

class ControlPanel extends StatelessWidget {
  final VoidCallback onToggleMute;
  final VoidCallback onToggleVideo;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onLeaveRoom;
  final bool isMuted;
  final bool isVideoEnabled;
  final bool isSpeakerOn;

  const ControlPanel({
    Key? key,
    required this.onToggleMute,
    required this.onToggleVideo,
    required this.onToggleSpeaker,
    required this.onLeaveRoom,
    required this.isMuted,
    required this.isVideoEnabled,
    required this.isSpeakerOn,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      decoration: const BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: isMuted ? Icons.mic_off : Icons.mic,
            label: isMuted ? 'Sesi Aç' : 'Sesi Kapat',
            color: isMuted ? Colors.red : Colors.white,
            onPressed: onToggleMute,
          ),
          _buildControlButton(
            icon: isVideoEnabled ? Icons.videocam : Icons.videocam_off,
            label: isVideoEnabled ? 'Videoyu Kapat' : 'Videoyu Aç',
            color: isVideoEnabled ? Colors.white : Colors.red,
            onPressed: onToggleVideo,
          ),
          _buildControlButton(
            icon: isSpeakerOn ? Icons.volume_up : Icons.volume_off,
            label: isSpeakerOn ? 'Hoparlörü Kapat' : 'Hoparlörü Aç',
            color: isSpeakerOn ? Colors.white : Colors.red,
            onPressed: onToggleSpeaker,
          ),
          _buildControlButton(
            icon: Icons.call_end,
            label: 'Ayrıl',
            color: Colors.red,
            onPressed: onLeaveRoom,
            backgroundColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    Color? backgroundColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor ?? Colors.grey[800],
          ),
          child: IconButton(
            icon: Icon(icon),
            color: color,
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12.0,
          ),
        ),
      ],
    );
  }
}
