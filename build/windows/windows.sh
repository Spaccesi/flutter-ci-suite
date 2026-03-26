set -e

FLAGS="--$BUILD_MODE"
[ "$BUILD_NAME" != '' ] && FLAGS="$FLAGS --build-name=$BUILD_NAME"
[ "$BUILD_NUMBER" != '' ] && FLAGS="$FLAGS --build-number=$BUILD_NUMBER"
[ "$DART_DEFINE" != '' ] && FLAGS="$FLAGS --dart-define=$DART_DEFINE"
[ "$DART_DEFINE_FROM_FILE" != '' ] && FLAGS="$FLAGS --dart-define-from-file=$DART_DEFINE_FROM_FILE"
[ "$TARGET" != '' ] && FLAGS="$FLAGS --target=$TARGET"
[ "$TRACK_WIDGET_CREATION" == 'true' ] && FLAGS="$FLAGS --track-widget-creation"
[ "$CONFIG_ONLY" == 'true' ] && FLAGS="$FLAGS --config-only"
[ "$NO_OBFUSCATE" == 'true' ] && FLAGS="$FLAGS --no-obfuscate"
[ "$NO_PUB" == 'true' ] && FLAGS="$FLAGS --no-pub"
[ "$SPLIT_DEBUG_INFO" != '' ] && FLAGS="$FLAGS --split-debug-info=$SPLIT_DEBUG_INFO"
[ "$NO_TREE_SHAKE_ICONS" == 'true' ] && FLAGS="$FLAGS --no-tree-shake-icons"
[ "$NO_ANALYZE_SIZE" == 'true' ] && FLAGS="$FLAGS --no-analyze-size"
[ "$CODE_SIZE_DIRECTORY" != '' ] && FLAGS="$FLAGS --code-size-directory=$CODE_SIZE_DIRECTORY"

echo "▶️ Running flutter build windows with flags: $FLAGS"
flutter build windows $FLAGS
echo "✅ Windows build complete."

MODE_CAP="$(echo "${BUILD_MODE:0:1}" | tr '[:lower:]' '[:upper:]')${BUILD_MODE:1}"
ARTIFACT_PATH="build/windows/x64/runner/$MODE_CAP"
echo "artifact-path=$ARTIFACT_PATH" >> "$GITHUB_OUTPUT"
echo "✅ Artifact path: $ARTIFACT_PATH"
