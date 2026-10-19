#!/usr/bin/env sh
set -eu

: "${DIPLODOCUS_VERSION:?}"
: "${DIPLODOCUS_ASSET:?}"
: "${DIPLODOCUS_INSTALL_DIR:?}"

asset="$DIPLODOCUS_ASSET"
base="https://github.com/jolars/diplodocus/releases/download/${DIPLODOCUS_VERSION}"
installer_dir="$(mktemp -d)"
trap 'rm -rf "$installer_dir"' 0
trap 'exit 1' HUP INT TERM

echo "Downloading ${asset} (${DIPLODOCUS_VERSION})..."
curl --proto '=https' --tlsv1.2 -fLsS "${base}/${asset}" -o "$installer_dir/$asset"
curl --proto '=https' --tlsv1.2 -fLsS "${base}/${asset}.sha256" -o "$installer_dir/checksum"

expected="$(awk -v asset="$asset" '{name=$2; sub(/^\*/, "", name); if (name == asset) print tolower($1)}' "$installer_dir/checksum")"
if [ "${#expected}" -ne 64 ]; then
	echo "Missing or invalid SHA256 checksum for ${asset}" >&2
	exit 1
fi
if command -v sha256sum >/dev/null 2>&1; then
	actual="$(sha256sum "$installer_dir/$asset" | awk '{print $1}')"
else
	actual="$(shasum -a 256 "$installer_dir/$asset" | awk '{print $1}')"
fi
if [ "$actual" != "$expected" ]; then
	echo "Checksum verification failed for ${asset}" >&2
	exit 1
fi
echo "Verified ${asset} (sha256)"

if command -v gh >/dev/null 2>&1; then
	if attestation="$(gh attestation verify "$installer_dir/$asset" --repo jolars/diplodocus 2>&1)"; then
		echo "Verified ${asset} provenance (attestation)"
	elif printf '%s' "$attestation" | grep -qiE 'no attestation|http 404'; then
		echo "Warning: no provenance attestation for this release; skipping" >&2
	else
		echo "Provenance verification failed for ${asset}" >&2
		echo "$attestation" >&2
		exit 1
	fi
else
	echo "Warning: gh CLI not found; skipping provenance verification" >&2
fi

tar -xJf "$installer_dir/$asset" -C "$installer_dir"
mkdir -p "$DIPLODOCUS_INSTALL_DIR"
install -m 755 "$installer_dir/${asset%.tar.xz}/diplodocus" "$DIPLODOCUS_INSTALL_DIR/diplodocus"
echo "Installed Diplodocus to ${DIPLODOCUS_INSTALL_DIR}/diplodocus"
