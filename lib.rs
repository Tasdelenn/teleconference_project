use flutter_rust_bridge::frb;
use serde::{Deserialize, Serialize};
use std::sync::Mutex;
use webrtc_audio_processing::{ProcessorBuilder, ProcessorConfig};
use nnnoiseless::DenoiseState;
use anyhow::{Result, anyhow};
use std::collections::VecDeque;
use std::sync::Arc;

// Ses işleme için yapılar
pub struct AudioProcessor {
    webrtc_processor: Mutex<webrtc_audio_processing::Processor>,
    noise_suppressor: Mutex<DenoiseState>,
    audio_buffer: Mutex<VecDeque<Vec<f32>>>,
}

// WebRTC bağlantı durumları için yapılar
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Room {
    pub id: String,
    pub name: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Participant {
    pub id: String,
    pub name: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct IceServer {
    pub urls: Vec<String>,
    pub username: Option<String>,
    pub credential: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WebRTCConfig {
    pub ice_servers: Vec<IceServer>,
}

// Konuşma tanıma için yapılar
pub struct SpeechRecognizer {
    buffer: Mutex<VecDeque<Vec<f32>>>,
    // Whisper modeli burada başlatılacak
}

// Singleton örneği
static mut AUDIO_PROCESSOR: Option<Arc<AudioProcessor>> = None;
static mut SPEECH_RECOGNIZER: Option<Arc<SpeechRecognizer>> = None;

// Flutter'dan çağrılacak API fonksiyonları
#[frb(dart_metadata = "")]
pub fn initialize_audio_processor() -> Result<bool> {
    let config = ProcessorConfig::default();
    let webrtc_processor = ProcessorBuilder::new()
        .config(config)
        .build()
        .map_err(|e| anyhow!("WebRTC processor initialization failed: {}", e))?;
    
    let noise_suppressor = DenoiseState::new();
    
    let processor = AudioProcessor {
        webrtc_processor: Mutex::new(webrtc_processor),
        noise_suppressor: Mutex::new(noise_suppressor),
        audio_buffer: Mutex::new(VecDeque::new()),
    };
    
    unsafe {
        AUDIO_PROCESSOR = Some(Arc::new(processor));
    }
    
    Ok(true)
}

#[frb(dart_metadata = "")]
pub fn initialize_speech_recognizer() -> Result<bool> {
    let recognizer = SpeechRecognizer {
        buffer: Mutex::new(VecDeque::new()),
    };
    
    unsafe {
        SPEECH_RECOGNIZER = Some(Arc::new(recognizer));
    }
    
    Ok(true)
}

#[frb(dart_metadata = "")]
pub fn process_audio(audio_data: Vec<f32>) -> Result<Vec<f32>> {
    let processor = unsafe {
        match &AUDIO_PROCESSOR {
            Some(p) => p.clone(),
            None => return Err(anyhow!("Audio processor not initialized")),
        }
    };
    
    // Gürültü engelleme uygula
    let mut noise_suppressor = processor.noise_suppressor.lock().unwrap();
    let mut processed_data = audio_data.clone();
    noise_suppressor.process_frame(&mut processed_data);
    
    // WebRTC ses işleme (yankı engelleme) uygula
    // Not: Gerçek uygulamada, WebRTC işlemcisi için uygun format dönüşümleri yapılmalıdır
    
    // İşlenmiş ses verisini tampona ekle (konuşma tanıma için)
    let mut buffer = processor.audio_buffer.lock().unwrap();
    buffer.push_back(processed_data.clone());
    
    // Tampon boyutu sınırını aşarsa, eski verileri kaldır
    while buffer.len() > 100 {
        buffer.pop_front();
    }
    
    Ok(processed_data)
}

#[frb(dart_metadata = "")]
pub fn recognize_speech() -> Result<Option<String>> {
    let recognizer = unsafe {
        match &SPEECH_RECOGNIZER {
            Some(r) => r.clone(),
            None => return Err(anyhow!("Speech recognizer not initialized")),
        }
    };
    
    let processor = unsafe {
        match &AUDIO_PROCESSOR {
            Some(p) => p.clone(),
            None => return Err(anyhow!("Audio processor not initialized")),
        }
    };
    
    // Ses tamponundan veri al
    let buffer = processor.audio_buffer.lock().unwrap();
    if buffer.is_empty() {
        return Ok(None);
    }
    
    // Gerçek uygulamada, burada Whisper modeli kullanılarak konuşma tanıma yapılacak
    // Şimdilik örnek bir metin döndürüyoruz
    Ok(Some("Merhaba, bu bir test metnidir.".to_string()))
}

#[frb(dart_metadata = "")]
pub fn analyze_frequency(audio_data: Vec<f32>) -> Result<Vec<f32>> {
    // Gerçek uygulamada, burada FFT kullanılarak frekans analizi yapılacak
    // Şimdilik örnek bir veri döndürüyoruz
    Ok(vec![0.1, 0.2, 0.3, 0.4, 0.5])
}

#[frb(dart_metadata = "")]
pub fn get_ice_servers() -> Result<WebRTCConfig> {
    // Varsayılan STUN sunucuları
    let config = WebRTCConfig {
        ice_servers: vec![
            IceServer {
                urls: vec!["stun:stun.l.google.com:19302".to_string()],
                username: None,
                credential: None,
            },
            IceServer {
                urls: vec!["stun:stun1.l.google.com:19302".to_string()],
                username: None,
                credential: None,
            },
        ],
    };
    
    Ok(config)
}
