use std::sync::{Arc, Mutex};
use teleconference_server::*;
use tokio;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args: Vec<String> = std::env::args().collect();
    
    let address = if args.len() > 1 { args[1].trim_matches('"') } else { "127.0.0.1" };
    let port = if args.len() > 2 { args[2].parse().unwrap_or(8080) } else { 8080 };
    
    println!("Telekonferans sunucusu başlatılıyor: {}:{}", address, port);
    
    // Telekonferans çekirdeğini oluştur
    let core = Arc::new(Mutex::new(TeleconferenceCore::new()));
    
    // VoidAgent sunucusunu oluştur
    let mut server = VoidAgentServer::new(address, port, core);
    
    // Sunucuyu başlat
    match server.start().await {
        Ok(_) => println!("Sunucu başarıyla başlatıldı"),
        Err(e) => eprintln!("Sunucu başlatılamadı: {:?}", e),
    }
    
    Ok(())
}