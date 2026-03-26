set -e

if [ "$CODE_SIGN" != 'false' ]; then
  echo "▶️ Installing distribution certificate"
  KEYCHAIN_PASSWORD='dist_password'
  KEYCHAIN_PATH=$RUNNER_TEMP/app-signing.keychain-db

  # import certificate and provisioning profile from secrets
  CERTIFICATE_PATH=$RUNNER_TEMP/build_certificate.p12
  echo -n "$MACOS_DISTRIBUTION_CERTIFICATE_BASE64" | base64 --decode -o $CERTIFICATE_PATH

  # create temporary keychain
  security create-keychain -p "$KEYCHAIN_PASSWORD" $KEYCHAIN_PATH
  security set-keychain-settings -lut 21600 $KEYCHAIN_PATH
  security unlock-keychain -p "$KEYCHAIN_PASSWORD" $KEYCHAIN_PATH

  # import certificate to keychain
  security import $CERTIFICATE_PATH -P "$MACOS_DISTRIBUTION_CERTIFICATE_PASSWORD" -A -t cert -f pkcs12 -k $KEYCHAIN_PATH
  security list-keychain -d user -s $KEYCHAIN_PATH

  echo "✅ Distribution certificate installed."

  # -- Installing Installer certificate ------------------------------------------------------------------
  echo "▶️ Installing installer certificate"

  INSTALLER_CERTIFICATE_PATH=$RUNNER_TEMP/build_installer_certificate.p12

  # import certificate from secrets
  echo -n "$MACOS_INSTALLER_CERTIFICATE_BASE64" | base64 --decode -o $INSTALLER_CERTIFICATE_PATH

  # import certificate to keychain
  # Using -T /usr/bin/codesign to explicitly allow usage
  security import $INSTALLER_CERTIFICATE_PATH -P "$MACOS_INSTALLER_CERTIFICATE_PASSWORD" -T /usr/bin/codesign -t cert -f pkcs12 -k $KEYCHAIN_PATH
  echo "✅ Installer certificate installed."

  # -- Installing provisioning profile ------------------------------------------------------------------
  echo "▶️ Installing provisioning profile"

  PP_PATH=$RUNNER_TEMP/build_pp.provisionprofile

  # import provisioning profile from secrets
  echo -n "$MACOS_PROVISIONING_PROFILE_BASE64" | base64 --decode -o $PP_PATH

  # apply provisioning profile
  mkdir -p ~/Library/ProvisioningProfiles
  cp $PP_PATH ~/Library/ProvisioningProfiles

  # Extract UUID and copy with UUID name to ensure detection
  UUID=$(/usr/libexec/PlistBuddy -c 'Print :UUID' /dev/stdin <<< $(security cms -D -i $PP_PATH))
  cp $PP_PATH ~/Library/ProvisioningProfiles/$UUID.provisionprofile

  echo "✅ Provisioning profile installed (UUID: $UUID)."
fi

FLAGS="--$BUILD_MODE"
[ "$DART_DEFINE" != '' ] && FLAGS="$FLAGS --dart-define=$DART_DEFINE"
[ "$BUILD_NUMBER" != '' ] && FLAGS="$FLAGS --build-number=$BUILD_NUMBER"
[ "$BUILD_NAME" != '' ] && FLAGS="$FLAGS --build-name=$BUILD_NAME"
[ "$FLAVOR" != '' ] && FLAGS="$FLAGS --flavor=$FLAVOR"
[ "$TARGET" != '' ] && FLAGS="$FLAGS --target=$TARGET"
[ "$NO_PUB" == 'true' ] && FLAGS="$FLAGS --no-pub"
[ "$NO_OBFUSCATE" == 'true' ] && FLAGS="$FLAGS --no-obfuscate"

echo "▶️ Running flutter build macos with flags: $FLAGS"
flutter build macos $FLAGS
echo "✅ macOS build complete."

MODE_CAP="$(echo "${BUILD_MODE:0:1}" | tr '[:lower:]' '[:upper:]')${BUILD_MODE:1}"
ARTIFACT_PATH="build/macos/Build/Products/$MODE_CAP"
echo "artifact-path=$ARTIFACT_PATH" >> "$GITHUB_OUTPUT"
echo "✅ Artifact path: $ARTIFACT_PATH"
