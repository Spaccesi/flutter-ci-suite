echo "::group::ℹ️ Installing Snapcraft"
sudo snap install snapcraft --classic
echo "::endgroup::"

echo "::group::ℹ️ Installing core24 snap"
sudo snap install core24 --channel=latest/stable
echo "::endgroup::"

echo "▶️ Extracting Flutter version from pubspec.yaml"
VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //;s/+.*//')

if [ "$VERSION" == '' ]; then
  echo "::error::🚨 Could not extract version from pubspec.yaml."
  exit 1
fi
echo "☑️ Version: $VERSION"

echo "▶️ Updating snapcraft.yaml version"
sed -i "s/^version: .*/version: \"$VERSION\"/" snap/snapcraft.yaml
echo "☑️ snapcraft.yaml updated."

echo "▶️ Building snap"
snapcraft pack --debug --use-lxd
echo "☑️ Snap built."

echo "▶️ Publishing to Snap Store"
snapcraft upload *.snap --release=stable
echo "✅ Snap Store publish complete."
