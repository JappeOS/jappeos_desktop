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

import 'desktop_menu_entry.dart';

class DesktopMenuRegistry {
  final Map<String, DesktopMenuEntry> _entries = {};
  final List<DesktopMenuEntry> _orderedEntries = [];

  void register(DesktopMenuEntry entry) {
    _entries[entry.id] = entry;
    _orderedEntries.add(entry);
  }

  Iterable<DesktopMenuEntry> get entries => _orderedEntries;

  DesktopMenuEntry? getById(String id) => _entries[id];
}
