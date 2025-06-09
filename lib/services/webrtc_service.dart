import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:uuid/uuid.dart';
import 'package:teleconference_app/models/participant.dart';
import 'package:teleconference_app/models/room.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:teleconference_app/ffi.dart';

class WebRTCService extends ChangeNotifier {
  bool _isInitialized = false;
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isSpeakerOn = true;
  WebSocketChannel? _channel;
  final List<Participant> _participants = [];
  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, RTCDataChannel> _dataChannels = {};
  String? _localParticipantId;
  String? _roomId;
  MediaStream? _localStream;
  RTCVideoRenderer? _localRenderer;
  Function(String, String, String)? _onSubtitleReceived;

  bool get isInitialized => _isInitialized;
  bool get isMuted => _isMuted;
  bool get isVideoEnabled => _isVideoEnabled;
  bool get isSpeakerOn => _isSpeakerOn;
  List<Participant> get participants => List.unmodifiable(_participants);
  String? get localParticipantId => _localParticipantId;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // WebRTC için ICE sunucularını al
    final iceConfig = await api.getIceServers();
    
    // Yerel video renderer'ı başlat
    _localRenderer = RTCVideoRenderer();
    await _localRenderer!.initialize();
    
    // Yerel medya akışını oluştur
    _localStream = await _createLocalStream();
    _localRenderer!.srcObject = _localStream;
    
    _isInitialized = true;
    notifyListeners();
  }

  Future<MediaStream> _createLocalStream() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': {
        'mandatory': {
          'minWidth': '640',
          'minHeight': '480',
          'minFrameRate': '30',
        },
        'facingMode': 'user',
        'optional': [],
      }
    };

    MediaStream stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    return stream;
  }

  Future<void> joinRoom({
    required String roomId,
    required String userName,
    required Function(String, String, String) onSubtitleReceived,
  }) async {
    if (!_isInitialized) {
      throw Exception('WebRTC servisi başlatılmadı');
    }

    _roomId = roomId;
    _localParticipantId = const Uuid().v4();
    _onSubtitleReceived = onSubtitleReceived;

    // WebSocket bağlantısını kur
    final serverUrl = dotenv.env['SERVER_URL'] ?? 'ws://localhost:8080/ws';
    _channel = WebSocketChannel.connect(Uri.parse(serverUrl));

    // Odaya katılma mesajı gönder
    final joinMessage = {
      'type': 'join',
      'room_id': roomId,
      'user_id': _localParticipantId,
      'user_name': userName,
    };
    _channel!.sink.add(jsonEncode(joinMessage));

    // Yerel katılımcıyı ekle
    final localParticipant = Participant(
      id: _localParticipantId!,
      name: userName,
      videoRenderer: _localRenderer,
      isMuted: _isMuted,
    );
    _participants.add(localParticipant);

    // WebSocket mesajlarını dinle
    _channel!.stream.listen(
      (message) => _handleSignalingMessage(jsonDecode(message)),
      onError: (error) => print('WebSocket error: $error'),
      onDone: () => print('WebSocket connection closed'),
    );

    notifyListeners();
  }

  Future<void> _handleSignalingMessage(Map<String, dynamic> message) async {
    final type = message['type'];

    switch (type) {
      case 'join':
        await _handleJoinMessage(message);
        break;
      case 'leave':
        await _handleLeaveMessage(message);
        break;
      case 'offer':
        await _handleOfferMessage(message);
        break;
      case 'answer':
        await _handleAnswerMessage(message);
        break;
      case 'ice_candidate':
        await _handleIceCandidateMessage(message);
        break;
      case 'subtitle':
        await _handleSubtitleMessage(message);
        break;
      default:
        print('Unknown message type: $type');
    }
  }

  Future<void> _handleJoinMessage(Map<String, dynamic> message) async {
    final userId = message['user_id'];
    final userName = message['user_name'];

    // Kendimizin katılma mesajını yoksay
    if (userId == _localParticipantId) return;

    // Yeni katılımcı için renderer oluştur
    final renderer = RTCVideoRenderer();
    await renderer.initialize();

    // Katılımcıyı ekle
    final participant = Participant(
      id: userId,
      name: userName,
      videoRenderer: renderer,
      isMuted: false,
    );
    _participants.add(participant);

    // Yeni katılımcı için peer bağlantısı oluştur
    await _createPeerConnection(userId);

    // Teklif gönder
    await _createOffer(userId);

    notifyListeners();
  }

  Future<void> _handleLeaveMessage(Map<String, dynamic> message) async {
    final userId = message['user_id'];

    // Katılımcıyı bul ve kaldır
    final index = _participants.indexWhere((p) => p.id == userId);
    if (index != -1) {
      // Renderer'ı temizle
      final participant = _participants[index];
      await participant.videoRenderer?.dispose();

      // Katılımcıyı listeden kaldır
      _participants.removeAt(index);
    }

    // Peer bağlantısını kapat
    await _closePeerConnection(userId);

    notifyListeners();
  }

  Future<void> _handleOfferMessage(Map<String, dynamic> message) async {
    final senderId = message['sender_id'];
    final sdp = message['sdp'];

    // Peer bağlantısı yoksa oluştur
    if (!_peerConnections.containsKey(senderId)) {
      await _createPeerConnection(senderId);
    }

    // Teklifi ayarla
    final peerConnection = _peerConnections[senderId]!;
    await peerConnection.setRemoteDescription(
      RTCSessionDescription(sdp, 'offer'),
    );

    // Yanıt oluştur
    await _createAnswer(senderId);
  }

  Future<void> _handleAnswerMessage(Map<String, dynamic> message) async {
    final senderId = message['sender_id'];
    final sdp = message['sdp'];

    // Peer bağlantısı yoksa hata
    if (!_peerConnections.containsKey(senderId)) {
      print('Peer connection not found for user: $senderId');
      return;
    }

    // Yanıtı ayarla
    final peerConnection = _peerConnections[senderId]!;
    await peerConnection.setRemoteDescription(
      RTCSessionDescription(sdp, 'answer'),
    );
  }

  Future<void> _handleIceCandidateMessage(Map<String, dynamic> message) async {
    final senderId = message['sender_id'];
    final candidate = message['candidate'];
    final sdpMid = message['sdp_mid'];
    final sdpMLineIndex = message['sdp_m_line_index'];

    // Peer bağlantısı yoksa hata
    if (!_peerConnections.containsKey(senderId)) {
      print('Peer connection not found for user: $senderId');
      return;
    }

    // ICE adayını ekle
    final peerConnection = _peerConnections[senderId]!;
    await peerConnection.addCandidate(
      RTCIceCandidate(candidate, sdpMid, sdpMLineIndex),
    );
  }

  Future<void> _handleSubtitleMessage(Map<String, dynamic> message) async {
    final senderId = message['sender_id'];
    final text = message['text'];
    final timestamp = message['timestamp'];

    // Göndereni bul
    final sender = _participants.firstWhere(
      (p) => p.id == senderId,
      orElse: () => Participant(id: senderId, name: 'Unknown', videoRenderer: null, isMuted: false),
    );

    // Altyazı callback'ini çağır
    _onSubtitleReceived?.call(senderId, sender.name, text);
  }

  Future<void> _createPeerConnection(String userId) async {
    // ICE sunucularını yapılandır
    final iceServers = await api.getIceServers();
    final Map<String, dynamic> configuration = {
      'iceServers': iceServers.iceServers.map((server) => {
        'urls': server.urls,
        if (server.username != null) 'username': server.username,
        if (server.credential != null) 'credential': server.credential,
      }).toList(),
      'sdpSemantics': 'unified-plan',
    };

    // Peer bağlantısını oluştur
    final peerConnection = await createPeerConnection(configuration);

    // Yerel akışı ekle
    _localStream!.getTracks().forEach((track) {
      peerConnection.addTrack(track, _localStream!);
    });

    // Uzak akış olayını dinle
    peerConnection.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        // Katılımcıyı bul ve renderer'ını güncelle
        final index = _participants.indexWhere((p) => p.id == userId);
        if (index != -1) {
          _participants[index].videoRenderer!.srcObject = event.streams[0];
          notifyListeners();
        }
      }
    };

    // ICE aday olayını dinle
    peerConnection.onIceCandidate = (RTCIceCandidate candidate) {
      _sendIceCandidate(userId, candidate);
    };

    // Veri kanalı oluştur
    final dataChannel = await peerConnection.createDataChannel(
      'subtitle',
      RTCDataChannelInit()..ordered = true,
    );

    // Veri kanalı olaylarını dinle
    dataChannel.onMessage = (RTCDataChannelMessage message) {
      if (message.text != null) {
        final data = jsonDecode(message.text!);
        if (data['type'] == 'subtitle') {
          _handleSubtitleMessage({
            'sender_id': userId,
            'text': data['text'],
            'timestamp': data['timestamp'],
          });
        }
      }
    };

    // Bağlantıları sakla
    _peerConnections[userId] = peerConnection;
    _dataChannels[userId] = dataChannel;
  }

  Future<void> _closePeerConnection(String userId) async {
    // Veri kanalını kapat
    _dataChannels[userId]?.close();
    _dataChannels.remove(userId);

    // Peer bağlantısını kapat
    await _peerConnections[userId]?.close();
    _peerConnections.remove(userId);
  }

  Future<void> _createOffer(String userId) async {
    // Peer bağlantısı yoksa hata
    if (!_peerConnections.containsKey(userId)) {
      print('Peer connection not found for user: $userId');
      return;
    }

    // Teklif oluştur
    final peerConnection = _peerConnections[userId]!;
    final offer = await peerConnection.createOffer();
    await peerConnection.setLocalDescription(offer);

    // Teklifi gönder
    final offerMessage = {
      'type': 'offer',
      'room_id': _roomId,
      'sender_id': _localParticipantId,
      'receiver_id': userId,
      'sdp': offer.sdp,
    };
    _channel!.sink.add(jsonEncode(offerMessage));
  }

  Future<void> _createAnswer(String userId) async {
    // Peer bağlantısı yoksa hata
    if (!_peerConnections.containsKey(userId)) {
      print('Peer connection not found for user: $userId');
      return;
    }

    // Yanıt oluştur
    final peerConnection = _peerConnections[userId]!;
    final answer = await peerConnection.createAnswer();
    await peerConnection.setLocalDescription(answer);

    // Yanıtı gönder
    final answerMessage = {
      'type': 'answer',
      'room_id': _roomId,
      'sender_id': _localParticipantId,
      'receiver_id': userId,
      'sdp': answer.sdp,
    };
    _channel!.sink.add(jsonEncode(answerMessage));
  }

  void _sendIceCandidate(String userId, RTCIceCandidate candidate) {
    // ICE adayını gönder
    final iceMessage = {
      'type': 'ice_candidate',
      'room_id': _roomId,
      'sender_id': _localParticipantId,
      'receiver_id': userId,
      'candidate': candidate.candidate,
      'sdp_mid': candidate.sdpMid,
      'sdp_m_line_index': candidate.sdpMLineIndex,
    };
    _channel!.sink.add(jsonEncode(iceMessage));
  }

  void sendAudio(List<double> processedAudio) {
    // İşlenmiş ses verisini WebRTC üzerinden gönder
    // Not: Gerçek uygulamada, ses verisi WebRTC medya akışına entegre edilecek
  }

  void sendSubtitle(String text) {
    if (!_isInitialized || _roomId == null || _localParticipantId == null) {
      return;
    }

    // Altyazıyı WebSocket üzerinden gönder
    final subtitleMessage = {
      'type': 'subtitle',
      'room_id': _roomId,
      'sender_id': _localParticipantId,
      'text': text,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    _channel!.sink.add(jsonEncode(subtitleMessage));

    // Altyazıyı veri kanalları üzerinden de gönder
    final dataMessage = {
      'type': 'subtitle',
      'text': text,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    final messageStr = jsonEncode(dataMessage);
    _dataChannels.forEach((_, channel) {
      channel.send(RTCDataChannelMessage(messageStr));
    });
  }

  void toggleMute() {
    if (!_isInitialized || _localStream == null) return;

    _isMuted = !_isMuted;
    _localStream!.getAudioTracks().forEach((track) {
      track.enabled = !_isMuted;
    });

    // Yerel katılımcıyı güncelle
    final index = _participants.indexWhere((p) => p.id == _localParticipantId);
    if (index != -1) {
      _participants[index].isMuted = _isMuted;
    }

    notifyListeners();
  }

  void toggleVideo() {
    if (!_isInitialized || _localStream == null) return;

    _isVideoEnabled = !_isVideoEnabled;
    _localStream!.getVideoTracks().forEach((track) {
      track.enabled = _isVideoEnabled;
    });

    notifyListeners();
  }

  void toggleSpeaker() {
    if (!_isInitialized) return;

    _isSpeakerOn = !_isSpeakerOn;
    // Hoparlör durumunu değiştir (platform özeldir)

    notifyListeners();
  }

  Future<void> leaveRoom() async {
    if (!_isInitialized || _roomId == null || _localParticipantId == null) {
      return;
    }

    // Odadan ayrılma mesajı gönder
    final leaveMessage = {
      'type': 'leave',
      'room_id': _roomId,
      'user_id': _localParticipantId,
    };
    _channel!.sink.add(jsonEncode(leaveMessage));

    // Tüm peer bağlantılarını kapat
    for (final userId in _peerConnections.keys.toList()) {
      await _closePeerConnection(userId);
    }

    // Yerel akışı kapat
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream = null;

    // Renderer'ları temizle
    for (final participant in _participants) {
      await participant.videoRenderer?.dispose();
    }
    _participants.clear();

    // WebSocket bağlantısını kapat
    await _channel?.sink.close();
    _channel = null;

    _roomId = null;
    _localParticipantId = null;

    notifyListeners();
  }

  @override
  void dispose() {
    leaveRoom();
    _localRenderer?.dispose();
    super.dispose();
  }
}
