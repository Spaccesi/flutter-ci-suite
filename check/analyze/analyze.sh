FLAGS=""
[ "$ANALYZE_FAILS_IF_INFOS" == 'false' ] && FLAGS="$FLAGS --no-fatal-infos"
[ "$ANALYZE_FAILS_IF_WARNINGS" == 'false' ] && FLAGS="$FLAGS --no-fatal-warnings"
[ "$NO_PUB" == 'true' ] && FLAGS="$FLAGS --no-pub"

echo "▶️ Running flutter analyze with flags: $FLAGS"
flutter analyze . $FLAGS
echo "✅ Analysis passed."
