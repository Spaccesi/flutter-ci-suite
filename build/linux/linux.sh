set -e

echo "::group::ℹ️ Installing Linux build dependencies"
sudo apt-get update && sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
echo "::endgroup::"
echo "☑️ Linux build dependencies available"

FLAGS="--$BUILD_MODE"
[ "$BUILD_NAME" != '' ] && FLAGS="$FLAGS --build-name=$BUILD_NAME"
[ "$BUILD_NUMBER" != '' ] && FLAGS="$FLAGS --build-number=$BUILD_NUMBER"
[ "$DART_DEFINE" != '' ] && FLAGS="$FLAGS --dart-define=$DART_DEFINE"
[ "$DART_DEFINE_FROM_FILE" != '' ] && FLAGS="$FLAGS --dart-define-from-file=$DART_DEFINE_FROM_FILE"
[ "$OBFUSCATE" != 'true' ] && FLAGS="$FLAGS --no-obfuscate"
[ "$NO_PUB" == 'true' ] && FLAGS="$FLAGS --no-pub"
[ "$SPLIT_DEBUG_INFO" != '' ] && FLAGS="$FLAGS --split-debug-info=$SPLIT_DEBUG_INFO"
[ "$NO_TREE_SHAKE_ICONS" == 'true' ] && FLAGS="$FLAGS --no-tree-shake-icons"
[ "$NO_ANALYZE_SIZE" == 'true' ] && FLAGS="$FLAGS --no-analyze-size"
[ "$CODE_SIZE_DIRECTORY" != '' ] && FLAGS="$FLAGS --code-size-directory=$CODE_SIZE_DIRECTORY"
[ "$TARGET_PLATFORM" != '' ] && FLAGS="$FLAGS --target-platform=$TARGET_PLATFORM"
[ "$TARGET_SYSROOT" != '' ] && FLAGS="$FLAGS --target-sysroot=$TARGET_SYSROOT"

echo "▶️ Running flutter build linux with flags: $FLAGS"
flutter build linux $FLAGS
echo "✅ Linux build complete."
