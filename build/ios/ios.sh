if [ "$CODE_SIGN" == 'true' ]; then
  KEYCHAIN_PASSWORD='dist_password'
  KEYCHAIN_PATH=$RUNNER_TEMP/app-signing.keychain-db

  echo "▶️ Installing Apple certificate"
  CERTIFICATE_PATH=$RUNNER_TEMP/build_certificate.p12
  echo -n "$IOS_DISTRIBUTION_CERTIFICATE_BASE64" | base64 --decode -o $CERTIFICATE_PATH
  security create-keychain -p "$KEYCHAIN_PASSWORD" $KEYCHAIN_PATH
  security set-keychain-settings -lut 21600 $KEYCHAIN_PATH
  security unlock-keychain -p "$KEYCHAIN_PASSWORD" $KEYCHAIN_PATH
  security import $CERTIFICATE_PATH -P "$IOS_DISTRIBUTION_CERTIFICATE_PASSWORD" -A -t cert -f pkcs12 -k $KEYCHAIN_PATH
  security list-keychain -d user -s $KEYCHAIN_PATH
  echo "✅ Apple certificate installed."

  echo "▶️ Installing provisioning profile"
  PP_PATH=$RUNNER_TEMP/build_pp.mobileprovision
  echo -n "$IOS_PROVISIONING_PROFILE_BASE64" | base64 --decode -o $PP_PATH
  mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
  cp $PP_PATH ~/Library/MobileDevice/Provisioning\ Profiles
  echo "✅ Provisioning profile installed."
fi

FLAGS="--$BUILD_MODE"
[ "$DART_DEFINE" != '' ] && FLAGS="$FLAGS --dart-define=$DART_DEFINE"
[ "$BUILD_NUMBER" != '' ] && FLAGS="$FLAGS --build-number=$BUILD_NUMBER"
[ "$BUILD_NAME" != '' ] && FLAGS="$FLAGS --build-name=$BUILD_NAME"
[ "$FLAVOR" != '' ] && FLAGS="$FLAGS --flavor=$FLAVOR"
[ "$TARGET" != '' ] && FLAGS="$FLAGS --target=$TARGET"
[ "$EXPORT_METHOD" != '' ] && FLAGS="$FLAGS --export-method $EXPORT_METHOD"
[ "$EXPORT_OPTIONS_PLIST" != '' ] && FLAGS="$FLAGS --export-options-plist=$EXPORT_OPTIONS_PLIST"
[ "$NO_PUB" == 'true' ] && FLAGS="$FLAGS --no-pub"
[ "$OBFUSCATE" != 'true' ] && FLAGS="$FLAGS --no-obfuscate"
[ "$CODE_SIGN" == 'false' ] && FLAGS="$FLAGS --no-codesign"

echo "▶️ Running flutter build ipa with flags: $FLAGS"
flutter build ipa $FLAGS
echo "✅ iOS build complete."
