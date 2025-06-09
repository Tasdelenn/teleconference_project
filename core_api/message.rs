// core_api/message.rs

use uuid::Uuid;
use crate::core_api::teleconference::{
    SessionConfigUpdate, TeleconferenceError, ChatMessage, SessionInfo,
    Participant, DeviceInfo, SessionAudioQuality
};

/// İstemciden sunucuya gönderilecek mesaj türleri
#[derive(Debug, Clone)]
pub enum ClientMessage {
    /// Bağlantı kurma isteği
    Connect {
        session_id: Uuid,
        participant_id: Uuid,
        device_info: DeviceInfo,
    },
    
    /// Bağlanı kesme isteği
    Disconnect {
        participant_id: Uuid,
    },
    
    /// Ses verisi gönderimi
    AudioData {
        participant_id: Uuid,
        data: Vec<i16>, // 16-bit ses verisi
    },
    
    /// Metin mesajı gönderimi
    TextMessage {
        participant_id: Uuid,
        message: String,
    },
    
    /// Oturumu yeniden yapılandırma isteği
    Reconfigure {
        session_id: Uuid,
        config_update: SessionConfigUpdate,
    },
    
    /// Özel komut istekleri
    CustomCommand {
        command: String,
        payload: Vec<u8>,
    }
}

/// Sunucudan istemciye gönderilecek mesaj türleri
#[derive(Debug, Clone)]
pub enum ServerMessage {
    /// Bağlantı kabul edildi
    Connected {
        session_info: SessionInfo,
        is_muted: bool,
    },
    
    /// Yeni bir katılımcının oturuma katıldığını bildirir
    ParticipantJoined {
        participant: Participant,
    },
    
    /// Bir katılımcının oturumdan ayrıldığını bildirir
    ParticipantLeft {
        participant_id: Uuid,
    },
    
    /// Ses verisi alındı
    AudioReceived {
        participant: Participant,
        data: Vec<i16>,
    },
    
    /// Bir metin mesajı alındı
    TextMessageReceived {
        message: ChatMessage,
    },
    
    /// Oturum yapılandırması değişti
    SessionUpdated {
        session_info: SessionInfo,
    },
    
    /// Sunucudan hata bildirimi
    Error {
        error: TeleconferenceError,
    },
    
    /// Özel sunucu yanıtları
    CustomResponse {
        command: String,
        payload: Vec<u8>,
    },
    
    /// Kalite değişikliği bildirimi
    QualityUpdate {
        quality: SessionAudioQuality,
    }
}

// Helper fonksiyonları (ileride detaylandırılacak)
impl ClientMessage {
    pub fn serialize(&self) -> Result<Vec<u8>, TeleconferenceError> {
        // Bu fonksiyon, serde veya custom bir binary format ile istemci mesajlarını 
        // byte dizisine çevirir. Şimdi yalnızca tasviri yapıyoruz.
        todo!("İstemci mesajlarını serileştirme fonksiyonu burada uygulanacak")
    }

    pub fn deserialize(data: &[u8]) -> Result<Self, TeleconferenceError> {
        // Bu fonksiyon, incoming byte akışını istemci mesajlarına çevirir.
        todo!("İstemci mesajlarını deserileştirme fonksiyonu burada uygulanacak")
    }
}

impl ServerMessage {
    pub fn serialize(&self) -> Result<Vec<u8>, TeleconferenceError> {
        // Bu fonksiyon, serde veya custom bir binary format ile server mesajlarını 
        // byte dizisine çevirir.
        todo!("Sunucu mesajlarını serileştirme fonksiyonu burada uygulanacak")
    }

    pub fn deserialize(data: &[u8]) -> Result<Self, TeleconferenceError> {
        // Bu fonksiyon, incoming byte akışını server mesajlarına çevirir.
        todo!("Sunucu mesajlarını deserileştirme fonksiyonu burada uygulanacak")
    }
}