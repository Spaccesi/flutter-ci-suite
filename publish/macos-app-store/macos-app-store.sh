cleanup() {
  rm -f "$RUNNER_TEMP/AuthKey_$API_KEY_ID.p8"
}
trap cleanup EXIT

echo "▶️ Writing App Store Connect API key"
mkdir -p ~/.appstoreconnect/private_keys
echo "$API_KEY_CONTENT" | base64 --decode > ~/.appstoreconnect/private_keys/AuthKey_$API_KEY_ID.p8
echo "✅ API key written."

echo "▶️ Packaging .app into .pkg"
INSTALLER_IDENTITY=$(security find-identity -v | grep "3rd Party Mac Developer Installer" | head -1 | sed 's/.*"\(.*\)".*/\1/')
if [ "$INSTALLER_IDENTITY" == '' ]; then
  echo "::error::🚨 No '3rd Party Mac Developer Installer' identity found in keychain. Make sure the installer certificate is installed."
  exit 1
fi
echo "☑️ Using installer identity: $INSTALLER_IDENTITY"

if [ "$MACOS_APP_PATH" == '' ]; then
  MACOS_APP_PATH=$(find build/macos/Build/Products/Release -maxdepth 1 -name "*.app" | head -1)
  if [ "$MACOS_APP_PATH" == '' ]; then
    echo "::error::🚨 No .app bundle found in build/macos/Build/Products/Release. Provide macos-app-path or build the app first."
    exit 1
  fi
  echo "☑️ Auto-detected app path: $MACOS_APP_PATH"
fi
PRODUCTS_DIR=$(dirname "$MACOS_APP_PATH")
APP_NAME=$(basename "$MACOS_APP_PATH" .app)
PKG_FILE="$PRODUCTS_DIR/$APP_NAME.pkg"
productbuild --component "$MACOS_APP_PATH" /Applications --sign "$INSTALLER_IDENTITY" "$PKG_FILE"
echo "✅ Package created: $PKG_FILE"

echo "▶️ Uploading to App Store Connect"
xcrun altool --upload-app --type osx --file "$PKG_FILE" --apiKey "$API_KEY_ID" --apiIssuer "$API_ISSUER_ID"
echo "✅ macOS App Store publish complete."
