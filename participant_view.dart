import 'package:flutter/material.dart';
import 'package:teleconference_app/models/participant.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class ParticipantView extends StatelessWidget {
  final Participant participant;
  final bool isLocal;

  const ParticipantView({
    Key? key,
    required this.participant,
    required this.isLocal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isLocal ? Colors.blue : Colors.grey,
          width: 2.0,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6.0),
                topRight: Radius.circular(6.0),
              ),
              child: participant.videoRenderer != null
                  ? RTCVideoView(
                      participant.videoRenderer!,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    )
                  : const Center(
                      child: Icon(
                        Icons.videocam_off,
                        color: Colors.white,
                        size: 48.0,
                      ),
                    ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            decoration: const BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(6.0),
                bottomRight: Radius.circular(6.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    isLocal ? '${participant.name} (Sen)' : participant.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (participant.isMuted)
                  const Icon(
                    Icons.mic_off,
                    color: Colors.red,
                    size: 18.0,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
