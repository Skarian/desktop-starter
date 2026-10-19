#!/bin/bash
# Builds dist/<name>-<version>-macos-<arch>.dmg (arch: arm64 or x64). <name> is
# the package name in Cargo.toml. The app is ad-hoc signed, not notarized.
set -euo pipefail
cd "$(dirname "$0")/.."

case ${1:-$(uname -m)} in
  arm64 | aarch64) arch=arm64 target=aarch64-apple-darwin ;;
  x64 | x86_64) arch=x64 target=x86_64-apple-darwin ;;
  *) echo "Use arm64 or x64" >&2; exit 1 ;;
esac

# Read the app identity from Cargo.toml. Parse cargo's JSON with JavaScript
# for Automation, which is part of macOS.
metadata=$(cargo metadata --locked --no-deps --format-version 1)
field() { # Prints the package field at a dotted path. Stops if it is not text.
  osascript -l JavaScript -e '
    function run(argv) {
      const input = $.NSFileHandle.fileHandleWithStandardInput.readDataToEndOfFile;
      let value = JSON.parse($.NSString.alloc.initWithDataEncoding(input, $.NSUTF8StringEncoding).js).packages[0];
      for (const key of argv[0].split(".")) value = value?.[key];
      if (typeof value !== "string" || /[\x00-\x1f\x7f]/.test(value))
        throw new Error("In Cargo.toml, set package." + argv[0] + " to text without control characters.");
      return value;
    }' "$1" <<<"$metadata"
}
exe=$(field name)
version=$(field version)
name=$(field description)
bundle_id=$(field metadata.app.identifier)
bad_chars='[\/:*?"<>|{},]' # field rejects control characters.
if [[ -z $name || $name =~ $bad_chars ]]; then
  echo 'In Cargo.toml, set package.description to the app name. Do not use control characters or \ / : * ? " < > | { } ,' >&2
  exit 1
fi
if [[ ${#bundle_id} -gt 127 || ! $bundle_id =~ ^[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$ ]]; then
  echo 'In Cargo.toml, set package.metadata.app.identifier to a reverse-domain ID, for example com.example.my-app. Use only letters, digits, hyphens and periods, and 127 characters or fewer.' >&2
  exit 1
fi

MACOSX_DEPLOYMENT_TARGET=15.0 cargo build --release --locked --target "$target"

stage="dist/macos-$arch"
app="$stage/$name.app"
rm -rf "$stage"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "target/$target/release/$exe" "$app/Contents/MacOS/"
cp icons/icon.icns "$app/Contents/Resources/AppIcon.icns"
cat > "$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>${name//&/&amp;}</string>
<key>CFBundleIdentifier</key><string>$bundle_id</string>
<key>CFBundleExecutable</key><string>$exe</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>${version%%-*}</string>
<key>CFBundleVersion</key><string>${version%%-*}</string>
<key>LSMinimumSystemVersion</key><string>15.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
plutil -lint -s "$app/Contents/Info.plist"
codesign --force --sign - "$app"

ln -s /Applications "$stage/Applications"
hdiutil create -volname "$name" -srcfolder "$stage" -fs HFS+ -format UDZO -ov \
  "dist/$exe-$version-macos-$arch.dmg"
