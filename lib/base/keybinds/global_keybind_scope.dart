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

import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'global_keybind_service.dart';

class GlobalKeybindScope extends InheritedWidget {
  final GlobalKeybindService keybinds;

  const GlobalKeybindScope({
    required this.keybinds,
    required super.child,
    super.key,
  });

  static GlobalKeybindService of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<GlobalKeybindScope>();
    assert(scope != null, 'No GlobalKeybindScope found in context');
    return scope!.keybinds;
  }

  @override
  bool updateShouldNotify(GlobalKeybindScope oldWidget) => false;
}