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

part of jappeos_desktop.base;

enum DesktopMenuEntryType {
  launcher,
  tray,
}

abstract class DesktopMenuEntry extends ChangeNotifier {
  String get id;

  DesktopMenuEntryType get type;

  /// Icon for the top bar button (can change dynamically)
  List<Widget> buildIcon(BuildContext context);

  /// Tooltip / accessibility label
  String get label;

  LogicalKeySet? get shortcut;

  /// Called when top-bar button is pressed
  DesktopMenu createMenu();

  bool _isOpen = false;
  bool get isOpen => _isOpen;

  void toggle(DesktopMenuController controller, Offset position) {
    if (_isOpen) {
      controller.closeMenu();
      if (!_isOpen) return; // <-- callback already triggered
      _isOpen = false;
      notifyListeners();
    }

    controller.openMenu(
      createMenu(),
      position: position,
      closeCallback: () {
        _isOpen = false;
        notifyListeners();
      },
    );

    _isOpen = true;
    notifyListeners();
  }
}