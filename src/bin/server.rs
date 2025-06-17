use tokio;
use warp::{Filter, ws::Message, ws::WebSocket};
use std::collections::HashMap;
use std::sync::{Arc, Mutex};
use futures::{StreamExt};
use uuid::Uuid;
use serde::{Deserialize, Serialize};
use anyhow::Result;
use std::net::SocketAddr;

// Kullanıcı bağlantısı
struct Connection {
    id: String,
    room_id: String,
    sender: Option<futures::channel::mpsc::UnboundedSender<Message>>,
}

// Sinyal mesajları
#[derive(Debug, Serialize, Deserialize)]
#[serde(tag = "type")]
enum SignalMessage {
    Join {
        room_id: String,
        user_id: String,
    },
    Offer {
        sdp: String,
        user_id: String,
        target_id: String,
    },
    Answer {
        sdp: String,
        user_id: String,
        target_id: String,
    },
    IceCandidate {
        candidate: String,
        user_id: String,
        target_id: String,
    },
    Leave {
        user_id: String,
        room_id: String,
    },
}

// Bağlantı havuzu
type Connections = Arc<Mutex<HashMap<String, Connection>>>;

#[tokio::main]
async fn main() -> Result<()> {
    let args: Vec<String> = std::env::args().collect();
    
    let address = if args.len() > 1 { &args[1] } else { "127.0.0.1" };
    let port = if args.len() > 2 { args[2].parse().unwrap_or(8080) } else { 8080 };
    
    println!("Telekonferans sunucusu başlatılıyor: {}:{}", address, port);
    
    // Bağlantı havuzu
    let connections = Connections::default();
    let connections_filter = warp::any().map(move || connections.clone());
    
    // WebSocket yönlendirme
    let ws_route = warp::path("ws")
    .and(warp::ws())
    .and(connections_filter)
    .map(|ws: warp::ws::Ws, connections| {
        ws.on_upgrade(move |socket| handle_connection(socket, connections))
    });

    // CORS yapılandırması
    let cors = warp::cors()
    .allow_any_origin()
    .allow_headers(vec!["content-type"])
    .allow_methods(vec!["GET", "POST", "OPTIONS"]);

    // HTTP sunucusu
    let routes = ws_route.with(cors);
    
    // Sunucuyu başlat
    let addr: SocketAddr = format!("{}:{}", address, port).parse().unwrap();
    println!("Sunucu başladı. Bağlantılar kabul ediliyor...");
    warp::serve(routes).run(addr).await;
    
    Ok(())
}

// WebSocket bağlantısını işle
async fn handle_connection(ws: WebSocket, connections: Connections) {
    // Kullanıcı ID'si oluştur
    let id = Uuid::new_v4().to_string();
    println!("Yeni bağlantı kabul edildi: {}", id);

    // WebSocket'i alıcı ve gönderici olarak ayır
    let (mut ws_tx, mut ws_rx) = ws.split();

    // Mesaj kanalı oluştur
    let (tx, rx) = futures::channel::mpsc::unbounded();
    let mut rx = rx.map(Ok).forward(ws_tx);

    // Bağlantıyı havuza ekle
    {
        let mut connections = connections.lock().unwrap();
        connections.insert(id.clone(), Connection {
            id: id.clone(),
            room_id: String::new(),
            sender: Some(tx),
        });
    }

    println!("Yeni oturum oluşturuldu: \"{}\"", id);

    // Mesajları işle
    tokio::task::spawn(async move {
        while let Some(result) = ws_rx.next().await {
            match result {
                Ok(msg) => {
                    if let Ok(text) = msg.to_str() {
                        println!("Alınan mesaj: {}", text);
                        handle_message(text, &id, &connections).await;
                    }
                }
                Err(e) => {
                    println!("Mesaj alınamadı: {}", e);
                    break;
                }
            }
        }

        // Bağlantı kapandığında kullanıcıyı kaldır
        let mut connections = connections.lock().unwrap();
        connections.remove(&id);
        println!("Bağlantı kapandı: {}", id);
    });

    // Alıcı kanalı çalıştır
    let _ = rx.await;
}

// Mesajları işle
async fn handle_message(msg: &str, sender_id: &str, connections: &Connections) {
    // Mesajı ayrıştır
    let signal_result = serde_json::from_str::<SignalMessage>(msg);
    if let Ok(signal) = signal_result {
        match signal {
            SignalMessage::Join { room_id, user_id } => {
                println!("Kullanıcı {} odaya katıldı: {}", user_id, room_id);
                
                // Kullanıcının oda bilgisini güncelle
                let mut connections = connections.lock().unwrap();
                if let Some(connection) = connections.get_mut(sender_id) {
                    connection.room_id = room_id.clone();
                }
                
                // Odadaki diğer kullanıcılara bildir
                for (id, connection) in connections.iter() {
                    if id != sender_id && connection.room_id == room_id {
                        if let Some(sender) = &connection.sender {
                            let join_msg = serde_json::to_string(&SignalMessage::Join {
                                room_id: room_id.clone(),
                                user_id: user_id.clone(),
                            }).unwrap();
                            let _ = sender.unbounded_send(Message::text(join_msg));
                        }
                    }
                }
            }
            SignalMessage::Offer { sdp, user_id, target_id } => {
                // Teklifi hedef kullanıcıya ilet
                let connections = connections.lock().unwrap();
                if let Some(connection) = connections.get(&target_id) {
                    if let Some(sender) = &connection.sender {
                        let offer_msg = serde_json::to_string(&SignalMessage::Offer {
                            sdp,
                            user_id,
                            target_id,
                        }).unwrap();
                        let _ = sender.unbounded_send(Message::text(offer_msg));
                    }
                }
            }
            SignalMessage::Answer { sdp, user_id, target_id } => {
                // Cevabı hedef kullanıcıya ilet
                let connections = connections.lock().unwrap();
                if let Some(connection) = connections.get(&target_id) {
                    if let Some(sender) = &connection.sender {
                        let answer_msg = serde_json::to_string(&SignalMessage::Answer {
                            sdp,
                            user_id,
                            target_id,
                        }).unwrap();
                        let _ = sender.unbounded_send(Message::text(answer_msg));
                    }
                }
            }
            SignalMessage::IceCandidate { candidate, user_id, target_id } => {
                // ICE adayını hedef kullanıcıya ilet
                let connections = connections.lock().unwrap();
                if let Some(connection) = connections.get(&target_id) {
                    if let Some(sender) = &connection.sender {
                        let ice_msg = serde_json::to_string(&SignalMessage::IceCandidate {
                            candidate,
                            user_id,
                            target_id,
                        }).unwrap();
                        let _ = sender.unbounded_send(Message::text(ice_msg));
                    }
                }
            }
            SignalMessage::Leave { user_id, room_id } => {
                // Kullanıcının odadan ayrıldığını diğer kullanıcılara bildir
                let connections = connections.lock().unwrap();
                for (id, connection) in connections.iter() {
                    if id != sender_id && connection.room_id == room_id {
                        if let Some(sender) = &connection.sender {
                            let leave_msg = serde_json::to_string(&SignalMessage::Leave {
                                user_id: user_id.clone(),
                                room_id: room_id.clone(),
                            }).unwrap();
                            let _ = sender.unbounded_send(Message::text(leave_msg));
                        }
                    }
                }
            }
        }
    } else {
        println!("JSON ayrıştırma hatası: {}", signal_result.err().unwrap());
    }
}
