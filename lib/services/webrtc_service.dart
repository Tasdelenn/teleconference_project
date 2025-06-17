import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:uuid/uuid.dart';
import 'package:teleconference_app/models/participant.dart';

class WebRTCService extends ChangeNotifier {
  // WebRTC
  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, MediaStream> _remoteStreams = {};
  MediaStream? _localStream;
  
  // WebSocket
  WebSocketChannel? _channel;
  bool _isConnected = false;
  
  // Kullanıcı ve oda bilgileri
  String _userId = '';
  String _roomId = '';
  String _userName = '';
  
  // Katılımcı yönetimi
  final List<Participant> _participants = [];
  final Map<String, RTCVideoRenderer> _videoRenderers = {};
  
  // Medya kontrolleri
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isSpeakerOn = true;
  
  // Getter'lar
  MediaStream? get localStream => _localStream;
  Map<String, MediaStream> get remoteStreams => _remoteStreams;
  bool get isConnected => _isConnected;
  String get userId => _userId;
  String get roomId => _roomId;
  String get userName => _userName;
  List<Participant> get participants => _participants;
  String get localParticipantId => _userId;
  bool get isMuted => _isMuted;
  bool get isVideoEnabled => _isVideoEnabled;
  bool get isSpeakerOn => _isSpeakerOn;
  
  // WebRTC yapılandırması
  final _rtcConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ]
  };
  
  // WebRTC servisini başlat
  Future<void> initialize({
    Map<String, dynamic>? videoConstraints,
    Map<String, dynamic>? audioConstraints,
  }) async {
    _userId = const Uuid().v4();
    await _initializeLocalStream(
      videoConstraints: videoConstraints,
      audioConstraints: audioConstraints,
    );
    await _initializeLocalRenderer();
  }
  
  // Yerel medya akışını başlat
  Future<void> _initializeLocalStream({
    Map<String, dynamic>? videoConstraints,
    Map<String, dynamic>? audioConstraints,
  }) async {
    final mediaConstraints = {
      'audio': audioConstraints ?? true,
      'video': videoConstraints ?? {
        'facingMode': 'user',
      }
    };
    
    try {
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      notifyListeners();
    } catch (e) {
      print('Medya akışı başlatılamadı: $e');
      rethrow;
    }
  }
  
  // Sunucuya bağlan
  Future<void> connect(String serverUrl, String roomId) async {
    if (_isConnected) {
      await disconnect();
    }
    
    _roomId = roomId;
    
    try {
      _channel = WebSocketChannel.connect(Uri.parse(serverUrl));
      _isConnected = true;
      
      // Odaya katıl
      _sendSignal({
        'type': 'Join',
        'room_id': _roomId,
        'user_id': _userId,
        'user_name': _userName,
      });
      
      // Mesajları dinle
      _channel!.stream.listen(_handleSignal, onDone: () {
        _isConnected = false;
        notifyListeners();
      }, onError: (error) {
        print('WebSocket hatası: $error');
        _isConnected = false;
        notifyListeners();
      });
      
      notifyListeners();
    } catch (e) {
      print('Sunucuya bağlanılamadı: $e');
      _isConnected = false;
      notifyListeners();
      rethrow;
    }
  }
  
  // Sunucu bağlantısını kapat
  Future<void> disconnect() async {
    if (!_isConnected) return;
    
    // Odadan ayrıl
    _sendSignal({
      'type': 'Leave',
      'user_id': _userId,
      'room_id': _roomId,
    });
    
    // Peer bağlantılarını kapat
    for (final connection in _peerConnections.values) {
      await connection.close();
    }
    _peerConnections.clear();
    
    // Uzak akışları kapat
    for (final stream in _remoteStreams.values) {
      for (final track in stream.getTracks()) {
        track.stop();
      }
    }
    _remoteStreams.clear();
    
    // WebSocket bağlantısını kapat
    await _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    
    notifyListeners();
  }
  
  // Sinyal mesajlarını işle
  void _handleSignal(dynamic message) {
    final data = jsonDecode(message);
    
    switch (data['type']) {
      case 'Join':
        _handleJoin(data);
        break;
      case 'Offer':
        _handleOffer(data);
        break;
      case 'Answer':
        _handleAnswer(data);
        break;
      case 'IceCandidate':
        _handleIceCandidate(data);
        break;
      case 'Leave':
        _handleLeave(data);
        break;
      case 'Subtitle':
        _handleSubtitle(data);
        break;
      case 'MuteStatus':
        _handleMuteStatus(data);
        break;
      case 'ChatMessage':
        _handleChatMessage(data);
        break;
  }
  
  // Katılma mesajını işle
  Future<void> _handleJoin(Map<String, dynamic> data) async {
    final peerId = data['user_id'];
    final peerName = data['user_name'] ?? 'Misafir';
    
    if (peerId == _userId) return; // Kendimizi yoksay
    
    print('Yeni kullanıcı katıldı: $peerName ($peerId)');
    
    // Video renderer oluştur
    final renderer = RTCVideoRenderer();
    await renderer.initialize();
    _videoRenderers[peerId] = renderer;
    
    // Katılımcı listesine ekle
    _participants.add(
      Participant(
        id: peerId,
        name: peerName,
        videoRenderer: renderer,
        isMuted: false,
      ),
    );
    
    // Peer bağlantısı oluştur
    await _createPeerConnection(peerId);
    
    // Teklif oluştur
    await _createOffer(peerId);
    
    notifyListeners();
  }
  
  // Teklif mesajını işle
  Future<void> _handleOffer(Map<String, dynamic> data) async {
    final peerId = data['user_id'];
    final sdp = data['sdp'];
    
    print('Teklif alındı: $peerId');
    
    // Peer bağlantısı oluştur (yoksa)
    if (!_peerConnections.containsKey(peerId)) {
      await _createPeerConnection(peerId);
    }
    
    // Uzak açıklamayı ayarla
    final rtcSessionDescription = RTCSessionDescription(sdp, 'offer');
    await _peerConnections[peerId]!.setRemoteDescription(rtcSessionDescription);
    
    // Cevap oluştur
    await _createAnswer(peerId);
  }
  
  // Cevap mesajını işle
  Future<void> _handleAnswer(Map<String, dynamic> data) async {
    final peerId = data['user_id'];
    final sdp = data['sdp'];
    
    print('Cevap alındı: $peerId');
    
    if (!_peerConnections.containsKey(peerId)) return;
    
    // Uzak açıklamayı ayarla
    final rtcSessionDescription = RTCSessionDescription(sdp, 'answer');
    await _peerConnections[peerId]!.setRemoteDescription(rtcSessionDescription);
  }
  
  // ICE adayı mesajını işle
  Future<void> _handleIceCandidate(Map<String, dynamic> data) async {
    final peerId = data['user_id'];
    final candidateString = data['candidate'];
    
    if (!_peerConnections.containsKey(peerId)) return;
    
    // ICE adayını ekle
    final rtcIceCandidate = RTCIceCandidate(
      candidateString,
      '',
      0,
    );
    await _peerConnections[peerId]!.addCandidate(rtcIceCandidate);
  }
  
  // Ayrılma mesajını işle
  void _handleLeave(Map<String, dynamic> data) {
    final peerId = data['user_id'];
    
    print('Kullanıcı ayrıldı: $peerId');
    
    // Peer bağlantısını kapat
    if (_peerConnections.containsKey(peerId)) {
      _peerConnections[peerId]!.close();
      _peerConnections.remove(peerId);
    }
    
    // Uzak akışı kapat
    if (_remoteStreams.containsKey(peerId)) {
      for (final track in _remoteStreams[peerId]!.getTracks()) {
        track.stop();
      }
      _remoteStreams.remove(peerId);
    }
    
    // Video renderer'ı temizle
    if (_videoRenderers.containsKey(peerId)) {
      _videoRenderers[peerId]!.dispose();
      _videoRenderers.remove(peerId);
    }
    
    // Katılımcı listesinden kaldır
    _participants.removeWhere((participant) => participant.id == peerId);
    
    notifyListeners();
  }
  
  // Altyazı mesajını işle
  void _handleSubtitle(Map<String, dynamic> data) {
    final peerId = data['user_id'];
    final peerName = data['user_name'] ?? 'Misafir';
    final text = data['text'] ?? '';
    
    // Altyazı callback'ini çağır
    if (_subtitleCallback != null) {
      _subtitleCallback!(peerId, peerName, text);
    }
  }
  
  // Mikrofon durumu mesajını işle
  void _handleMuteStatus(Map<String, dynamic> data) {
    final peerId = data['user_id'];
    final isMuted = data['is_muted'] ?? false;
    
    // Katılımcının mikrofon durumunu güncelle
    final participantIndex = _participants.indexWhere((p) => p.id == peerId);
    if (participantIndex >= 0) {
      _participants[participantIndex] = Participant(
        id: peerId,
        name: _participants[participantIndex].name,
        videoRenderer: _participants[participantIndex].videoRenderer,
        isMuted: isMuted,
      );
      
      notifyListeners();
    }
  }
  
  // Altyazı callback'i
  Function(String, String, String)? _subtitleCallback;
  
  // Sohbet mesajı callback'i
  Function(String, String, String, DateTime)? _chatMessageCallback;
  
  // Sohbet mesajı işle
  void _handleChatMessage(Map<String, dynamic> data) {
    final peerId = data['user_id'];
    final peerName = data['user_name'] ?? 'Misafir';
    final message = data['message'] ?? '';
    final timestamp = DateTime.fromMillisecondsSinceEpoch(data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch);
    
    // Sohbet mesajı callback'ini çağır
    if (_chatMessageCallback != null) {
      _chatMessageCallback!(peerId, peerName, message, timestamp);
    }
  }
  
  // Sohbet mesajı gönder
  void sendChatMessage(String message) {
    if (!_isConnected || _channel == null || message.trim().isEmpty) return;
    
    _sendSignal({
      'type': 'ChatMessage',
      'user_id': _userId,
      'user_name': _userName,
      'message': message,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
  
  // Peer bağlantısı oluştur
  Future<void> _createPeerConnection(String peerId) async {
    print('Peer bağlantısı oluşturuluyor: $peerId');
    
    // Peer bağlantısı oluştur
    final pc = await createPeerConnection(_rtcConfig);
    
    // Yerel akışı ekle
    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        pc.addTrack(track, _localStream!);
      }
    }
    
    // ICE aday olayını dinle
    pc.onIceCandidate = (candidate) {
      _sendSignal({
        'type': 'IceCandidate',
        'user_id': _userId,
        'target_id': peerId,
        'candidate': candidate.toMap(),
      });
    };
    
    // Uzak akış olayını dinle
    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteStreams[peerId] = event.streams[0];
        
        // Video renderer'a akışı bağla
        if (_videoRenderers.containsKey(peerId)) {
          _videoRenderers[peerId]!.srcObject = event.streams[0];
        }
        
        notifyListeners();
      }
    };
    
    _peerConnections[peerId] = pc;
  }
  
  // Teklif oluştur
  Future<void> _createOffer(String peerId) async {
    final pc = _peerConnections[peerId];
    if (pc == null) return;
    
    // Teklif oluştur
    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);
    
    // Teklifi gönder
    _sendSignal({
      'type': 'Offer',
      'user_id': _userId,
      'target_id': peerId,
      'sdp': offer.sdp,
    });
  }
  
  // Cevap oluştur
  Future<void> _createAnswer(String peerId) async {
    final pc = _peerConnections[peerId];
    if (pc == null) return;
    
    // Cevap oluştur
    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);
    
    // Cevabı gönder
    _sendSignal({
      'type': 'Answer',
      'user_id': _userId,
      'target_id': peerId,
      'sdp': answer.sdp,
    });
  }
  
  // Sinyal mesajı gönder
  void _sendSignal(Map<String, dynamic> signal) {
    if (!_isConnected || _channel == null) return;
    
    _channel!.sink.add(jsonEncode(signal));
  }
  
  // Ping mesajı gönder (bağlantıyı canlı tutmak için)
  void sendPing() {
    if (!_isConnected || _channel == null) return;
    
    _sendSignal({
      'type': 'Ping',
      'user_id': _userId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
  
  // Yerel video renderer'ı başlat
  Future<void> _initializeLocalRenderer() async {
    final renderer = RTCVideoRenderer();
    await renderer.initialize();
    
    if (_localStream != null) {
      renderer.srcObject = _localStream;
    }
    
    _videoRenderers[_userId] = renderer;
    
    // Yerel katılımcıyı ekle
    _participants.add(
      Participant(
        id: _userId,
        name: _userName.isEmpty ? 'Sen' : _userName,
        videoRenderer: renderer,
        isMuted: _isMuted,
      ),
    );
    
    notifyListeners();
  }
  
  // Odaya katıl
  Future<void> joinRoom({
    required String roomId,
    required String userName,
    required Function(String, String, String) onSubtitleReceived,
    Function(String, String, String, DateTime)? onChatMessageReceived,
  }) async {
    _roomId = roomId;
    _userName = userName;
    _subtitleCallback = onSubtitleReceived;
    _chatMessageCallback = onChatMessageReceived;
    
    // Katılımcı adını güncelle
    if (_participants.isNotEmpty) {
      final localParticipantIndex = _participants.indexWhere((p) => p.id == _userId);
      if (localParticipantIndex >= 0) {
        _participants[localParticipantIndex] = Participant(
          id: _userId,
          name: _userName,
          videoRenderer: _participants[localParticipantIndex].videoRenderer,
          isMuted: _isMuted,
        );
      }
    }
    
    // Sunucuya bağlan
    final serverUrl = 'wss://teleconference-signaling-server.example.com/ws/$roomId';
    await connect(serverUrl, roomId);
  }
  
  // Odadan ayrıl
  Future<void> leaveRoom() async {
    await disconnect();
    _participants.clear();
    notifyListeners();
  }
  
  // Mikrofonu aç/kapat
  void toggleMute() {
    _isMuted = !_isMuted;
    
    if (_localStream != null) {
      for (final track in _localStream!.getAudioTracks()) {
        track.enabled = !_isMuted;
      }
    }
    
    // Yerel katılımcının durumunu güncelle
    final localParticipantIndex = _participants.indexWhere((p) => p.id == _userId);
    if (localParticipantIndex >= 0) {
      _participants[localParticipantIndex] = Participant(
        id: _userId,
        name: _userName,
        videoRenderer: _participants[localParticipantIndex].videoRenderer,
        isMuted: _isMuted,
      );
    }
    
    // Mikrofon durumunu diğer katılımcılara bildir
    _sendSignal({
      'type': 'MuteStatus',
      'user_id': _userId,
      'is_muted': _isMuted,
    });
    
    notifyListeners();
  }
  
  // Videoyu aç/kapat
  void toggleVideo() {
    _isVideoEnabled = !_isVideoEnabled;
    
    if (_localStream != null) {
      for (final track in _localStream!.getVideoTracks()) {
        track.enabled = _isVideoEnabled;
      }
    }
    
    notifyListeners();
  }
  
  // Hoparlörü aç/kapat
  void toggleSpeaker() {
    _isSpeakerOn = !_isSpeakerOn;
    
    // Uzak akışların ses durumunu güncelle
    for (final stream in _remoteStreams.values) {
      for (final track in stream.getAudioTracks()) {
        track.enabled = _isSpeakerOn;
      }
    }
    
    notifyListeners();
  }
  
  // Ses verisi gönder
  void sendAudio(List<double> audioData) {
    // WebRTC üzerinden ses verisi gönderme işlemi
    // Bu fonksiyon şu an için simülasyon amaçlı
  }
  
  // Altyazı gönder
  void sendSubtitle(String subtitle) {
    if (!_isConnected || _channel == null) return;
    
    _sendSignal({
      'type': 'Subtitle',
      'user_id': _userId,
      'user_name': _userName,
      'text': subtitle,
    });
  }
  
  // Ekran paylaşımını başlat
  Future<void> startScreenSharing() async {
    // Ekran paylaşımı için medya akışı al
    final mediaConstraints = {
      'audio': false,
      'video': {
        'mandatory': {
          'minWidth': 1280,
          'minHeight': 720,
          'minFrameRate': 30,
        },
        'facingMode': 'environment',
        'optional': [],
      }
    };
    
    try {
      // Ekran paylaşımı için medya akışını al
      final screenStream = await navigator.mediaDevices.getDisplayMedia(mediaConstraints);
      
      // Mevcut video akışını değiştir
      if (_localStream != null) {
        // Eski video parçalarını kaldır
        final videoTracks = _localStream!.getVideoTracks();
        for (final track in videoTracks) {
          _localStream!.removeTrack(track);
          track.stop();
        }
        
        // Yeni ekran paylaşımı parçasını ekle
        final screenTrack = screenStream.getVideoTracks().first;
        _localStream!.addTrack(screenTrack);
        
        // Tüm peer bağlantılarını güncelle
        for (final connection in _peerConnections.entries) {
          final sender = connection.value.getSenders()
              .firstWhere((sender) => sender.track?.kind == 'video', orElse: () => null);
          
          if (sender != null) {
            await sender.replaceTrack(screenTrack);
          }
        }
        
        // Ekran paylaşımı bittiğinde otomatik olarak kamera görüntüsüne geri dön
        screenTrack.onEnded = () {
          stopScreenSharing();
        };
      }
      
      notifyListeners();
    } catch (e) {
      print('Ekran paylaşımı başlatılamadı: $e');
      rethrow;
    }
  }
  
  // Ekran paylaşımını durdur
  Future<void> stopScreenSharing() async {
    try {
      // Kamera görüntüsüne geri dön
      await _initializeLocalStream();
      
      // Tüm peer bağlantılarını güncelle
      for (final peerId in _peerConnections.keys) {
        await _updateMediaStream(peerId);
      }
      
      notifyListeners();
    } catch (e) {
      print('Ekran paylaşımı durdurulamadı: $e');
      rethrow;
    }
  }
  
  // Medya akışını güncelle
  Future<void> _updateMediaStream(String peerId) async {
    if (!_peerConnections.containsKey(peerId) || _localStream == null) return;
    
    final pc = _peerConnections[peerId]!;
    
    // Mevcut video gönderenlerini bul
    final videoSender = pc.getSenders()
        .firstWhere((sender) => sender.track?.kind == 'video', orElse: () => null);
    
    if (videoSender != null && _localStream!.getVideoTracks().isNotEmpty) {
      // Video parçasını güncelle
      await videoSender.replaceTrack(_localStream!.getVideoTracks().first);
    }
  }
  
  // Kaynakları temizle
  @override
  void dispose() {
    disconnect();
    
    // Yerel akışı kapat
    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        track.stop();
      }
      _localStream = null;
    }
    
    // Video renderer'ları temizle
    for (final renderer in _videoRenderers.values) {
      renderer.dispose();
    }
    _videoRenderers.clear();
    
    super.dispose();
  }
}
