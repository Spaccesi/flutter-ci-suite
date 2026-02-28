cleanup() {
  rm -f google-application-credentials.json
}
trap cleanup EXIT

if ! command -v firebase >/dev/null 2>&1; then
  echo "▶️ Installing Firebase CLI"
  npm install -g firebase-tools
fi
echo "✅ Firebase CLI available."

echo "▶️ Decoding service account"
echo "$FIREBASE_SERVICE_ACCOUNT_BASE64" | base64 --decode > google-application-credentials.json
export GOOGLE_APPLICATION_CREDENTIALS=google-application-credentials.json
echo "✅ Service account decoded."

FLAGS="--only hosting"
[ "$FIREBASE_TARGET" != '' ] && FLAGS="--only hosting:$FIREBASE_TARGET"
[ "$FIREBASE_PROJECT_ID" != '' ] && FLAGS="$FLAGS --project $FIREBASE_PROJECT_ID"
[ "$FIREBASE_DEBUG" == 'true' ] && FLAGS="$FLAGS --debug"
[ "$FIREBASE_MESSAGE" != '' ] && FLAGS="$FLAGS --message $FIREBASE_MESSAGE"

echo "▶️ Deploying to Firebase Hosting"
firebase deploy $FLAGS
echo "✅ Firebase Hosting deploy complete."
