// WebRTC yapılandırması
const configuration = {
    iceServers: [
        { urls: 'stun:stun.l.google.com:19302' },
        { urls: 'stun:stun1.l.google.com:19302' }
    ]
};

// Değişkenler
let socket;
let localStream;
let peerConnections = {};
let roomId;
let userId;
let isMuted = false;
let isVideoOff = false;

// DOM elementleri
const joinForm = document.querySelector('.join-form');
const conferenceRoom = document.querySelector('.conference-room');
const roomIdInput = document.getElementById('roomId');
const userNameInput = document.getElementById('userName');
const joinBtn = document.getElementById('joinBtn');
const muteBtn = document.getElementById('muteBtn');
const videoBtn = document.getElementById('videoBtn');
const leaveBtn = document.getElementById('leaveBtn');
const localVideo = document.getElementById('localVideo');
const remoteVideos = document.getElementById('remoteVideos');

// Olayları dinle
joinBtn.addEventListener('click', joinRoom);
muteBtn.addEventListener('click', toggleMute);
videoBtn.addEventListener('click', toggleVideo);
leaveBtn.addEventListener('click', leaveRoom);

// Odaya katıl
async function joinRoom() {
    roomId = roomIdInput.value.trim();
    const userName = userNameInput.value.trim();
    
    if (!roomId || !userName) {
        alert('Lütfen oda ID ve kullanıcı adı girin');
        return;
    }
    
    userId = generateUserId();
    
    try {
        // Medya akışını al
        localStream = await navigator.mediaDevices.getUserMedia({
            audio: true,
            video: true
        });
        
        // Yerel videoyu göster
        localVideo.srcObject = localStream;
        
        // WebSocket bağlantısı kur
        connectToSignalServer();
        
        // Arayüzü güncelle
        joinForm.style.display = 'none';
        conferenceRoom.style.display = 'block';
    } catch (error) {
        console.error('Medya akışı alınamadı:', error);
        alert('Kamera ve mikrofon erişimi sağlanamadı');
    }
}

// Sinyal sunucusuna bağlan
function connectToSignalServer() {
    socket = new WebSocket('ws://127.0.0.1:8080/ws');
    
    socket.onopen = () => {
        console.log('WebSocket bağlantısı kuruldu');
        
        // Odaya katıl
        sendSignal({
            type: 'Join',
            room_id: roomId,
            user_id: userId
        });
    };
    
    socket.onmessage = (event) => {
        const data = JSON.parse(event.data);
        handleSignal(data);
    };
    
    socket.onclose = () => {
        console.log('WebSocket bağlantısı kapandı');
    };
    
    socket.onerror = (error) => {
        console.error('WebSocket hatası:', error);
    };
}

// Sinyal mesajlarını işle
function handleSignal(signal) {
    switch (signal.type) {
        case 'Join':
            handleJoin(signal);
            break;
        case 'Offer':
            handleOffer(signal);
            break;
        case 'Answer':
            handleAnswer(signal);
            break;
        case 'IceCandidate':
            handleIceCandidate(signal);
            break;
        case 'Leave':
            handleLeave(signal);
            break;
    }
}

// Katılma mesajını işle
async function handleJoin(signal) {
    const peerId = signal.user_id;
    
    if (peerId === userId) return; // Kendimizi yoksay
    
    console.log('Yeni kullanıcı katıldı:', peerId);
    
    // Peer bağlantısı oluştur
    await createPeerConnection(peerId);
    
    // Teklif oluştur
    await createOffer(peerId);
}

// Teklif mesajını işle
async function handleOffer(signal) {
    const peerId = signal.user_id;
    const sdp = signal.sdp;
    
    console.log('Teklif alındı:', peerId);
    
    // Peer bağlantısı oluştur (yoksa)
    if (!peerConnections[peerId]) {
        await createPeerConnection(peerId);
    }
    
    // Uzak açıklamayı ayarla
    await peerConnections[peerId].setRemoteDescription(new RTCSessionDescription({
        type: 'offer',
        sdp: sdp
    }));
    
    // Cevap oluştur
    await createAnswer(peerId);
}

// Cevap mesajını işle
async function handleAnswer(signal) {
    const peerId = signal.user_id;
    const sdp = signal.sdp;
    
    console.log('Cevap alındı:', peerId);
    
    if (!peerConnections[peerId]) return;
    
    // Uzak açıklamayı ayarla
    await peerConnections[peerId].setRemoteDescription(new RTCSessionDescription({
        type: 'answer',
        sdp: sdp
    }));
}

// ICE adayı mesajını işle
async function handleIceCandidate(signal) {
    const peerId = signal.user_id;
    const candidate = signal.candidate;
    
    if (!peerConnections[peerId]) return;
    
    // ICE adayını ekle
    await peerConnections[peerId].addIceCandidate(new RTCIceCandidate(candidate));
}

// Ayrılma mesajını işle
function handleLeave(signal) {
    const peerId = signal.user_id;
    
    console.log('Kullanıcı ayrıldı:', peerId);
    
    // Peer bağlantısını kapat
    if (peerConnections[peerId]) {
        peerConnections[peerId].close();
        delete peerConnections[peerId];
    }
    
    // Uzak videoyu kaldır
    const videoElement = document.getElementById(`video-${peerId}`);
    if (videoElement) {
        videoElement.parentNode.remove();
    }
}

// Peer bağlantısı oluştur
async function createPeerConnection(peerId) {
    console.log('Peer bağlantısı oluşturuluyor:', peerId);
    
    // Peer bağlantısı oluştur
    const pc = new RTCPeerConnection(configuration);
    
    // Yerel akışı ekle
    localStream.getTracks().forEach(track => {
        pc.addTrack(track, localStream);
    });
    
    // ICE aday olayını dinle
    pc.onicecandidate = (event) => {
        if (event.candidate) {
            sendSignal({
                type: 'IceCandidate',
                user_id: userId,
                target_id: peerId,
                candidate: event.candidate
            });
        }
    };
    
    // Uzak akış olayını dinle
    pc.ontrack = (event) => {
        if (event.streams && event.streams[0]) {
            createRemoteVideo(peerId, event.streams[0]);
        }
    };
    
    peerConnections[peerId] = pc;
}

// Teklif oluştur
async function createOffer(peerId) {
    const pc = peerConnections[peerId];
    if (!pc) return;
    
    // Teklif oluştur
    const offer = await pc.createOffer();
    await pc.setLocalDescription(offer);
    
    // Teklifi gönder
    sendSignal({
        type: 'Offer',
        user_id: userId,
        target_id: peerId,
        sdp: offer.sdp
    });
}

// Cevap oluştur
async function createAnswer(peerId) {
    const pc = peerConnections[peerId];
    if (!pc) return;
    
    // Cevap oluştur
    const answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);
    
    // Cevabı gönder
    sendSignal({
        type: 'Answer',
        user_id: userId,
        target_id: peerId,
        sdp: answer.sdp
    });
}

// Uzak video oluştur
function createRemoteVideo(peerId, stream) {
    // Mevcut videoyu kontrol et
    const existingVideo = document.getElementById(`video-${peerId}`);
    if (existingVideo) {
        existingVideo.srcObject = stream;
        return;
    }
    
    // Yeni video oluştur
    const videoWrapper = document.createElement('div');
    videoWrapper.className = 'video-wrapper';
    
    const video = document.createElement('video');
    video.id = `video-${peerId}`;
    video.autoplay = true;
    video.playsInline = true;
    video.srcObject = stream;
    
    const label = document.createElement('div');
    label.className = 'video-label';
    label.textContent = `Kullanıcı ${peerId.substring(0, 5)}`;
    
    videoWrapper.appendChild(video);
    videoWrapper.appendChild(label);
    remoteVideos.appendChild(videoWrapper);
}

// Mikrofonu aç/kapat
function toggleMute() {
    isMuted = !isMuted;
    
    localStream.getAudioTracks().forEach(track => {
        track.enabled = !isMuted;
    });
    
    muteBtn.textContent = isMuted ? 'Mikrofonu Aç' : 'Mikrofonu Kapat';
}

// Videoyu aç/kapat
function toggleVideo() {
    isVideoOff = !isVideoOff;
    
    localStream.getVideoTracks().forEach(track => {
        track.enabled = !isVideoOff;
    });
    
    videoBtn.textContent = isVideoOff ? 'Videoyu Aç' : 'Videoyu Kapat';
}

// Odadan ayrıl
function leaveRoom() {
    // Odadan ayrıl mesajı gönder
    sendSignal({
        type: 'Leave',
        user_id: userId,
        room_id: roomId
    });
    
    // Peer bağlantılarını kapat
    Object.values(peerConnections).forEach(pc => pc.close());
    peerConnections = {};
    
    // Medya akışlarını kapat
    if (localStream) {
        localStream.getTracks().forEach(track => track.stop());
    }
    
    // WebSocket bağlantısını kapat
    if (socket) {
        socket.close();
    }
    
    // Arayüzü sıfırla
    conferenceRoom.style.display = 'none';
    joinForm.style.display = 'flex';
    remoteVideos.innerHTML = '';
    localVideo.srcObject = null;
}

// Sinyal mesajı gönder
function sendSignal(signal) {
    if (socket && socket.readyState === WebSocket.OPEN) {
        socket.send(JSON.stringify(signal));
    }
}

// Rastgele kullanıcı ID'si oluştur
function generateUserId() {
    return 'web-' + Math.random().toString(36).substring(2, 15);
}
