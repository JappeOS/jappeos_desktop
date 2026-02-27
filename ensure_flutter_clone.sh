#!/usr/bin/env bash
# Ensure Flutter is cloned locally to vendor/flutter_clone/. Use existing clone if valid.
# Run from repo root. Used by Docker build (flutter is COPY'd into image).

set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"
FLUTTER_DIR="${ROOT}/vendor/flutter_clone"
FLUTTER_CHANNEL="${FLUTTER_CHANNEL:-stable}"

is_valid_flutter_clone() {
  [[ -x "${FLUTTER_DIR}/bin/flutter" ]] || return 1
  [[ -d "${FLUTTER_DIR}/.git" ]] || return 1
  git -C "${FLUTTER_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 1
  return 0
}

if is_valid_flutter_clone; then
  echo "Using existing Flutter clone at ${FLUTTER_DIR}"
  exit 0
fi

if [[ -d "${FLUTTER_DIR}" ]]; then
  echo "Existing ${FLUTTER_DIR} is not a valid git clone. Recreating it..."
  rm -rf "${FLUTTER_DIR}"
fi

echo "Cloning Flutter (${FLUTTER_CHANNEL}) to ${FLUTTER_DIR}..."
mkdir -p "$(dirname "${FLUTTER_DIR}")"
git clone -b "${FLUTTER_CHANNEL}" --depth 1 https://github.com/flutter/flutter.git "${FLUTTER_DIR}"
echo "Configuring Flutter (linux-desktop) and running precache..."
"${FLUTTER_DIR}/bin/flutter" config --enable-linux-desktop
"${FLUTTER_DIR}/bin/flutter" precache
echo "Flutter cloned and ready."
