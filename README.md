<h1 align="center">
  <img src="https://raw.githubusercontent.com/JappeOS/JappeOS/dev/Icons/jappeos-logo-banner-white-512.png" width="120"><br>
  jappeos_desktop
</h1>

<p align="center">
  <strong>The desktop environment for JappeOS.</strong>
</p>

<p align="center">
  <a href="./issues"><img src="https://img.shields.io/github/issues/JappeOS/jappeos_desktop?style=plastic&color=edda09"></a>
  <a href="./pulls"><img src="https://img.shields.io/github/issues-pr/JappeOS/jappeos_desktop?style=plastic&color=40a842"></a>
  <a href="./blob/main/LICENSE"><img src="https://img.shields.io/github/license/JappeOS/jappeos_desktop?style=plastic&color=9d09ed"></a>
  <img src="https://img.shields.io/badge/arch-x86__64-blue?style=plastic">
  <img src="https://img.shields.io/badge/status-experimental-orange?style=plastic">
  <a href="https://discord.gg/dRtU4HR"><img src="https://img.shields.io/discord/716673375946407972?style=plastic&color=3250a8"></a>
</p>

---

## Overview

The desktop environment for JappeOS. Written in Flutter.

![Screenshot](.github/assets/desktop_ui1.png)
_Screenshot might be outdated!_

## Features

* Window manager via `jappeos_desktop_base` and `JDWM`
* Quick settings (Wi-Fi, Bluetooth, Do-not-disturb, etc.)
* Application launcher
* System search
* Virtual desktops
* Notification menu
* Topbar & dock

## Role in the OS

The main UI that the users interact with after login.

## Building

### Prerequisites

- Flutter SDK 3.38.0 or later (with desktop support enabled)
- Dart SDK (included with Flutter)

Verify Flutter desktop setup:

```bash
$ flutter doctor
```

### Setup

Clone the repository and fetch dependencies:
```bash
$ git clone https://github.com/JappeOS/jappeos_desktop.git
$ cd jappeos_desktop
$ flutter pub get
```

### Build

#### Linux

**Read build instructions at the end of this file:** https://github.com/JappeOS/jdwm/blob/main/_integration_kit/DEPENDENCY_README.md

> [!IMPORTANT]
> JDWM is already a dependecy of this project. You might still need to install wlroots and the correct version of Flutter into the `vendor/*` directory.
> After that, you should be ready to build.

#### Other platforms

The JDWM compositor is not supposed to work on other platforms than Linux. Support or usability for other platforms cannot be guaranteed.

#### Troubleshooting

If the build fails after dependency changes or Docker image deletion, simply run `./run_build.sh build-image` as instructed in the `DEPENDENCY_README.md` file linked above.
If the JDWM native code is modified, a clean build is required. Simply update the JDWM GIT submodule to update JDWM, then run a clean build, as instructed in `DEPENDENCY_README.md`.

## Contributing

Contributions of all kinds are welcome and appreciated. You can help the project by:

- ⭐ Starring the repository to show your support
- 💖 Sponsoring the project (if available)
- 🐞 Reporting bugs via [GitHub Issues](./issues)
- 💡 Requesting or discussing new features

For code contributions, please see [`CONTRIBUTING.md`](./CONTRIBUTING.md) for guidelines.

## License

This repository is part of the JappeOS project and is licensed under the terms described in the [`LICENSE`](./LICENSE) file.