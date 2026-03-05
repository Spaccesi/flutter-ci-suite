cleanup() {
  rm -f "$RUNNER_TEMP/AuthKey_$API_KEY_ID.p8"
}
trap cleanup EXIT

echo "▶️ Writing App Store Connect API key"
mkdir -p ~/.appstoreconnect/private_keys
echo "$API_KEY_CONTENT" | base64 --decode > ~/.appstoreconnect/private_keys/AuthKey_$API_KEY_ID.p8
echo "✅ API key written."

echo "▶️ Resolving .pkg file path"
PKG_FILE=$(ls $MACOS_APP_PATH 2>/dev/null | head -1)

if [ "$PKG_FILE" == '' ]; then
  echo "::error::🚨 No .pkg file found at '$MACOS_APP_PATH'. Make sure the macOS build step ran successfully before this action."
  exit 1
fi
echo "☑️ Found .pkg file: $PKG_FILE"

echo "▶️ Uploading to App Store Connect"
xcrun altool --upload-app --type osx --file "$PKG_FILE" --apiKey "$API_KEY_ID" --apiIssuer "$API_ISSUER_ID"
echo "✅ macOS App Store publish complete."
