set -e

if [ "$BUILD_MODE" != 'debug' ]; then
  echo "▶️ Decoding keystore"
  KEYSTORE_PATH="android/upload-keystore.jks"
  echo "$ANDROID_STORE_FILE_BASE64" | tr -d '[:space:]' | base64 --decode > "$KEYSTORE_PATH"
  echo "storeFile=../upload-keystore.jks" > android/key.properties
  echo "storePassword=$ANDROID_STORE_PASSWORD" >> android/key.properties
  echo "keyPassword=$ANDROID_KEY_PASSWORD" >> android/key.properties
  echo "keyAlias=$ANDROID_KEY_ALIAS" >> android/key.properties
  echo "✅ Keystore decoded and key.properties created."
fi

FLAGS="--$BUILD_MODE"
[ "$DART_DEFINE" != '' ] && FLAGS="$FLAGS --dart-define=$DART_DEFINE"
[ "$DART_DEFINE_FROM_FILE" != '' ] && FLAGS="$FLAGS --dart-define-from-file=$DART_DEFINE_FROM_FILE"
[ "$BUILD_NUMBER" != '' ] && FLAGS="$FLAGS --build-number=$BUILD_NUMBER"
[ "$BUILD_NAME" != '' ] && FLAGS="$FLAGS --build-name=$BUILD_NAME"
[ "$TARGET" != '' ] && FLAGS="$FLAGS -t $TARGET"
[ "$NO_PUB" == 'true' ] && FLAGS="$FLAGS --no-pub"
[ "$FLAVOR" != '' ] && FLAGS="$FLAGS --flavor=$FLAVOR"
[ "$NO_OBFUSCATE" == 'true' ] && FLAGS="$FLAGS --no-obfuscate"

echo "▶️ Running flutter build $BUILD_TYPE with flags: $FLAGS"
flutter build "$BUILD_TYPE" $FLAGS
echo "✅ Android build complete."

if [ "$BUILD_TYPE" = "apk" ]; then
  ARTIFACT_PATH="build/app/outputs/apk/$BUILD_MODE/app-$BUILD_MODE.apk"
else
  ARTIFACT_PATH="build/app/outputs/bundle/$BUILD_MODE/app-$BUILD_MODE.aab"
fi
echo "artifact-path=$ARTIFACT_PATH" >> "$GITHUB_OUTPUT"
echo "✅ Artifact path: $ARTIFACT_PATH"
