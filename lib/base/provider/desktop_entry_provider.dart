//  JappeOS-Desktop, The desktop environment for JappeOS.
//  Copyright (C) 2025  Jappe02
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

import 'package:flutter/material.dart';
import 'package:freedesktop_desktop_entry/freedesktop_desktop_entry.dart';

// TODO: Parse desktop entries properly and only when logged in.
class DesktopEntryProvider extends ChangeNotifier {
  List<DesktopEntry> entries = [];

  DesktopEntryProvider() {
    _loadEntries();
    _watchDirectories();
  }

  void _loadEntries() {
    throw UnimplementedError();
    // Scan all known freedesktop paths
    //entries = parseAllDesktopEntries(); TODO
    notifyListeners();
  }

  void _watchDirectories() {
    throw UnimplementedError();
/*
    for (final dir in freedesktopDirs) {
      final watcher = DirectoryWatcher(dir);
      watcher.events.listen((event) {
        _loadEntries(); // Naive way: reload all
        // For optimization, parse only affected file
      });
    }*/
  }
}