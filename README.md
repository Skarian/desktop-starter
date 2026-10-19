# Desktop Starter

A small baseline for native desktop apps in Rust with
[GPUI Kit](https://gpui-kit.com), for Windows and macOS. The app is one window
with a button and a counter. The starter also includes an app icon, a Windows
installer, macOS DMGs and a release workflow.

To run the app:

```sh
cargo run
```

## Prerequisites

- Rust 1.92 or newer.
- On Windows: Visual Studio Build Tools with the C++ workload.
- On macOS: Xcode or the Xcode command-line tools.

## Start a new app from this

1. Copy the repository.
2. In `Cargo.toml`, set these three values:
   - `name`: the package name. The executable and the package files use this
     name.
   - `description`: the app name that users see. Do not use control characters
     or these characters: `\ / : * ? " < > | { } ,`
   - `identifier` in `[package.metadata.app]`: a unique reverse-domain ID, for
     example `com.yourcompany.your-app`. The macOS bundle ID and the Windows
     installer `AppId` use this value.
3. Run `cargo update --workspace` to update `Cargo.lock`.
4. Replace `icons/icon.svg`. Use a square image with a transparent background.
5. Regenerate the icons with the
   [Tauri CLI](https://v2.tauri.app/develop/icons/). The Tauri CLI needs
   Node.js. Normal builds do not need Node.js.

   ```sh
   npx --yes @tauri-apps/cli@2.12.3 icon icons/icon.svg --output icons
   ```

6. Write your app in `src/main.rs`.
7. Change the title of this README. Change the copyright holder in `LICENSE`.

Do not change the identifier after your first release. Upgrades use it to find
existing installs.

## Layout

- `src/main.rs`: the app
- `build.rs`: Windows icon and version info
- `installer/app.iss`, `scripts/`: Windows and macOS packaging
- `.github/workflows/`: CI (format and build) and release

## Releasing

1. Set the version in `Cargo.toml`.
2. Run `cargo update --workspace` to update `Cargo.lock`.
3. Merge both files to `main`.
4. Push a matching tag:

   ```sh
   git tag v0.2.0
   git push origin v0.2.0
   ```

The release workflow builds these packages:

- A Windows installer and a Windows zip.
- macOS DMGs for Apple Silicon and Intel. These apps need macOS 15 or later.

The workflow publishes the packages and `SHA256SUMS.txt` as a GitHub release.
If the tag has a hyphen (for example `v0.2.0-rc.1`), the workflow publishes a
prerelease.

To build packages locally:

- On Windows, run `.\scripts\build-windows.ps1`. The installer needs
  [Inno Setup 6](https://jrsoftware.org/isinfo.php).
- On macOS, run `bash scripts/package-macos.sh`. The script builds for the
  architecture of your Mac.

Windows builds are not code-signed. The macOS script applies an ad-hoc
signature, but it does not notarize the app. Thus Windows SmartScreen and
macOS Gatekeeper show a warning on first launch. On Windows, choose
**More info → Run anyway**. On macOS, go to
**System Settings → Privacy & Security → Open Anyway**.

## License

MIT, see [LICENSE](LICENSE).
