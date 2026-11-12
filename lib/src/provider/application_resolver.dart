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

import 'package:freedesktop_desktop_entry/freedesktop_desktop_entry.dart';
import 'package:jdwm/jdwm.dart';

class ResolvedApplication {
  final String groupId;
  final String title;
  final String? desktopId;
  final DesktopEntry? entry;
  final ManagedWindowInfo? window;

  const ResolvedApplication({
    required this.groupId,
    required this.title,
    this.desktopId,
    this.entry,
    this.window,
  });
}

/// One deterministic identity policy shared by the dock, launcher and menus.
class ApplicationResolver {
  final Map<String, DesktopEntry> entries;
  final _ids = <String, Set<String>>{};
  final _foldedIds = <String, Set<String>>{};
  final _classes = <String, Set<String>>{};
  final _foldedClasses = <String, Set<String>>{};

  ApplicationResolver(Map<String, DesktopEntry> entries)
      : entries = Map.unmodifiable(entries) {
    for (final item in entries.entries) {
      _index(_ids, _id(item.key), item.key);
      _index(_foldedIds, _id(item.key).toLowerCase(), item.key);

      final wmClass = item.value.entries[DesktopEntryKey.startupWmClass.string]?.value.trim() ?? '';
      if (wmClass.isNotEmpty) {
        _index(_classes, wmClass, item.key);
        _index(_foldedClasses, wmClass.toLowerCase(), item.key);
      }
    }
  }

  static String _id(String s) =>
      s.endsWith('.desktop') ? s.substring(0, s.length - 8) : s;

  static void _index(Map<String, Set<String>> index, String key, String id) =>
      index.putIfAbsent(key, () => <String>{}).add(id);

  String? _match(List<Set<String>?> levels) {
    for (final candidates in levels) {
      if (candidates == null || candidates.isEmpty) continue;
      // Ambiguity at a stronger level must not become a weaker guess.
      return candidates.length == 1 ? candidates.single : null;
    }
    return null;
  }

  ResolvedApplication forEntry(String query) {
    final id = _match([_ids[_id(query)], _foldedIds[_id(query).toLowerCase()]]);
    return _result(id, fallback: query, groupId: 'entry:$query');
  }

  ResolvedApplication forWindow(ManagedWindowInfo window) {
    final appId = _id(window.appId);
    final cls = window.wmClass;
    final instance = window.wmInstance;

    final id = window.protocol == ManagedWindowProtocol.xwayland
        ? _match([
            _classes[cls],
            _classes[instance],
            _ids[_id(cls)],
            _ids[_id(instance)],
            _foldedClasses[cls.toLowerCase()],
            _foldedClasses[instance.toLowerCase()],
            _foldedIds[_id(cls).toLowerCase()],
            _foldedIds[_id(instance).toLowerCase()],
          ])
        : _match([_ids[appId], _foldedIds[appId.toLowerCase()]]);

    final identity = window.protocol == ManagedWindowProtocol.xwayland
        ? (cls.isNotEmpty ? cls : instance)
        : window.appId;

    return _result(
      id,
      window: window,
      fallback: window.title.isNotEmpty ? window.title : identity,
      groupId: identity.isEmpty
          ? 'window:${window.viewId}'
          : '${window.protocol}:$identity',
    );
  }

  ResolvedApplication _result(
    String? id, {
    required String fallback,
    required String groupId,
    ManagedWindowInfo? window,
  }) {
    final entry = entries[id];
    final name = entry?.entries['Name']?.value;
    return ResolvedApplication(
      desktopId: id,
      entry: entry,
      window: window,
      groupId: id == null ? groupId : 'desktop:$id',
      title: name?.isNotEmpty == true
          ? name!
          : (fallback.isEmpty ? 'Application' : fallback),
    );
  }
}
