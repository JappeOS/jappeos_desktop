# jappeos_desktop Arch Packaging

This PKGBUILD packages the JappeOS desktop shell into a Pacman package. It
builds against the JDWM source in `vendor/jdwm`; JDWM is not resolved as a
Pacman package for this desktop build.

Build from the repository root:

```sh
makepkg -p packaging/arch/PKGBUILD
```

Or from this directory:

```sh
makepkg
```

The package build calls the native Arch build path:

```sh
./run_build.sh arch-native release
```

This path builds against Arch system libraries under `/usr` and does not use the
Docker builder/runtime images. Ubuntu development builds still use the existing
commands such as `./run_build.sh release`, `./run_build.sh fast`, and
`./run_build.sh --run`.

The PKGBUILD uses `git+` sources for:

- this repository
- `vendor/jdwm`
- `vendor/wlroots`

`prepare()` copies those source clones into the expected `vendor/` paths before
the build starts. This is required because GitHub tag tarballs do not include
submodule contents, and the native build still needs a wlroots source tree for
private headers.

Do not commit `vendor/flutter_clone`. For native package builds, provide Flutter
through `PATH`, `FLUTTER_BIN`, or `/opt/flutter/bin/flutter`. The ignored
`vendor/flutter_clone` tree remains for the existing Docker build path, where the
Dockerfile copies that local SDK into the image.

The package installs the desktop bundle under `/usr/lib/jappeos_desktop` and
provides `/usr/bin/jappeos_desktop`.

Arch-specific runtime cleanup is handled in `package()` as a guard against stale
Docker bundle contents:

- remove bundled `libdrm.so.2`
- remove bundled `libwayland-client.so.0`
- remove bundled `libwayland-server.so.0`
- remove bundled `libwlroots-0.19.so`
- remove other bundled graphics/XCB/session libraries provided by Arch
- remove bundled `bin/Xwayland`
- add `libunwind.so.1 -> /usr/lib/libunwind.so.8`

The native path uses `vendor/wlroots` as the wlroots source/header tree for
private wlroots headers while linking against Arch's `wlroots0.19` package.
