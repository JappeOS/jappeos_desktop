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

import 'dart:io';

import 'package:flutter_svg/svg.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:freedesktop_desktop_entry/freedesktop_desktop_entry.dart';

class DesktopEntryProvider extends ChangeNotifier {
  final _themes = FreedesktopIconThemes();
  Map<String, DesktopEntry> _entries = {};
  bool _isDirty = true;

  DesktopEntryProvider() {
    _themes.loadThemes();
  }

  Future<Map<String, DesktopEntry>> getEntries() async {
    if (_isDirty) {
      try {
        await _reloadEntries();
      } catch (e) {
        // TODO: Handle errors, e.g., log them
      }
      _isDirty = false;
    }
    return _entries;
  }

  Future<File?> getIcon(DesktopEntry entry) async {
    String? icon = entry.entries[DesktopEntryKey.icon.string]?.value;
    if (icon == null) return null;
    return _themes.findIcon(
      IconQuery(
        name: icon,
        size: 64,
        extensions: ['png', 'svg'],
        preferredThemes: ['Papirus', 'Papirus-Dark', 'Papirus-Light'],
      ),
    );
  }

  Future<Widget> getIconWidget(DesktopEntry entry, {double size = 24}) async {
    final iconFile = await getIcon(entry);
    if (iconFile == null) {
      return const Icon(Icons.question_mark);
    }
    if (iconFile.path.endsWith('.svg')) {
      return SvgPicture.file(
        iconFile,
        width: size,
        height: size,
        errorBuilder: (context, error, stackTrace)
            => const Icon(Icons.settings_applications),
      );
    }
    return Image.file(
      iconFile,
      width: size,
      height: size,
      errorBuilder: (context, error, stackTrace)
          => const Icon(Icons.settings_applications),
    );
  }

  Future<bool> launchDesktopEntry(
    DesktopEntry desktopEntry,
    [String action = ""]
  ) async {
    final baseEntries = desktopEntry.entries;
    final actionEntries = desktopEntry.actions[action];

    String? exec;
    bool? terminal;

    if (action.isNotEmpty) {
      if (actionEntries == null) {
        return false;
      }

      final String? aexec = actionEntries[DesktopEntryKey.exec.string]?.value;
      if (aexec != null) {
        exec = aexec;
      }

      final bool? aterminal = actionEntries[DesktopEntryKey.terminal.string]?.value.getBoolean();
      if (aterminal != null) {
        terminal = aterminal;
      }
    }

    exec ??= baseEntries[DesktopEntryKey.exec.string]?.value;
    if (exec == null) {
      return false;
    }
    terminal ??= baseEntries[DesktopEntryKey.terminal.string]?.value.getBoolean() ?? false;
    return _launchApplication(command: exec, terminal: terminal);
  }

  Future<bool> _launchApplication({
    required String command,
    bool terminal = false,
  }) async {
    // FIXME
    command = command.replaceAll(RegExp(r'( %.?)'), '');
    debugPrint("Launching $command");

    try {
      if (terminal) {
        await Process.start('kgx', ['-e', command]);
      } else {
        await Process.start('/bin/sh', ['-c', command]);
      }
      return true;
    } on ProcessException catch (e) {
      stderr.writeln(e.toString());
      return false;
    }
  }

  Future<void> _reloadEntries() async {
    final entries = await parseAllInstalledDesktopFiles();
    _entries = entries;
    notifyListeners();
  }
}