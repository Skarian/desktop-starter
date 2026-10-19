//! Embeds the icon and version into the Windows executable.

fn main() {
    println!("cargo:rerun-if-changed=icons/icon.ico");
    if std::env::var("CARGO_CFG_TARGET_OS").as_deref() != Ok("windows") {
        return;
    }
    let name = env!("CARGO_PKG_DESCRIPTION");
    // set_icon uses resource ID 1, where GPUI loads the window icon from.
    winresource::WindowsResource::new()
        .set_icon("icons/icon.ico")
        .set("FileDescription", name)
        .set("ProductName", name)
        .compile()
        .unwrap();
}
