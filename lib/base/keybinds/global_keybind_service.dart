//  JappeOS-Desktop, The desktop environment for JappeOS.
//  Copyright (C) 2026  The JappeOS team.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as
//  published by the Free Software Foundation, either version 3 of the
//  License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.

import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

typedef KeybindAction = bool Function();

class GlobalKeybindService {
  final Map<LogicalKeySet, KeybindAction> _bindings = {};

  GlobalKeybindService() {
    ServicesBinding.instance.keyboard.addHandler(_handleKey);
  }

  void register(LogicalKeySet keySet, KeybindAction action) {
    if (_bindings.containsKey(keySet)) {
      throw Exception('Keybind for $keySet is already registered.');
    }

    _bindings[keySet] = action;
  }

  void unregister(LogicalKeySet keySet) {
    _bindings.remove(keySet);
  }

  bool _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final pressed = LogicalKeySet.fromSet(
      HardwareKeyboard.instance.logicalKeysPressed,
    );

    final action = _bindings[pressed];
    return action?.call() ?? false;
  }

  void dispose() {
    ServicesBinding.instance.keyboard.removeHandler(_handleKey);
  }
}
