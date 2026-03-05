cleanup() {
  rm -f "$RUNNER_TEMP/AuthKey_$API_KEY_ID.p8"
}
trap cleanup EXIT

echo "▶️ Writing App Store Connect API key"
mkdir -p ~/.appstoreconnect/private_keys
echo "$API_KEY_CONTENT" | base64 --decode > ~/.appstoreconnect/private_keys/AuthKey_$API_KEY_ID.p8
echo "✅ API key written."

echo "▶️ Resolving .ipa file path"
IPA_FILE=$(ls $APP_PATH 2>/dev/null | head -1)

if [ "$IPA_FILE" == '' ]; then
  echo "::error::🚨 No .ipa file found at '$APP_PATH'. Make sure the iOS build step ran successfully before this action."
  exit 1
fi
echo "☑️ Found .ipa file: $IPA_FILE"

echo "▶️ Uploading to App Store Connect"
xcrun altool --upload-app --type ios --file "$IPA_FILE" --apiKey "$API_KEY_ID" --apiIssuer "$API_ISSUER_ID"
echo "✅ iOS App Store publish complete."
