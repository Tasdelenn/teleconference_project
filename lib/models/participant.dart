import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class Participant {
  final String id;
  final String name;
  final RTCVideoRenderer? videoRenderer;
  bool isMuted;

  Participant({
    required this.id,
    required this.name,
    required this.videoRenderer,
    required this.isMuted,
  });
}