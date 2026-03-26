set -e

FLAGS="--$BUILD_MODE"
[ "$DART_DEFINE" != '' ] && FLAGS="$FLAGS --dart-define=$DART_DEFINE"
[ "$BUILD_NUMBER" != '' ] && FLAGS="$FLAGS --build-number=$BUILD_NUMBER"
[ "$BUILD_NAME" != '' ] && FLAGS="$FLAGS --build-name=$BUILD_NAME"
[ "$TARGET" != '' ] && FLAGS="$FLAGS -t $TARGET"
[ "$NO_PUB" == 'true' ] && FLAGS="$FLAGS --no-pub"
[ "$BASE_HREF" != '' ] && FLAGS="$FLAGS --base-href=$BASE_HREF"
[ "$STATIC_ASSETS_URL" != '' ] && FLAGS="$FLAGS --static-assets-url=$STATIC_ASSETS_URL"
[ "$WASM" == 'true' ] && FLAGS="$FLAGS --wasm"
FLAGS="$FLAGS --output=${OUTPUT:-build/web}"

echo "▶️ Running flutter build web with flags: $FLAGS"
flutter build web $FLAGS
echo "✅ Web build complete."

ARTIFACT_PATH="${OUTPUT:-build/web}"
echo "artifact-path=$ARTIFACT_PATH" >> "$GITHUB_OUTPUT"
echo "✅ Artifact path: $ARTIFACT_PATH"
