import 'package:flutter/services.dart';
import 'package:jappeos_desktop_base/jappeos_desktop_base.dart';
import 'package:jappeos_services/jappeos_services.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'desktop_menu_manager/desktop_menu_controller.dart';
import 'desktop_menu_manager/desktop_menu_registry.dart';
import 'desktop_menu_manager/menus/switcher_menu.dart';

class DesktopKeybinds extends StatefulWidget {
  final DesktopMenuRegistry registry;
  final DesktopMenuController menuController;
  final Widget child;

  const DesktopKeybinds({super.key, required this.child, required this.registry, required this.menuController});

  @override
  State<DesktopKeybinds> createState() => _DesktopKeybindsState();
}

class _DesktopKeybindsState extends State<DesktopKeybinds> {
  final _sliderSteps = [
    0.0,
    0.01, 0.02, 0.03, 0.05, 0.07,
    0.1, 0.15, 0.25, 0.3,
    0.4, 0.5, 0.6,
    0.7, 0.8, 0.9,
    1.0,
  ];

  final _kKeyAudioMute = LogicalKeySet(LogicalKeyboardKey.audioVolumeMute);
  final _kKeyAudioVolumeDown = LogicalKeySet(LogicalKeyboardKey.audioVolumeDown);
  final _kKeyAudioVolumeUp = LogicalKeySet(LogicalKeyboardKey.audioVolumeUp);
  final _kKeyAudioMicrophoneToggle = LogicalKeySet(LogicalKeyboardKey.microphoneToggle);
  final _kKeyAudioMicrophoneMute = LogicalKeySet(LogicalKeyboardKey.microphoneVolumeMute);
  final _kKeyDmenuSwitcherOpen = LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.tab);

  bool _altPressed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      init();
    });
  }

  void init() {
    ServicesBinding.instance.keyboard.addHandler(_handleAltKey);

    final keybinds = GlobalKeybindScope.of(context);
    keybinds.register(_kKeyAudioMute, _audioHandleMute);
    keybinds.register(_kKeyAudioVolumeDown, _audioHandleVolumeDown);
    keybinds.register(_kKeyAudioVolumeUp, _audioHandleVolumeUp);
    keybinds.register(_kKeyAudioMicrophoneToggle, _audioHandleMicrophoneToggle);
    keybinds.register(_kKeyAudioMicrophoneMute, _audioHandleMicrophoneToggle);
    keybinds.register(_kKeyDmenuSwitcherOpen, _dmenuSwitcherHandleOpen);
  }

  @override
  void dispose() {
    ServicesBinding.instance.keyboard.removeHandler(_handleAltKey);

    final keybinds = GlobalKeybindScope.of(context);
    keybinds.unregister(_kKeyAudioMute, _audioHandleMute);
    keybinds.unregister(_kKeyAudioVolumeDown, _audioHandleVolumeDown);
    keybinds.unregister(_kKeyAudioVolumeUp, _audioHandleVolumeUp);
    keybinds.unregister(_kKeyAudioMicrophoneToggle, _audioHandleMicrophoneToggle);
    keybinds.unregister(_kKeyAudioMicrophoneMute, _audioHandleMicrophoneToggle);
    keybinds.unregister(_kKeyDmenuSwitcherOpen, _dmenuSwitcherHandleOpen);
    super.dispose();
  }

  int _findClosestIndex(double value) {
    int closest = 0;
    double minDiff = double.infinity;

    for (int i = 0; i < _sliderSteps.length; i++) {
      final diff = (_sliderSteps[i] - value).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = i;
      }
    }
    return closest;
  }

  double _stepValue(double currentValue, int direction) {
    int index = _findClosestIndex(currentValue);

    index += direction;
    index = index.clamp(0, _sliderSteps.length - 1);

    return _sliderSteps[index];
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  bool _handleAltKey(KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.alt ||
        event.logicalKey == LogicalKeyboardKey.altLeft ||
        event.logicalKey == LogicalKeyboardKey.altRight) {
      if (event is KeyDownEvent) {
        _altPressed = true;
      }
      if (event is KeyUpEvent) {
        _altPressed = false;
        return _dmenuSwitcherHandleClose();
      }
    }
    return false;
  }

  bool _audioHandleMute() {
    final audio = context.read<AudioService>();
    final device = audio.activeOutputDevice;
    if (device == null) return true;
    audio.setDeviceMuted(device, !device.muted);
    return true;
  }

  bool _audioHandleVolumeDown() {
    final audio = context.read<AudioService>();
    final device = audio.activeOutputDevice;
    if (device == null) return true;
    audio.setDeviceVolume(device, _stepValue(device.volume, -1));
    return true;
  }

  bool _audioHandleVolumeUp() {
    final audio = context.read<AudioService>();
    final device = audio.activeOutputDevice;
    if (device == null) return true;
    audio.setDeviceVolume(device, _stepValue(device.volume, 1));
    return true;
  }

  bool _audioHandleMicrophoneToggle() {
    final audio = context.read<AudioService>();
    final device = audio.activeInputDevice;
    if (device == null) return true;
    audio.setDeviceMuted(device, !device.muted);
    return true;
  }

  bool _dmenuSwitcherHandleOpen() {
    // TODO
    print("TODO: Open dmenu switcher");
    widget.menuController.openMenu(
          widget.registry.entries
              .firstWhere((e) => e is SwitcherMenuEntry)
              .createMenu()
    );
    return true;
  }

  bool _dmenuSwitcherHandleClose() {
    // TODO
    print("TODO: Close dmenu switcher");
    widget.menuController.closeMenu();
    return true;
  }
}