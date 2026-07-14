# Maintainer: JappeOS

pkgname=jappeos_desktop
pkgver=1.0.2
_tag=dev-v1.0.2
pkgrel=1
pkgdesc='JappeOS desktop shell built with Flutter and JDWM'
arch=('x86_64')
url="https://github.com/JappeOS/$pkgname"
license=('GPL-3.0-or-later')
depends=(
  'fontconfig'
  'jdwm'
  'libc++'
  'libc++abi'
  'libdisplay-info'
  'libdrm'
  'libepoxy'
  'libglvnd'
  'libinput'
  'libliftoff'
  'libunwind'
  'libxkbcommon'
  'lcms2'
  'mesa'
  'pam'
  'pixman'
  'seatd'
  'systemd-libs'
  'wayland'
  'wlroots0.19'
  'xcb-util-renderutil'
  'xcb-util-wm'
  'xorg-xwayland'
)
makedepends=(
  'clang'
  'curl'
  'flutter'
  'git'
  'libc++'
  'libc++abi'
  'make'
  'pkgconf'
  'unzip'
  'wlroots0.19'
)
provides=('jappeos-desktop')
conflicts=('jappeos-desktop')
options=('!strip')
source=("$pkgname-$pkgver.tar.gz::$url/archive/refs/tags/$_tag.tar.gz")
sha256sums=('SKIP')

_appname='jappeos_desktop'
_pkgroot='usr/lib/jappeos_desktop'
_srcroot="${pkgname}-${_tag}"

_repo_root() {
  if [[ -f "${srcdir}/${_srcroot}/run_build.sh" ]]; then
    printf '%s\n' "${srcdir}/${_srcroot}"
  elif [[ -f "${startdir}/run_build.sh" ]]; then
    printf '%s\n' "${startdir}"
  elif [[ -f "${startdir}/../../run_build.sh" ]]; then
    cd "${startdir}/../.." && pwd
  else
    echo "Could not locate repository root from ${startdir}" >&2
    return 1
  fi
}

build() {
  cd "$(_repo_root)"
  if [[ -z "${FLUTTER_BIN:-}" && -x /opt/flutter/bin/flutter ]]; then
    export FLUTTER_BIN=/opt/flutter/bin/flutter
  fi
  ./run_build.sh arch-native release
}

package() {
  cd "$(_repo_root)"

  local bundle="build/jappeos/${CARCH}/release/bundle"
  if [[ ! -x "${bundle}/${_appname}" ]]; then
    echo "Missing release bundle. Expected ${bundle}/${_appname}"
    return 1
  fi

  install -d "${pkgdir}/${_pkgroot}"
  cp -a "${bundle}/." "${pkgdir}/${_pkgroot}/"

  # Native Arch packages must use system graphics/session libraries.
  rm -f \
    "${pkgdir}/${_pkgroot}/lib/libX11-xcb.so.1" \
    "${pkgdir}/${_pkgroot}/lib/libdisplay-info.so.2" \
    "${pkgdir}/${_pkgroot}/lib/libdrm.so.2" \
    "${pkgdir}/${_pkgroot}/lib/libliftoff.so.0" \
    "${pkgdir}/${_pkgroot}/lib/libpixman-1.so.0" \
    "${pkgdir}/${_pkgroot}/lib/libseat.so.1" \
    "${pkgdir}/${_pkgroot}/lib/libwayland-client.so.0" \
    "${pkgdir}/${_pkgroot}/lib/libwayland-server.so.0" \
    "${pkgdir}/${_pkgroot}/lib/libwlroots-0.19.so" \
    "${pkgdir}/${_pkgroot}/lib/libxcb-composite.so.0" \
    "${pkgdir}/${_pkgroot}/lib/libxcb-ewmh.so.2" \
    "${pkgdir}/${_pkgroot}/lib/libxcb-icccm.so.4" \
    "${pkgdir}/${_pkgroot}/lib/libxcb-render-util.so.0" \
    "${pkgdir}/${_pkgroot}/lib/libxcb-render.so.0" \
    "${pkgdir}/${_pkgroot}/lib/libxcb-res.so.0" \
    "${pkgdir}/${_pkgroot}/lib/libxcb-xfixes.so.0" \
    "${pkgdir}/${_pkgroot}/lib/libxcb.so.1"
  rm -f "${pkgdir}/${_pkgroot}/bin/Xwayland"

  # Sony's engine/runtime expects libunwind.so.1, while Arch ships libunwind.so.8.
  if [[ ! -e "${pkgdir}/${_pkgroot}/lib/libunwind.so.1" ]]; then
    ln -s /usr/lib/libunwind.so.8 "${pkgdir}/${_pkgroot}/lib/libunwind.so.1"
  fi

  install -Dm755 "packaging/arch/jappeos_desktop" "${pkgdir}/usr/bin/${_appname}"
  install -Dm644 LICENSE "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
}
