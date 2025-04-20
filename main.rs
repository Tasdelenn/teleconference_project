use std::collections::HashMap;
use std::sync::{Arc, Mutex};
use tokio::sync::mpsc;
use warp::ws::{Message, WebSocket};
use warp::Filter;
use uuid::Uuid;
use serde::{Deserialize, Serialize};
use log::{info, error, warn, debug};
use futures::{FutureExt, StreamExt};

// WebRTC bağlantı durumlarını takip etmek için kullanılacak yapılar
#[derive(Debug, Clone, Serialize, Deserialize)]
struct Room {
    id: String,
    participants: HashMap<String, Participant>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Participant {
    id: String,
    name: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
enum SignalMessage {
    Join {
        room_id: String,
        user_id: String,
        user_name: String,
    },
    Leave {
        room_id: String,
        user_id: String,
    },
    Offer {
        room_id: String,
        sender_id: String,
        receiver_id: String,
        sdp: String,
    },
    Answer {
        room_id: String,
        sender_id: String,
        receiver_id: String,
        sdp: String,
    },
    IceCandidate {
        room_id: String,
        sender_id: String,
        receiver_id: String,
        candidate: String,
        sdp_mid: String,
        sdp_m_line_index: u32,
    },
    Subtitle {
        room_id: String,
        sender_id: String,
        text: String,
        timestamp: u64,
    },
}

// Kullanıcı bağlantılarını saklamak için kullanılacak yapı
type Users = Arc<Mutex<HashMap<String, mpsc::UnboundedSender<Result<Message, warp::Error>>>>>;
type Rooms = Arc<Mutex<HashMap<String, Room>>>;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Loglama ayarlarını yapılandır
    env_logger::init();
    info!("Telekonferans sunucusu başlatılıyor...");

    // Kullanıcı bağlantılarını ve odaları saklamak için yapıları oluştur
    let users = Users::default();
    let rooms = Rooms::default();

    // WebSocket endpoint'i oluştur
    let users_filter = warp::any().map(move || users.clone());
    let rooms_filter = warp::any().map(move || rooms.clone());

    let websocket_route = warp::path("ws")
        .and(warp::ws())
        .and(users_filter)
        .and(rooms_filter)
        .map(|ws: warp::ws::Ws, users, rooms| {
            ws.on_upgrade(move |socket| handle_websocket(socket, users, rooms))
        });

    // HTTP sunucusunu başlat
    let routes = websocket_route
        .with(warp::cors().allow_any_origin())
        .with(warp::log("teleconference_server"));

    info!("Sunucu 8080 portunda dinlemeye başladı");
    warp::serve(routes).run(([0, 0, 0, 0], 8080)).await;

    Ok(())
}

async fn handle_websocket(ws: WebSocket, users: Users, rooms: Rooms) {
    // Her bağlantı için benzersiz bir ID oluştur
    let user_id = Uuid::new_v4().to_string();
    info!("Yeni WebSocket bağlantısı: {}", user_id);

    // WebSocket'i alıcı ve gönderici olarak böl
    let (ws_tx, mut ws_rx) = ws.split();

    // Kullanıcıya mesaj göndermek için kanal oluştur
    let (tx, rx) = mpsc::unbounded_channel();
    tokio::task::spawn(rx.forward(ws_tx).map(|result| {
        if let Err(e) = result {
            error!("WebSocket gönderme hatası: {}", e);
        }
    }));

    // Kullanıcıyı kullanıcılar listesine ekle
    users.lock().unwrap().insert(user_id.clone(), tx);

    // WebSocket mesajlarını işle
    while let Some(result) = ws_rx.next().await {
        match result {
            Ok(msg) => {
                if let Err(e) = handle_message(msg, &user_id, &users, &rooms).await {
                    error!("Mesaj işleme hatası: {}", e);
                    break;
                }
            }
            Err(e) => {
                error!("WebSocket alma hatası: {}", e);
                break;
            }
        }
    }

    // Kullanıcı bağlantısı koptuğunda temizlik yap
    handle_disconnect(&user_id, &users, &rooms).await;
}

async fn handle_message(
    msg: Message,
    user_id: &str,
    users: &Users,
    rooms: &Rooms,
) -> Result<(), Box<dyn std::error::Error>> {
    // Mesaj binary veya text değilse, işleme
    if !msg.is_binary() && !msg.is_text() {
        return Ok(());
    }

    let message_data = if msg.is_binary() {
        msg.as_bytes()
    } else {
        msg.as_str().unwrap().as_bytes()
    };

    // Mesajı JSON olarak ayrıştır
    let signal_message: SignalMessage = serde_json::from_slice(message_data)?;

    // Mesaj tipine göre işle
    match signal_message {
        SignalMessage::Join { room_id, user_id, user_name } => {
            handle_join(room_id, user_id, user_name, rooms, users).await?;
        }
        SignalMessage::Leave { room_id, user_id } => {
            handle_leave(room_id, user_id, rooms, users).await?;
        }
        SignalMessage::Offer { room_id, sender_id, receiver_id, sdp } => {
            handle_offer(room_id, sender_id, receiver_id, sdp, users).await?;
        }
        SignalMessage::Answer { room_id, sender_id, receiver_id, sdp } => {
            handle_answer(room_id, sender_id, receiver_id, sdp, users).await?;
        }
        SignalMessage::IceCandidate { room_id, sender_id, receiver_id, candidate, sdp_mid, sdp_m_line_index } => {
            handle_ice_candidate(room_id, sender_id, receiver_id, candidate, sdp_mid, sdp_m_line_index, users).await?;
        }
        SignalMessage::Subtitle { room_id, sender_id, text, timestamp } => {
            handle_subtitle(room_id, sender_id, text, timestamp, rooms, users).await?;
        }
    }

    Ok(())
}

async fn handle_join(
    room_id: String,
    user_id: String,
    user_name: String,
    rooms: &Rooms,
    users: &Users,
) -> Result<(), Box<dyn std::error::Error>> {
    info!("Kullanıcı {} odaya katılıyor: {}", user_id, room_id);

    // Odayı bul veya oluştur
    let mut rooms_lock = rooms.lock().unwrap();
    let room = rooms_lock.entry(room_id.clone()).or_insert_with(|| Room {
        id: room_id.clone(),
        participants: HashMap::new(),
    });

    // Kullanıcıyı odaya ekle
    let participant = Participant {
        id: user_id.clone(),
        name: user_name,
    };
    room.participants.insert(user_id.clone(), participant.clone());

    // Odadaki diğer kullanıcılara yeni kullanıcının katıldığını bildir
    let users_lock = users.lock().unwrap();
    for (other_id, _) in room.participants.iter() {
        if other_id != &user_id {
            if let Some(sender) = users_lock.get(other_id) {
                let join_message = SignalMessage::Join {
                    room_id: room_id.clone(),
                    user_id: user_id.clone(),
                    user_name: participant.name.clone(),
                };
                let message = serde_json::to_string(&join_message)?;
                sender.send(Ok(Message::text(message)))?;
            }
        }
    }

    // Yeni kullanıcıya odadaki diğer kullanıcıları bildir
    if let Some(sender) = users_lock.get(&user_id) {
        for (other_id, other_participant) in room.participants.iter() {
            if other_id != &user_id {
                let join_message = SignalMessage::Join {
                    room_id: room_id.clone(),
                    user_id: other_id.clone(),
                    user_name: other_participant.name.clone(),
                };
                let message = serde_json::to_string(&join_message)?;
                sender.send(Ok(Message::text(message)))?;
            }
        }
    }

    Ok(())
}

async fn handle_leave(
    room_id: String,
    user_id: String,
    rooms: &Rooms,
    users: &Users,
) -> Result<(), Box<dyn std::error::Error>> {
    info!("Kullanıcı {} odadan ayrılıyor: {}", user_id, room_id);

    // Odayı bul
    let mut rooms_lock = rooms.lock().unwrap();
    if let Some(room) = rooms_lock.get_mut(&room_id) {
        // Kullanıcıyı odadan çıkar
        room.participants.remove(&user_id);

        // Odadaki diğer kullanıcılara kullanıcının ayrıldığını bildir
        let users_lock = users.lock().unwrap();
        for (other_id, _) in room.participants.iter() {
            if let Some(sender) = users_lock.get(other_id) {
                let leave_message = SignalMessage::Leave {
                    room_id: room_id.clone(),
                    user_id: user_id.clone(),
                };
                let message = serde_json::to_string(&leave_message)?;
                sender.send(Ok(Message::text(message)))?;
            }
        }

        // Oda boşsa, odayı kaldır
        if room.participants.is_empty() {
            rooms_lock.remove(&room_id);
            info!("Oda kaldırıldı: {}", room_id);
        }
    }

    Ok(())
}

async fn handle_offer(
    room_id: String,
    sender_id: String,
    receiver_id: String,
    sdp: String,
    users: &Users,
) -> Result<(), Box<dyn std::error::Error>> {
    debug!("SDP Teklifi: {} -> {}", sender_id, receiver_id);

    // Alıcıya teklifi ilet
    let users_lock = users.lock().unwrap();
    if let Some(sender) = users_lock.get(&receiver_id) {
        let offer_message = SignalMessage::Offer {
            room_id,
            sender_id,
            receiver_id,
            sdp,
        };
        let message = serde_json::to_string(&offer_message)?;
        sender.send(Ok(Message::text(message)))?;
    } else {
        warn!("Alıcı bulunamadı: {}", receiver_id);
    }

    Ok(())
}

async fn handle_answer(
    room_id: String,
    sender_id: String,
    receiver_id: String,
    sdp: String,
    users: &Users,
) -> Result<(), Box<dyn std::error::Error>> {
    debug!("SDP Yanıtı: {} -> {}", sender_id, receiver_id);

    // Alıcıya yanıtı ilet
    let users_lock = users.lock().unwrap();
    if let Some(sender) = users_lock.get(&receiver_id) {
        let answer_message = SignalMessage::Answer {
            room_id,
            sender_id,
            receiver_id,
            sdp,
        };
        let message = serde_json::to_string(&answer_message)?;
        sender.send(Ok(Message::text(message)))?;
    } else {
        warn!("Alıcı bulunamadı: {}", receiver_id);
    }

    Ok(())
}

async fn handle_ice_candidate(
    room_id: String,
    sender_id: String,
    receiver_id: String,
    candidate: String,
    sdp_mid: String,
    sdp_m_line_index: u32,
    users: &Users,
) -> Result<(), Box<dyn std::error::Error>> {
    debug!("ICE Adayı: {} -> {}", sender_id, receiver_id);

    // Alıcıya ICE adayını ilet
    let users_lock = users.lock().unwrap();
    if let Some(sender) = users_lock.get(&receiver_id) {
        let ice_message = SignalMessage::IceCandidate {
            room_id,
            sender_id,
            receiver_id,
            candidate,
            sdp_mid,
            sdp_m_line_index,
        };
        let message = serde_json::to_string(&ice_message)?;
        sender.send(Ok(Message::text(message)))?;
    } else {
        warn!("Alıcı bulunamadı: {}", receiver_id);
    }

    Ok(())
}

async fn handle_subtitle(
    room_id: String,
    sender_id: String,
    text: String,
    timestamp: u64,
    rooms: &Rooms,
    users: &Users,
) -> Result<(), Box<dyn std::error::Error>> {
    debug!("Altyazı: {} -> {}", sender_id, text);

    // Odayı bul
    let rooms_lock = rooms.lock().unwrap();
    if let Some(room) = rooms_lock.get(&room_id) {
        // Odadaki tüm kullanıcılara altyazıyı ilet
        let users_lock = users.lock().unwrap();
        for (other_id, _) in room.participants.iter() {
            if other_id != &sender_id {
                if let Some(sender) = users_lock.get(other_id) {
                    let subtitle_message = SignalMessage::Subtitle {
                        room_id: room_id.clone(),
                        sender_id: sender_id.clone(),
                        text: text.clone(),
                        timestamp,
                    };
                    let message = serde_json::to_string(&subtitle_message)?;
                    sender.send(Ok(Message::text(message)))?;
                }
            }
        }
    } else {
        warn!("Oda bulunamadı: {}", room_id);
    }

    Ok(())
}

async fn handle_disconnect(user_id: &str, users: &Users, rooms: &Rooms) {
    info!("Kullanıcı bağlantısı koptu: {}", user_id);

    // Kullanıcıyı kullanıcılar listesinden çıkar
    users.lock().unwrap().remove(user_id);

    // Kullanıcının bulunduğu tüm odalardan çıkar
    let mut rooms_to_leave = Vec::new();
    {
        let rooms_lock = rooms.lock().unwrap();
        for (room_id, room) in rooms_lock.iter() {
            if room.participants.contains_key(user_id) {
                rooms_to_leave.push(room_id.clone());
            }
        }
    }

    for room_id in rooms_to_leave {
        if let Err(e) = handle_leave(room_id, user_id.to_string(), rooms, users).await {
            error!("Kullanıcı ayrılma hatası: {}", e);
        }
    }
}
