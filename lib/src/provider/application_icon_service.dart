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
import 'dart:typed_data';

import 'package:freedesktop_desktop_entry/freedesktop_desktop_entry.dart';
import 'package:jdwm/jdwm.dart';

import 'application_resolver.dart';

class ApplicationIconSource {
  final Uint8List? bytes;
  final bool svg;
  final ClientIconImage? pixels;

  const ApplicationIconSource.encoded(this.bytes, {required this.svg})
      : pixels = null;
  const ApplicationIconSource.pixels(this.pixels)
      : bytes = null,
        svg = false;
}

typedef IconLookup = Future<File?> Function(IconQuery query);

/// A cached request whose completed value is available during the first build.
class ApplicationIconRequest {
  late final Future<List<ApplicationIconSource>> future;
  List<ApplicationIconSource>? _value;

  ApplicationIconRequest._(Future<List<ApplicationIconSource>> load) {
    future = load.then((value) {
      _value = value;
      return value;
    });
  }

  List<ApplicationIconSource>? get value => _value;
}

/// Service that manages desktop application icons.
/// Caches source data, not widgets or GPU images. Theme policy is supplied by the DE.
class ApplicationIconService {
  final IconLookup lookup;
  final _cache = <Object, ApplicationIconRequest>{};
  final _viewKeys = <int, Set<Object>>{};
  final _viewRevisions = <int, int>{};
  final _costs = <Object, int>{};
  int _bytes = 0;
  int _generation = 0;
  int get generation => _generation;

  ApplicationIconService(this.lookup);

  void invalidate() {
    _generation++;
    _cache.clear();
    _viewKeys.clear();
    _viewRevisions.clear();
    _costs.clear();
    _bytes = 0;
  }

  void _remove(Object key) {
    _cache.remove(key);
    _bytes -= _costs.remove(key) ?? 0;
    for (final id in _viewKeys.keys.toList()) {
      final keys = _viewKeys[id]!;
      keys.remove(key);
      if (keys.isEmpty) {
        _viewKeys.remove(id);
        _viewRevisions.remove(id);
      }
    }
  }

  void retainWindows(Set<int> ids) {
    for (final id in _viewKeys.keys.toList()) {
      if (!ids.contains(id)) {
        for (final key in _viewKeys[id]!.toList()) {
          _remove(key);
        }
      }
    }
  }

  static List<ClientIconImage> orderedImages(
    List<ClientIconImage> images,
    double logicalSize,
    double dpr,
  ) {
    final target = (logicalSize * dpr).ceil();
    final result = List<ClientIconImage>.of(images);

    int edge(ClientIconImage image) =>
        image.width < image.height ? image.width : image.height;

    result.sort((a, b) {
      final ae = edge(a), be = edge(b);

      if ((ae >= target) != (be >= target)) {
        return ae >= target ? -1 : 1;
      }

      final size = ae >= target ? ae.compareTo(be) : be.compareTo(ae);
      return size != 0
          ? size
          : (a.scale - dpr).abs().compareTo((b.scale - dpr).abs());
    });
    return result;
  }

  Future<List<ApplicationIconSource>> sources(
    ResolvedApplication app, {
    required double size,
    required double dpr,
  }) =>
      request(app, size: size, dpr: dpr).future;

  ApplicationIconRequest request(
    ResolvedApplication app, {
    required double size,
    required double dpr,
  }) {
    final metadata = app.window?.metadata;
    final key = (
      app.desktopId,
      app.entry?.entries[DesktopEntryKey.icon.string]?.value,
      app.window?.viewId,
      metadata?.revision,
      size,
      dpr,
      _generation,
    );

    final cached = _cache.remove(key);
    if (cached != null) {
      _cache[key] = cached;
      return cached;
    }

    final id = app.window?.viewId;
    if (id != null) {
      if (_viewRevisions[id] != (metadata?.revision ?? 0)) {
        for (final previousKey in _viewKeys[id]?.toList() ?? <Object>[]) {
          _remove(previousKey);
        }
      }
      _viewRevisions[id] = metadata?.revision ?? 0;
      _viewKeys.putIfAbsent(id, () => <Object>{}).add(key);
    }

    final request = ApplicationIconRequest._(_load(app, size, dpr));
    _cache[key] = request;

    while (_cache.length > 128) {
      _remove(_cache.keys.first);
    }

    request.future.then((sources) {
      if (!identical(_cache[key], request)) return;

      final cost = sources.fold<int>(
        0,
        (total, source) =>
            total + (source.bytes?.length ?? source.pixels?.rgba.length ?? 0),
      );

      _costs[key] = cost;
      _bytes += cost;
      while (_bytes > 32 * 1024 * 1024 && _cache.isNotEmpty) {
        _remove(_cache.keys.first);
      }
    });

    return request;
  }

  Future<List<ApplicationIconSource>> _load(
    ResolvedApplication app,
    double size,
    double dpr,
  ) async {
    final sources = <ApplicationIconSource>[];
    final paths = <String>{};

    Future<void> addNamed(String? name, {bool client = false}) async {
      if (name == null || name.isEmpty) return;

      // The client protocol names an icon, never a file on the compositor host.
      if (client &&
          (name.contains('/') ||
              name.contains('\\') ||
              name == '.' ||
              name == '..')) {
        return;
      }

      try {
        final file = await lookup(
          IconQuery(
            name: name,
            size: size.ceil(),
            scale: dpr.ceil().clamp(1, 8),
            extensions: const ['png', 'svg'],
          ),
        );

        if (file == null || !paths.add(file.path)) return;
        if (await file.length() > 8 * 1024 * 1024) return;

        sources.add(
          ApplicationIconSource.encoded(
            await file.readAsBytes(),
            svg: file.path.toLowerCase().endsWith('.svg'),
          ),
        );
      } on FileSystemException {
        // A removed file falls through to the next source.
      } catch (_) {
        // A missing/broken theme must not prevent client or generic fallback.
      }
    }

    await addNamed(app.window?.metadata.iconName, client: true);

    for (final image in orderedImages(
      app.window?.metadata.images ?? const [],
      size,
      dpr,
    )) {
      sources.add(ApplicationIconSource.pixels(image));
    }

    await addNamed(app.entry?.entries[DesktopEntryKey.icon.string]?.value);
    return List.unmodifiable(sources);
  }
}
