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

// ignore_for_file: library_private_types_in_public_api

import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../components/desktop_container.dart';
import '../desktop_menu_controller.dart';
import '../desktop_menu_entry.dart';

class SwitcherMenuEntry extends DesktopMenuEntry {
  @override
  String get id => 'switcher';

  @override
  DesktopMenuEntryType get type => DesktopMenuEntryType.none;

  @override
  String get label => 'Switcher';

  @override
  LogicalKeySet? get shortcut => null;

  @override
  List<Widget> buildIcon(BuildContext context) {
    return const [Icon(Icons.menu_open)];
  }

  @override
  DesktopMenu createMenu() {
    return SwitcherMenu();
  }
}

class SwitcherMenu extends CenteredDesktopMenu {
  SwitcherMenu({super.key});

  @override
  _SwitcherMenuState createState() => _SwitcherMenuState();
}

class _SwitcherMenuState extends State<SwitcherMenu> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DesktopOverlayContainer(
      width: 200,
      height: 200,
      padding: EdgeInsets.all(16 * theme.scaling),
      child: Placeholder(),
    );
  }
}
