#!/usr/bin/env bash
# Docker-first build helper for Flutter desktop compositor bundle.
# Usage:
#   ./run_build.sh build-image   # build/rebuild shared builder/runtime images
#   ./run_build.sh               # docker release build + export bundle
#   ./run_build.sh fast          # docker release build, skip flutter pub get
#   ./run_build.sh local         # local (non-docker) release build
#   ./run_build.sh debug         # docker debug bundle + export bundle
#   ./run_build.sh profile       # docker profile bundle + export bundle
#   ./run_build.sh <mode> --run  # run exported bundle after successful build

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${SCRIPT_DIR}"

CONFIG_FILE="${SCRIPT_DIR}/build_config.env"
if [[ -f "${CONFIG_FILE}" ]]; then
  # shellcheck source=/dev/null
  source "${CONFIG_FILE}"
fi

MODE="release"
RUN_AFTER_BUILD=0
RUN_ARGS=()
FLUTTER_BIN="${FLUTTER_BIN:-${SCRIPT_DIR}/vendor/flutter_clone/bin/flutter}"
WLR_ROOT="${WLR_ROOT:-${SCRIPT_DIR}/vendor/wlroots-install}"
WLR_SRC_ROOT="${WLR_SRC_ROOT:-${SCRIPT_DIR}/vendor/wlroots}"
BACKEND_DIR="${BACKEND_DIR:-${SCRIPT_DIR}/vendor/jdwm/native}"
TARGET="${APP_NAME:-$(basename "${SCRIPT_DIR}")}"
PROJECT_DIR="${PROJECT_DIR:-$(basename "${SCRIPT_DIR}")}"
ARCH="${ARCH:-$(uname -m)}"
OUTPUT_BASE="build/jappeos/${ARCH}"
BUILDER_IMAGE="zenith-wlroots-builder"
RUNTIME_IMAGE="zenith-wlroots-${TARGET}"

usage() {
  cat <<'EOF'
Usage:
  ./run_build.sh build-image
    Build/rebuild Docker images used by this script.

  ./run_build.sh
    Docker release build and export runtime bundle to:
    build/jappeos/<arch>/release/bundle

  ./run_build.sh fast
    Docker release build only (skip flutter pub get), then export:
    build/jappeos/<arch>/release/bundle

  ./run_build.sh local
    Local (non-docker) release build and export:
    build/jappeos/<arch>/release/bundle

  ./run_build.sh debug
    Docker debug bundle export to:
    build/jappeos/<arch>/debug/bundle

  ./run_build.sh profile
    Docker profile bundle export to:
    build/jappeos/<arch>/profile/bundle

Flags:
  --run, -r
    Run the exported bundle using run_<app_name>.sh after a successful build.
    You can pass app arguments after '--', e.g.:
    ./run_build.sh release --run -- --help

Environment:
  FLUTTER_BIN   Flutter executable (default: <repo>/<project_dir>/vendor/flutter_clone/bin/flutter)
  WLR_ROOT      Path to wlroots installation (default: <repo>/<project_dir>/vendor/wlroots-install)
  WLR_SRC_ROOT  Path to wlroots source tree (default: <repo>/<project_dir>/vendor/wlroots)
  ARCH          Output architecture folder (default: uname -m)
  APP_NAME      Binary/app name (default from build_config.env)
  PROJECT_DIR   Project directory name in docker build context (default from build_config.env)
EOF
}

parse_args() {
  local mode_set=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      build-image|release|fast|local|debug|profile)
        if (( mode_set )) && [[ "${MODE}" != "$1" ]]; then
          echo "Multiple modes provided: ${MODE} and $1"
          usage
          exit 1
        fi
        MODE="$1"
        mode_set=1
        shift
        ;;
      help|--help|-h)
        MODE="help"
        shift
        ;;
      --run|-r)
        RUN_AFTER_BUILD=1
        shift
        ;;
      --)
        shift
        RUN_ARGS=("$@")
        break
        ;;
      *)
        echo "Unknown argument: $1"
        usage
        exit 1
        ;;
    esac
  done
}

ensure_flutter_clone() {
  if [[ ! -x "${FLUTTER_BIN}" ]]; then
    (cd "${SCRIPT_DIR}" && ./ensure_flutter_clone.sh)
  fi
  if [[ ! -x "${FLUTTER_BIN}" ]]; then
    echo "Missing Flutter executable: ${FLUTTER_BIN}"
    exit 1
  fi
}

patch_shadcn_flutter_cache() {
  local shadcn_files=""
  shadcn_files="$(find "${HOME}/.pub-cache/git" -maxdepth 4 -type f -path "*/shadcn_flutter-*/lib/shadcn_flutter.dart" 2>/dev/null || true)"
  if [[ -z "${shadcn_files}" ]]; then
    return
  fi

  while IFS= read -r shadcn_file; do
    [[ -z "${shadcn_file}" ]] && continue
    local shadcn_dir
    shadcn_dir="$(dirname "${shadcn_file}")"

    # Flutter 3.32 widgets.dart no longer re-exports Brightness; shadcn expects it.
    if grep -q "show Icons, MaterialPageRoute, MaterialPage, SliverAppBar, FlutterLogo;" "${shadcn_file}"; then
      sed -i "s/show Icons, MaterialPageRoute, MaterialPage, SliverAppBar, FlutterLogo;/show Icons, MaterialPageRoute, MaterialPage, SliverAppBar, FlutterLogo, Brightness;/" "${shadcn_file}"
    fi

    # vector_math 2.1.x doesn't have scaleByDouble/translateByDouble.
    find "${shadcn_dir}/src" -type f -name "*.dart" -print0 | xargs -0 perl -0777 -i -pe \
      's/translateByDouble\(([^,]+),\s*([^,]+),\s*([^,]+),\s*([^)]+)\)/translate($1, $2, $3)/gs; s/scaleByDouble\(([^,]+),\s*([^,]+),\s*([^,]+),\s*([^)]+)\)/scale($1, $2, $3)/gs;'
  done <<< "${shadcn_files}"
}

ensure_wlroots() {
  if [[ ! -d "${WLR_ROOT}" ]]; then
    echo "Missing WLR_ROOT: ${WLR_ROOT}"
    exit 1
  fi
  if [[ ! -d "${WLR_SRC_ROOT}" ]]; then
    echo "Missing WLR_SRC_ROOT: ${WLR_SRC_ROOT}"
    exit 1
  fi
}

ensure_backend_dir() {
  if [[ ! -d "${BACKEND_DIR}" ]]; then
    echo "Missing BACKEND_DIR: ${BACKEND_DIR}"
    exit 1
  fi
}

setup_linker_paths() {
  local extra="-L/usr/local/lib -L/usr/local/lib/x86_64-linux-gnu -Wl,-rpath,/usr/local/lib -Wl,-rpath,/usr/local/lib/x86_64-linux-gnu"
  if [[ -n "${LDFLAGS:-}" ]]; then
    export LDFLAGS="${LDFLAGS} ${extra}"
  else
    export LDFLAGS="${extra}"
  fi
}

prepare_flutter_linux_build() {
  # Some Flutter/CMake combos expect this path to exist during install.
  mkdir -p build/native_assets/linux
}

docker_build_images() {
  (cd "${SCRIPT_DIR}" && ./ensure_flutter_clone.sh)
  docker build -f "${SCRIPT_DIR}/Dockerfile.zenith-wlroots" --target builder \
    --build-arg APP_NAME="${TARGET}" --build-arg PROJECT_DIR="${PROJECT_DIR}" \
    -t "${BUILDER_IMAGE}" "${ROOT_DIR}"
  docker build -f "${SCRIPT_DIR}/Dockerfile.zenith-wlroots" \
    --build-arg APP_NAME="${TARGET}" --build-arg PROJECT_DIR="${PROJECT_DIR}" \
    -t "${RUNTIME_IMAGE}" "${ROOT_DIR}"
}

ensure_builder_image() {
  if ! docker image inspect "${BUILDER_IMAGE}" >/dev/null 2>&1; then
    echo "Docker image ${BUILDER_IMAGE} not found. Run: ./run_build.sh build-image"
    exit 1
  fi
}

run_docker_build() {
  local build_target="$1"

  docker run --rm --user "$(id -u):$(id -g)" --entrypoint bash -v "${ROOT_DIR}:/work" "${BUILDER_IMAGE}" -lc "
    set -e
    cd /work/${PROJECT_DIR}
    export LDFLAGS='-L/usr/local/lib -L/usr/local/lib/x86_64-linux-gnu -Wl,-rpath,/usr/local/lib -Wl,-rpath,/usr/local/lib/x86_64-linux-gnu'
    make ${build_target} FLUTTER=/work/${PROJECT_DIR}/vendor/flutter_clone/bin/flutter WLR_ROOT=/work/${PROJECT_DIR}/vendor/wlroots-install WLR_SRC_ROOT=/work/${PROJECT_DIR}/vendor/wlroots BACKEND_DIR=/work/${PROJECT_DIR}/vendor/jdwm/native
  "
}

bundle_src_dir() {
  local mode="$1"
  echo "build/${TARGET}/${mode}/bundle"
}

bundle_out_dir() {
  local mode="$1"
  echo "${OUTPUT_BASE}/${mode}/bundle"
}

export_bundle() {
  local mode="$1"
  local src_dir=""
  local out_dir=""
  src_dir="$(bundle_src_dir "${mode}")"
  out_dir="$(bundle_out_dir "${mode}")"

  if [[ ! -x "${src_dir}/${TARGET}" ]]; then
    echo "Missing ${mode} binary: ${src_dir}/${TARGET}"
    exit 1
  fi

  local wlroots_lib=""
  if [[ -f "${WLR_ROOT}/lib/x86_64-linux-gnu/libwlroots-0.19.so" ]]; then
    wlroots_lib="${WLR_ROOT}/lib/x86_64-linux-gnu/libwlroots-0.19.so"
  elif [[ -f "${WLR_ROOT}/lib/libwlroots-0.19.so" ]]; then
    wlroots_lib="${WLR_ROOT}/lib/libwlroots-0.19.so"
  else
    echo "Missing libwlroots-0.19.so under ${WLR_ROOT}/lib"
    exit 1
  fi

  rm -rf "${out_dir}"
  mkdir -p "${out_dir}"
  cp -a "${src_dir}/." "${out_dir}/"
  mkdir -p "${out_dir}/lib"
  cp -f "${wlroots_lib}" "${out_dir}/lib/libwlroots-0.19.so"

  cat > "${out_dir}/run_${TARGET}.sh" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
export LD_LIBRARY_PATH="${DIR}/lib:${LD_LIBRARY_PATH:-}"
exec "${DIR}/__APP_NAME__" "$@"
SCRIPT
  sed -i "s/__APP_NAME__/${TARGET}/g" "${out_dir}/run_${TARGET}.sh"
  chmod +x "${out_dir}/run_${TARGET}.sh"

  echo "${mode^} bundle exported to ${out_dir}/"
}

copy_runtime_deps_from_image() {
  local mode="$1"
  local out_dir=""
  out_dir="$(bundle_out_dir "${mode}")"

  mkdir -p "${out_dir}/lib"
  local libs=(libliftoff.so.0 libdisplay-info.so.2 libwayland-server.so.0 libwayland-client.so.0 libpixman-1.so.0 libdrm.so.2 libseat.so.1)
  local copied=0
  local cid=""

  # Preferred source: runtime image bundle.
  if docker image inspect "${RUNTIME_IMAGE}" >/dev/null 2>&1; then
    cid="$(docker create "${RUNTIME_IMAGE}")"
    for lib in "${libs[@]}"; do
      if docker cp "${cid}:/app/${TARGET}/lib/${lib}" "${out_dir}/lib/${lib}" >/dev/null 2>&1; then
        copied=$((copied + 1))
      fi
    done
    docker rm "${cid}" >/dev/null
  else
    echo "Runtime image ${RUNTIME_IMAGE} not found; falling back to builder image for runtime libraries."
  fi

  # Fallback source: builder image /usr/local libs.
  if (( copied < ${#libs[@]} )); then
    if ! docker image inspect "${BUILDER_IMAGE}" >/dev/null 2>&1; then
      return
    fi

    cid="$(docker create "${BUILDER_IMAGE}")"
    for lib in "${libs[@]}"; do
      if [[ -f "${out_dir}/lib/${lib}" ]]; then
        continue
      fi
      docker cp "${cid}:/usr/local/lib/x86_64-linux-gnu/${lib}" "${out_dir}/lib/${lib}" >/dev/null 2>&1 || \
      docker cp "${cid}:/usr/lib/x86_64-linux-gnu/${lib}" "${out_dir}/lib/${lib}" >/dev/null 2>&1 || true
    done
    docker rm "${cid}" >/dev/null
  fi

  local missing=()
  for lib in "${libs[@]}"; do
    if [[ ! -f "${out_dir}/lib/${lib}" ]]; then
      missing+=("${lib}")
    fi
  done
  if (( ${#missing[@]} > 0 )); then
    echo "Warning: some runtime libraries are still missing in ${out_dir}/lib:"
    printf '  - %s\n' "${missing[@]}"
  fi
}

run_exported_bundle() {
  local mode="$1"
  local out_dir=""
  local run_script=""
  out_dir="$(bundle_out_dir "${mode}")"
  run_script="${out_dir}/run_${TARGET}.sh"

  if [[ ! -x "${run_script}" ]]; then
    echo "Missing run script: ${run_script}"
    exit 1
  fi

  echo "Running ${mode} bundle: ${run_script}"
  "${run_script}" "${RUN_ARGS[@]}"
}

parse_args "$@"

case "${MODE}" in
  build-image)
    docker_build_images
    ;;
  release|"")
    ensure_wlroots
    ensure_backend_dir
    ensure_flutter_clone
    ensure_builder_image
    rm -rf build/linux
    "${FLUTTER_BIN}" pub get
    patch_shadcn_flutter_cache
    prepare_flutter_linux_build
    "${FLUTTER_BIN}" build linux --release
    run_docker_build release_bundle_no_flutter
    export_bundle release
    copy_runtime_deps_from_image release
    if (( RUN_AFTER_BUILD )); then
      run_exported_bundle release
    fi
    ;;
  fast)
    ensure_wlroots
    ensure_backend_dir
    ensure_builder_image
    patch_shadcn_flutter_cache
    run_docker_build release_bundle_no_flutter
    export_bundle release
    copy_runtime_deps_from_image release
    if (( RUN_AFTER_BUILD )); then
      run_exported_bundle release
    fi
    ;;
  local)
    ensure_wlroots
    ensure_backend_dir
    ensure_flutter_clone
    setup_linker_paths
    "${FLUTTER_BIN}" pub get
    patch_shadcn_flutter_cache
    prepare_flutter_linux_build
    make release_bundle FLUTTER="${FLUTTER_BIN}" WLR_ROOT="${WLR_ROOT}" WLR_SRC_ROOT="${WLR_SRC_ROOT}" BACKEND_DIR="${BACKEND_DIR}"
    export_bundle release
    if (( RUN_AFTER_BUILD )); then
      run_exported_bundle release
    fi
    ;;
  debug)
    ensure_wlroots
    ensure_backend_dir
    ensure_flutter_clone
    ensure_builder_image
    rm -rf build/linux
    "${FLUTTER_BIN}" pub get
    patch_shadcn_flutter_cache
    prepare_flutter_linux_build
    "${FLUTTER_BIN}" build linux --debug
    run_docker_build debug_bundle_no_flutter
    export_bundle debug
    copy_runtime_deps_from_image debug
    if (( RUN_AFTER_BUILD )); then
      run_exported_bundle debug
    fi
    ;;
  profile)
    ensure_wlroots
    ensure_backend_dir
    ensure_flutter_clone
    ensure_builder_image
    rm -rf build/linux
    "${FLUTTER_BIN}" pub get
    patch_shadcn_flutter_cache
    prepare_flutter_linux_build
    "${FLUTTER_BIN}" build linux --profile
    run_docker_build profile_bundle_no_flutter
    export_bundle profile
    copy_runtime_deps_from_image profile
    if (( RUN_AFTER_BUILD )); then
      run_exported_bundle profile
    fi
    ;;
  help|--help|-h)
    usage
    ;;
  *)
    echo "Unknown mode: ${MODE}"
    usage
    exit 1
    ;;
esac
