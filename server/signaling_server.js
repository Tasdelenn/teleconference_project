const WebSocket = require('ws');
const http = require('http');
const express = require('express');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');

// Express uygulaması oluştur
const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// HTTP sunucusu oluştur
const server = http.createServer(app);

// WebSocket sunucusu oluştur
const wss = new WebSocket.Server({ server });

// Odaları ve bağlantıları sakla
const rooms = new Map();
const clients = new Map();
// Yeni WebSocket bağlantısı
wss.on('connection', (ws) => {
  console.log('Yeni bağlantı');
  
  // Bağlantı kapandığında
  ws.on('close', () => {
    console.log('Bağlantı kapandı');
    
    // Kullanıcıyı odadan çıkar
    if (clients.has(ws)) {
      const { userId, roomId } = clients.get(ws);
      
      if (rooms.has(roomId)) {
        const room = rooms.get(roomId);
        room.delete(userId);
        
        // Odadaki diğer kullanıcılara bildir
        broadcastToRoom(roomId, {
          type: 'Leave',
          user_id: userId,
          room_id: roomId
        }, ws);
        
        // Oda boşsa odayı sil
        if (room.size === 0) {
          rooms.delete(roomId);
          console.log(`Oda silindi: ${roomId}`);
        }
      }
      
      clients.delete(ws);
    }
  });
  
  // Mesaj alındığında
  ws.on('message', (message) => {
    try {
      const data = JSON.parse(message);
      console.log('Mesaj alındı:', data.type);
      
      switch (data.type) {
        case 'Join':
          handleJoin(ws, data);
          break;
        case 'Offer':
        case 'Answer':
        case 'IceCandidate':
          forwardMessage(data);
          break;
        case 'Leave':
          handleLeave(ws, data);
          break;
        case 'Subtitle':
        case 'ChatMessage':
        case 'MuteStatus':
          broadcastToRoom(data.room_id || clients.get(ws)?.roomId, data);
          break;
        default:
          console.log('Bilinmeyen mesaj tipi:', data.type);
      }
    } catch (error) {
      console.error('Mesaj işleme hatası:', error);
    }
  });
  
  // Ping-pong ile bağlantıyı canlı tut
  ws.isAlive = true;
  ws.on('pong', () => {
    ws.isAlive = true;
  });
});
// Odaya katılma işlemi
function handleJoin(ws, data) {
  const { room_id, user_id, user_name } = data;
  
  // Oda yoksa oluştur
  if (!rooms.has(room_id)) {
    rooms.set(room_id, new Map());
    console.log(`Yeni oda oluşturuldu: ${room_id}`);
  }
  
  const room = rooms.get(room_id);
  
  // Kullanıcıyı odaya ekle
  room.set(user_id, { ws, user_name });
  
  // Bağlantıyı kaydet
  clients.set(ws, { userId: user_id, roomId: room_id });
  
  console.log(`Kullanıcı odaya katıldı: ${user_name || user_id} -> ${room_id}`);
  
  // Odadaki diğer kullanıcılara bildir
  broadcastToRoom(room_id, {
    type: 'Join',
    user_id,
    user_name,
    room_id
  }, ws);
  
  // Odadaki diğer kullanıcıları yeni kullanıcıya bildir
  room.forEach((client, clientId) => {
    if (clientId !== user_id) {
      ws.send(JSON.stringify({
        type: 'Join',
        user_id: clientId,
        user_name: client.user_name,
        room_id
      }));
    }
  });
}

// Odadan ayrılma işlemi
function handleLeave(ws, data) {
  const { user_id, room_id } = data;
  
  if (rooms.has(room_id)) {
    const room = rooms.get(room_id);
    room.delete(user_id);
    
    // Odadaki diğer kullanıcılara bildir
    broadcastToRoom(room_id, {
      type: 'Leave',
      user_id,
      room_id
    }, ws);
    
    // Oda boşsa odayı sil
    if (room.size === 0) {
      rooms.delete(room_id);
      console.log(`Oda silindi: ${room_id}`);
    }
  }
  
  // Bağlantıyı temizle
  if (clients.has(ws)) {
    clients.delete(ws);
  }
}
// Mesajı hedef kullanıcıya ilet
function forwardMessage(data) {
  const { target_id, room_id } = data;
  
  if (rooms.has(room_id)) {
    const room = rooms.get(room_id);
    
    if (room.has(target_id)) {
      const { ws } = room.get(target_id);
      ws.send(JSON.stringify(data));
    }
  }
}

// Odadaki tüm kullanıcılara mesaj gönder
function broadcastToRoom(roomId, data, excludeWs = null) {
  if (!roomId || !rooms.has(roomId)) return;
  
  const room = rooms.get(roomId);
  const message = JSON.stringify(data);
  
  room.forEach((client) => {
    if (client.ws !== excludeWs && client.ws.readyState === WebSocket.OPEN) {
      client.ws.send(message);
    }
  });
}

// Bağlantıları kontrol et ve kopanları temizle
setInterval(() => {
  wss.clients.forEach((ws) => {
    if (ws.isAlive === false) {
      return ws.terminate();
    }
    
    ws.isAlive = false;
    ws.ping();
  });
}, 30000);
// Sunucu bilgisi endpoint'i
app.get('/info', (req, res) => {
  res.json({
    status: 'online',
    rooms: rooms.size,
    clients: clients.size,
    uptime: process.uptime()
  });
});

// Oda oluşturma endpoint'i
app.post('/create-room', (req, res) => {
  const roomId = req.body.roomId || uuidv4().substring(0, 8);
  
  if (!rooms.has(roomId)) {
    rooms.set(roomId, new Map());
    console.log(`API üzerinden oda oluşturuldu: ${roomId}`);
  }
  
  res.json({ roomId });
});
// Oda bilgisi endpoint'i
app.get('/room/:roomId', (req, res) => {
  const { roomId } = req.params;
  
  if (rooms.has(roomId)) {
    const room = rooms.get(roomId);
    const participants = [];
    
    room.forEach((client, userId) => {
      participants.push({
        id: userId,
        name: client.user_name || 'Misafir'
      });
    });
    
    res.json({
      roomId,
      participants,
      created: true
    });
  } else {
    res.json({
      roomId,
      participants: [],
      created: false
    });
  }
});

// Sunucuyu başlat
const PORT = process.env.PORT || 8080;
server.listen(PORT, () => {
  console.log(`Sinyal sunucusu başlatıldı: http://localhost:${PORT}`);
  console.log(`WebSocket sunucusu: ws://localhost:${PORT}`);
});