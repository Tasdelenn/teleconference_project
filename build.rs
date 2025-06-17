fn main() {
    // Bu dosya, Flutter Rust Bridge için gerekli yapılandırmaları içerir
    println!("cargo:rerun-if-changed=lib.rs");
    println!("cargo:rerun-if-changed=build.rs");
}
