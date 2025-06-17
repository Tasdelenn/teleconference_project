// Flutter Rust Bridge için FFI tanımlamaları
use crate::api;
use anyhow::Result;
use flutter_rust_bridge::frb;

// Ses işleme modülünü başlat
#[frb(sync)]
pub fn initialize_audio_processor() -> Result<bool> {
    api::initialize_audio_processor()
}

// Ses verilerini işle
#[frb(sync)]
pub fn process_audio(audio_data: Vec<f32>) -> Result<Vec<f32>> {
    api::process_audio(audio_data)
}

// Gelişmiş ses işleme
#[frb(sync)]
pub fn process_audio_advanced(
    audio_data: Vec<f32>,
    mode: i32,
    echo_cancel: bool,
    noise_reduction: bool,
    auto_gain_control: bool,
    microphone_mode: i32,
    volume_level: i32,
) -> Result<Vec<f32>> {
    api::process_audio_advanced(
        audio_data,
        mode,
        echo_cancel,
        noise_reduction,
        auto_gain_control,
        microphone_mode,
        volume_level,
    )
}

// Ses seviyesini ayarla
#[frb(sync)]
pub fn set_volume_level(level: i32) -> Result<bool> {
    api::set_volume_level(level)
}

// İşleme modunu ayarla
#[frb(sync)]
pub fn set_audio_processing_mode(mode: i32) -> Result<bool> {
    api::set_audio_processing_mode(mode)
}

// Mikrofon modunu ayarla
#[frb(sync)]
pub fn set_microphone_mode(mode: i32) -> Result<bool> {
    api::set_microphone_mode(mode)
}

// Yankı iptalini ayarla
#[frb(sync)]
pub fn set_echo_cancel(enabled: bool) -> Result<bool> {
    api::set_echo_cancel(enabled)
}

// Gürültü azaltmayı ayarla
#[frb(sync)]
pub fn set_noise_reduction(enabled: bool) -> Result<bool> {
    api::set_noise_reduction(enabled)
}

// Otomatik kazanç kontrolünü ayarla
#[frb(sync)]
pub fn set_auto_gain_control(enabled: bool) -> Result<bool> {
    api::set_auto_gain_control(enabled)
}

// Cihaz yapılandırma
#[frb(sync)]
pub fn configure_audio_device(device_id: String, device_type: String) -> Result<bool> {
    api::configure_audio_device(device_id, device_type)
}

// Frekans analizi
#[frb(sync)]
pub fn analyze_frequency(audio_data: Vec<f32>) -> Result<Vec<f32>> {
    api::analyze_frequency(audio_data)
}

// Ses kalitesini hesapla
#[frb(sync)]
pub fn calculate_signal_quality() -> Result<f32> {
    api::calculate_signal_quality()
}

// USB cihazları algıla
#[frb(sync)]
pub fn detect_audio_devices() -> Result<serde_json::Value> {
    api::detect_audio_devices()
}
