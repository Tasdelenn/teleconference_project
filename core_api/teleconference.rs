use std::collections::{HashMap, HashSet};
use std::sync::{Arc, Mutex};
use uuid::Uuid;

/// Temel ses yapılandırması
#[derive(Debug, Clone)]
pub struct AudioConfig {
    pub sample_rate: u32,
    pub channels: u8,
    pub bit_depth: u8,
    pub codec: String,
    pub network_bitrate: u32, // bit/s
    pub jitter_buffer_size: u32, // ms
}

/// Cihaz Türleri
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum DeviceType {
    Mobile,
    Server,
    RaspberryPi,
    LinuxBox,
    Unknown,
}

/// Cihaz bilgileri
#[derive(Debug, Clone)]
pub struct DeviceInfo {
    pub device_id: String,
    pub device_type: DeviceType,
    pub os_version: String,
    pub hardware_info: String,
    pub max_audio_channels: u8,
    pub supported_codecs: Vec<String>,
    pub network_capabilities: NetworkCapabilities,
}

/// Ağ Kapasiteleri
#[derive(Debug, Clone)]
pub struct NetworkCapabilities {
    pub max_upload_speed: u32, // bit/s
    pub max_download_speed: u32, // bit/s
    pub supports_udp: bool,
    pub supports_tcp: bool,
}

/// Katılımcı bilgileri
#[derive(Debug, Clone)]
pub struct Participant {
    pub participant_id: Uuid,
    pub display_name: String,
    pub device_info: DeviceInfo,
    pub is_muted: bool,
    pub joined_at: u64,
    pub last_active: u64,
    pub available_features: ParticipantFeatures,
}

/// Katılımcı Özellikleri
#[derive(Debug, Clone)]
pub struct ParticipantFeatures {
    pub can_share_screen: bool,
    pub can_send_chat: bool,
    pub supports_hardware_echo_cancellation: bool,
}

/// Oturum yapılandırması
#[derive(Debug)]
pub struct SessionConfig {
    pub max_participants: u8,
    pub requires_moderator: bool,
    pub audio_config: AudioConfig,
    pub enable_recording: bool,
    pub allowed_device_types: Vec<DeviceType>,
    pub adaptive_bitrate: bool,
    pub enable_transcription: bool,
}

/// Oturum bilgileri
#[derive(Debug)]
pub struct SessionInfo {
    pub session_id: Uuid,
    pub owner_id: Uuid,
    pub participants: Vec<Participant>,
    pub config: SessionConfig,
    pub created_at: u64,
    pub active_duration: u64,
    pub session_stats: SessionStats,
    pub waiting_room: Vec<Participant>,
    pub banned_devices: Vec<String>,
}

/// Oturum İstatistikleri
#[derive(Debug)]
pub struct SessionStats {
    pub audio_quality: SessionAudioQuality,
    pub network_latency: u32, // ms
    pub peak_participants: u8,
    pub total_data_used: u64, // bytes
}

/// Oturum Kalite Düzeyleri
#[derive(Debug)]
pub enum SessionAudioQuality {
    Low,
    Medium,
    High,
    Unavailable,
}

/// Chat Mesajı
#[derive(Debug, Clone)]
pub struct ChatMessage {
    pub sender_id: Uuid,
    pub content: String,
    pub timestamp: u64,
    pub is_whisper: bool,
    pub recipient_id: Option<Uuid>,
}

/// Ana telekonferans arayüzü
pub trait TeleconferenceCore {
    // Yeni bir oturum başlat
    fn initialize_session(
        &self,
        owner_id: Uuid,
        config: SessionConfig
    ) -> Result<SessionInfo, TeleconferenceError>;

    // Mevcut bir oturuma katıl
    fn join_session(
        &self,
        participant: Participant
    ) -> Result<SessionInfo, TeleconferenceError>;

    // Özel de sokağa özel talepler için sanal katılması
    fn join_session_with_request(
        &self,
        participant: Participant,
        join_request: JoinRequestType
    ) -> Result<SessionInfo, TeleconferenceError>;

    // Oturumdan çık
    fn leave_session(
        &self,
        participant_id: Uuid
    ) -> Result<(), TeleconferenceError>;

    // Aktif oturumun mevcut durumunu al
    fn get_session_info(
        &self,
        session_id: Uuid
    ) -> Result<SessionInfo, TeleconferenceError>;

    // Otorizasyon ayarları için bir yetkili manyak katılması
    fn authorize_moderator(
        &self, 
        moderator_id: Uuid
    ) -> Result<(), TeleconferenceError>;

    // Kalıcı bir oturum ile kuruluysak de değişklik katkıları yollarız
    fn update_session_config(
        &self,
        session_id: Uuid,
        config_update: SessionConfigUpdate
    ) -> Result<SessionInfo, TeleconferenceError>;

    // Parsiyel yapıda ses verisi gönderimi
    fn send_audio_data(
        &self, 
        participant_id: Uuid, 
        data: &[i16]
    ) -> Result<(), TeleconferenceError>;

    // Alınan ses verisini almak için callback
    fn on_audio_receive<F>(&self, callback: F)
    where
        F: Fn(Participant, &[i16]) + Send + Sync + 'static;

    // Chat mesajı gönder
    fn send_chat_message(
        &self,
        sender_id: Uuid,
        message: ChatMessage
    ) -> Result<(), TeleconferenceError>;

    // Chat mesajları dinlemek için callback
    fn on_chat_receive<F>(&self, callback: F)
    where
        F: Fn(ChatMessage) + Send + Sync + 'static;

    // Bir katılımcıyı oturum dışı bırak
    fn ban_participant(
        &self,
        moderator_id: Uuid,
        participant_id: Uuid
    ) -> Result<(), TeleconferenceError>;

    // Bir cihazı yasakla ve kalıcı bir şekilde oturumdan çıkar
    fn ban_device(
        &self,
        moderator_id: Uuid,
        device_id: &str
    ) -> Result<(), TeleconferenceError>;

    // Cihaz güncelleme için yetkili talebi gönder
    fn request_device_upgrade(
        &self,
        device_id: &str,
        upgrade_type: DeviceUpgradeType
    ) -> Result<(), TeleconferenceError>;
}

/// Hatalar için temel enum
#[derive(Debug)]
pub enum TeleconferenceError {
    SessionNotFound,
    ParticipantNotFound,
    SessionFull,
    UnauthorizedAction,
    AudioDeviceError(String),
    NetworkError(String),
    DeviceUpgradeError(String),
    InternalError(String),
    InvalidDeviceType,
    InvalidConfigurationException(String),
    ModerationError(String),
    ChatError(String),
}

/// Oturuma katılma talebi 
#[derive(Debug)]
pub enum JoinRequestType {
    DirectJoin, // Otomatik katılır
    PendingApproval, // Onay bekler
    JoinWithCustomConfig(AudioConfig), // Özel ses yapılandırması ile
}

/// Oturum yapılandırma güncelleme
#[derive(Debug)]
pub struct SessionConfigUpdate {
    pub optional_max_participants: Option<u8>,
    pub optional_requires_moderator: Option<bool>,
    pub optional_audio_config: Option<AudioConfig>,
    pub optional_enable_recording: Option<bool>,
    pub optional_allowed_device_types: Option<Vec<DeviceType>>,
    pub optional_adaptive_bitrate: Option<bool>,
    pub optional_enable_transcription: Option<bool>,
}

/// Cihaz yükseltme talepleri
#[derive(Debug)]
pub enum DeviceUpgradeType {
    FirmwareUpdate,
    SoftwareUpdate,
    CapabilityRequest(String), // Ek yetki istekleri
}