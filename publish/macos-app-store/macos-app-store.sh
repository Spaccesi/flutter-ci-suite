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

PRODUCTS_DIR=$(dirname "$MACOS_APP_PATH")
PKG_FILE="$PRODUCTS_DIR/app.pkg"
productbuild --sign "$INSTALLER_IDENTITY" --component "$MACOS_APP_PATH" /Applications "$PKG_FILE"
echo "✅ Package created: $PKG_FILE"

echo "▶️ Uploading to App Store Connect"
xcrun altool --upload-app --type osx --file "$PKG_FILE" --apiKey "$API_KEY_ID" --apiIssuer "$API_ISSUER_ID"
echo "✅ macOS App Store publish complete."
