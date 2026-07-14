# jappeos_desktop Arch Packaging

This PKGBUILD packages the JappeOS desktop shell into a Pacman package. The
desktop package is separate from the `jdwm` compositor package; greeter packages
should follow the same pattern and depend on `jdwm` instead of being named
`jdwm`.

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

The native path still uses `vendor/wlroots` as the wlroots source/header tree
for private wlroots headers while linking against Arch's `wlroots0.19` package.
