cleanup() {
  rm -f service-account.json
}
trap cleanup EXIT

if ! command -v firebase >/dev/null 2>&1; then
  echo "▶️ Installing Firebase CLI"
  npm install -g firebase-tools
fi
echo "✅ Firebase CLI available."

echo "▶️ Decoding service account"
echo "$FIREBASE_SERVICE_ACCOUNT_BASE64" | base64 --decode > service-account.json
export GOOGLE_APPLICATION_CREDENTIALS=service-account.json
echo "✅ Service account decoded."

FLAGS="$FIREBASE_RELEASE_BINARY_FILE --app $FIREBASE_APP_ID"
[ "$FIREBASE_GROUPS" != '' ] && FLAGS="$FLAGS --groups $FIREBASE_GROUPS"
[ "$FIREBASE_GROUPS_FILE" != '' ] && FLAGS="$FLAGS --groups-file $FIREBASE_GROUPS_FILE"
[ "$FIREBASE_TESTERS" != '' ] && FLAGS="$FLAGS --testers $FIREBASE_TESTERS"
[ "$FIREBASE_TESTERS_FILE" != '' ] && FLAGS="$FLAGS --testers-file $FIREBASE_TESTERS_FILE"
[ "$FIREBASE_RELEASE_NOTES" != '' ] && FLAGS="$FLAGS --release-notes \"$FIREBASE_RELEASE_NOTES\""
[ "$FIREBASE_RELEASE_NOTES_FILE" != '' ] && FLAGS="$FLAGS --release-notes-file $FIREBASE_RELEASE_NOTES_FILE"
[ "$FIREBASE_DEBUG" == 'true' ] && FLAGS="$FLAGS --debug"
[ "$FIREBASE_TEST_DEVICES" != '' ] && FLAGS="$FLAGS --test-devices $FIREBASE_TEST_DEVICES"
[ "$FIREBASE_TEST_DEVICES_FILE" != '' ] && FLAGS="$FLAGS --test-devices-file $FIREBASE_TEST_DEVICES_FILE"
[ "$FIREBASE_TEST_USERNAME" != '' ] && FLAGS="$FLAGS --test-username $FIREBASE_TEST_USERNAME"
[ "$FIREBASE_TEST_USERNAME_FILE" != '' ] && FLAGS="$FLAGS --test-username-file $FIREBASE_TEST_USERNAME_FILE"
[ "$FIREBASE_TEST_PASSWORD" != '' ] && FLAGS="$FLAGS --test-password $FIREBASE_TEST_PASSWORD"
[ "$FIREBASE_TEST_PASSWORD_FILE" != '' ] && FLAGS="$FLAGS --test-password-file $FIREBASE_TEST_PASSWORD_FILE"
[ "$FIREBASE_TEST_NON_BLOCKING" == 'true' ] && FLAGS="$FLAGS --non-blocking"
[ "$FIREBASE_TEST_CASE_IDS" != '' ] && FLAGS="$FLAGS --test-case-ids $FIREBASE_TEST_CASE_IDS"
[ "$FIREBASE_TEST_CASE_IDS_FILE" != '' ] && FLAGS="$FLAGS --test-case-ids-file $FIREBASE_TEST_CASE_IDS_FILE"

echo "▶️ Publishing to Firebase App Distribution"
firebase appdistribution:distribute $FLAGS
echo "✅ Firebase App Distribution publish complete."
