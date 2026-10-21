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

import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:freedesktop_desktop_entry/freedesktop_desktop_entry.dart';
// ignore: implementation_imports
import 'package:freedesktop_desktop_entry/src/utils.dart';
import 'package:path/path.dart' as p;

import '../lifecycle_handler.dart';
import 'gpu_info_provider.dart';

class DesktopEntryProvider extends ChangeNotifier {
  late Future<FreedesktopIconTheme> _themeLoadingFuture;
  late InstalledDesktopFilesWatcher _watcher;
  Map<String, DesktopEntry> _entries = {};

  Map<String, DesktopEntry> get entries => _entries;

  DesktopEntryProvider() {
    _themeLoadingFuture = _loadThemes();
    _watcher = InstalledDesktopFilesWatcher(
      onChanged: (entries) {
        _entries = entries;
        notifyListeners();
      },
      onError: (error, stackTrace) {
        stderr.writeln('Error watching desktop files: $error\n$stackTrace');
      },
    )..start().onError((error, stackTrace) {
      stderr.writeln('Error starting desktop files watcher: $error\n$stackTrace');
    });
  }

  @override
  void dispose() {
    safeAsyncDispose(_watcher.stopListening);
    super.dispose();
  }

  Future<File?> getIcon(DesktopEntry entry) async {
    String? icon = entry.entries[DesktopEntryKey.icon.string]?.value;
    if (icon == null) return null;
    return (await _themeLoadingFuture).findIcon(
      IconQuery(
        name: icon,
        size: 64,
        extensions: ['png', 'svg'],
        //preferredThemes: ['Papirus', 'Papirus-Dark', 'Papirus-Light'],
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
    GpuInfoProvider gpuInfoProvider, {
    String action = "",
    Map<String, String> environment = const {}}
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
    return _launchApplication(
      command: exec,
      terminal: terminal,
      environment: {
        ...environment,
        ...gpuInfoProvider.getGraphicsEnvironmentVariables(
          gpuInfoProvider.getUsesDiscreteGpu(desktopEntry),
        ),
      },
    );
  }

  Future<bool> _launchApplication({
    required String command,
    bool terminal = false,
    Map<String, String> environment = const {},
  }) async {
    // FIXME
    command = command.replaceAll(RegExp(r'( %.?)'), '');
    debugPrint("Launching $command");

    try {
      if (terminal) {
        await Process.start(
          'kgx',
          ['-e', command],
          environment: environment
        );
      } else {
        await Process.start(
          '/bin/sh',
          ['-c', command],
          environment: environment
        );
      }
      return true;
    } on ProcessException catch (e) {
      stderr.writeln(e.toString());
      return false;
    }
  }

  Future<FreedesktopIconTheme> _loadThemes() async {
    final themeList = await FreedesktopIconTheme.installedThemes;
    const preferredThemes = ['Papirus-Dark', 'Papirus-Light', 'Papirus'];

    final selectedTheme = preferredThemes.firstWhereOrNull(themeList.contains) ??
        themeList.firstOrNull;

    return await FreedesktopIconTheme.loadTheme(theme: selectedTheme ?? "");
  }
}

typedef DesktopEntriesChanged = void Function(
  Map<String, DesktopEntry> entries,
);

typedef DesktopFilesWatcherErrorCallback = void Function(
  Object error,
  StackTrace stackTrace,
);

/// Watches installed desktop entries, including application directories created
/// after startup. Paths and loading can be supplied for isolated filesystem tests.
class InstalledDesktopFilesWatcher {
  InstalledDesktopFilesWatcher({
    this.onChanged,
    this.onError,
    this.applicationDirectories,
    this.loadEntries = parseAllInstalledDesktopFiles,
    this.debounceDuration = const Duration(milliseconds: 100),
  });

  final DesktopEntriesChanged? onChanged;
  final DesktopFilesWatcherErrorCallback? onError;
  final Duration debounceDuration;
  final Iterable<String>? applicationDirectories;
  final Future<Map<String, DesktopEntry>> Function() loadEntries;

  late final Set<String> _applicationPaths =
      (applicationDirectories ?? getApplicationDirectories())
          .map((path) => p.normalize(p.absolute(path)))
          .toSet();

  final Map<String, StreamSubscription<FileSystemEvent>> _subscriptions = {};

  Timer? _refreshTimer;

  Future<void>? _startFuture;
  Future<void>? _stopFuture;
  Future<void>? _refreshFuture;

  bool _stopRequested = false;
  bool _refreshRequested = false;

  Map<String, DesktopEntry> desktopEntries = {};

  // MARK: - Public lifecycle

  Future<void> start() {
    if (_stopRequested) {
      return Future<void>.error(
        StateError('Cannot start a watcher after stopping it.'),
      );
    }

    // Repeated start() calls share the same startup operation.
    return _startFuture ??= _startImpl();
  }

  Future<void> stopListening() {
    // Repeated stopListening() calls share the same shutdown operation.
    return _stopFuture ??= _stopImpl();
  }

  // MARK: - Startup

  Future<void> _startImpl() async {
    try {
      await _syncSubscriptions();

      // Stop may have been requested while startup was in progress.
      if (_stopRequested) return;

      // Load initial state and notify listeners.
      await _refreshEntries();
    } catch (_) {
      // A failed startup must not leave subscriptions running.
      _stopRequested = true;

      _refreshTimer?.cancel();
      _refreshTimer = null;

      await _cancelSubscriptions();

      rethrow;
    }
  }

  // Watch the nearest existing parent as well as the application directory.
  // This discovers directories created after login and survives replacement.
  Future<void> _syncSubscriptions() async {
    final desiredPaths = <String>{};
    for (final path in _applicationPaths) {
      var parent = p.dirname(path);
      while (!Directory(parent).existsSync()) {
        final next = p.dirname(parent);
        if (next == parent) break;
        parent = next;
      }
      desiredPaths.add(parent);
      if (Directory(path).existsSync()) desiredPaths.add(path);
    }

    for (final path in desiredPaths) {
      if (_stopRequested) return;
      if (_subscriptions.containsKey(path)) continue;
      try {
        _subscriptions[path] = Directory(path).watch().listen(
          (event) => _handleFileSystemEvent(path, event),
          onError: (Object error, StackTrace stackTrace) {
            if (!_stopRequested) _reportError(error, stackTrace);
          },
          onDone: () {
            _subscriptions.remove(path);
            _scheduleRefresh();
          },
        );
      } catch (error, stackTrace) {
        _reportError(error, stackTrace);
      }
    }

    for (final path in _subscriptions.keys.toList()) {
      if (!desiredPaths.contains(path)) {
        await _subscriptions.remove(path)!.cancel();
      }
    }
  }

  // MARK: - Filesystem events

  void _handleFileSystemEvent(
    String dirPath,
    FileSystemEvent event,
  ) {
    if (_stopRequested) return;

    // A move can involve a .desktop file at either its source or
    // destination, so consider both paths where available.
    final paths = <String>[event.path];

    if (event is FileSystemMoveEvent && event.destination != null) {
      paths.add(event.destination!);
    }

    final relevant = paths.any(
      (path) {
        final absolutePath = p.isAbsolute(path)
            ? p.normalize(path)
            : p.normalize(p.join(dirPath, path));
        return _applicationPaths.any((applicationPath) =>
            absolutePath == applicationPath ||
            p.isWithin(absolutePath, applicationPath) ||
            _isDirectDesktopFile(applicationPath, absolutePath));
      },
    );

    if (relevant) {
      _scheduleRefresh();
    }
  }

  bool _isDirectDesktopFile(String dirPath, String eventPath) {
    final normalizedPath = p.isAbsolute(eventPath)
        ? p.normalize(eventPath)
        : p.normalize(p.join(dirPath, eventPath));

    return p.dirname(normalizedPath) == dirPath &&
        normalizedPath.endsWith('.desktop');
  }

  void _scheduleRefresh() {
    if (_stopRequested) return;

    _refreshTimer?.cancel();
    _refreshTimer = Timer(debounceDuration, () {
      _refreshTimer = null;
      if (!_stopRequested) {
        // The operation is not abandoned: _refreshEntries tracks it,
        // and stopListening() waits for it to finish.
        unawaited(_refreshEntries());
      }
    });
  }

  // MARK: - Refreshing

  Future<void> _refreshEntries() {
    if (_stopRequested) {
      return Future<void>.value();
    }

    _refreshRequested = true;

    final currentRefresh = _refreshFuture;

    if (currentRefresh != null) {
      // A refresh is already running. Request another pass after it
      // finishes instead of running overlapping parses.
      return currentRefresh;
    }

    final completer = Completer<void>();

    _refreshFuture = completer.future;

    unawaited(_drainRefreshes(completer));

    return completer.future;
  }

  Future<void> _drainRefreshes(Completer<void> completer) async {
    try {
      while (_refreshRequested && !_stopRequested) {
        _refreshRequested = false;

        try {
          await _syncSubscriptions();
          if (_stopRequested) break;
          final parsedEntries = await loadEntries();

          // Parsing cannot necessarily be cancelled, but its result
          // must not be published after shutdown has begun.
          if (_stopRequested) break;

          desktopEntries = parsedEntries;

          onChanged?.call(
            Map<String, DesktopEntry>.unmodifiable(desktopEntries),
          );
        } catch (error, stackTrace) {
          if (!_stopRequested) {
            _reportError(error, stackTrace);
          }
        }
      }
    } finally {
      if (identical(_refreshFuture, completer.future)) {
        _refreshFuture = null;
      }

      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  }

  // MARK: - Shutdown

  Future<void> _stopImpl() async {
    // From this point onward, event handlers and refreshes cannot initiate
    // further useful work.
    _stopRequested = true;

    _refreshTimer?.cancel();
    _refreshTimer = null;

    // Startup might still be awaiting the initial parse. Wait for it.
    final startFuture = _startFuture;
    if (startFuture != null) {
      try {
        await startFuture;
      } catch (_) {
        // Startup errors are reported by start() to its caller.
        // Shutdown must still complete its cleanup.
      }
    }

    await _cancelSubscriptions();

    // No new refresh can start after _stopRequested was set. Wait for
    // any refresh already running to finish.
    await _refreshFuture;
  }

  Future<void> _cancelSubscriptions() async {
    final subscriptions =
        List<StreamSubscription<FileSystemEvent>>.of(_subscriptions.values);

    _subscriptions.clear();

    await Future.wait(
      subscriptions.map((subscription) async {
        try {
          await subscription.cancel();
        } catch (error, stackTrace) {
          _reportError(error, stackTrace);
        }
      }),
    );
  }

  void _reportError(Object error, StackTrace stackTrace) {
    final handler = onError;

    if (handler == null) {
      Zone.current.handleUncaughtError(error, stackTrace);
      return;
    }

    try {
      handler(error, stackTrace);
    } catch (handlerError, handlerStackTrace) {
      Zone.current.handleUncaughtError(
        handlerError,
        handlerStackTrace,
      );
    }
  }
}
