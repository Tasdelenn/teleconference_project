// core_api/mod.rs

pub mod teleconference;  // Teleconference modülünü dışa aç
pub mod message;

// Yaygın kullanılan yapıları doğrudan erişilebilir yap
pub use teleconference::{
    AudioConfig, DeviceType, DeviceInfo, NetworkCapabilities,
    Participant, ParticipantFeatures, SessionConfig, SessionInfo,
    SessionStats, SessionAudioQuality, ChatMessage, TeleconferenceCore,
    TeleconferenceError, JoinRequestType, SessionConfigUpdate,
    DeviceUpgradeType, get_current_timestamp
};

pub use message::{ClientMessage, ServerMessage};

pub type TeleconferenceResult<T> = Result<T, TeleconferenceError>;