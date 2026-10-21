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

import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../lifecycle_handler.dart';

class GpuInfoProvider extends ChangeNotifier {
  static final _cardNamePattern = RegExp(r'^card\d+$');
  static final _drmDirectory = Directory('/sys/class/drm/');

  late final StreamSubscription<FileSystemEvent> _drmDirectoryStream;
  Timer? _debounceTimer;
  bool _isHandlerRunning = false;
  Completer<void>? _currentExecutionCompleter;

  int _graphicsCardCount = 0;
  bool _hasDiscreteGpu = false;

  int get graphicsCardCount => _graphicsCardCount;
  bool get hasDiscreteGpu => _hasDiscreteGpu;

  GpuInfoProvider() {
    _drmDirectoryStream = _drmDirectory.watch(events: FileSystemEvent.all).listen(
      (event) => _onEventReceived(event),
      onError: (error, stackTrace) => stderr.writeln('Error watching drm directory: $error\n$stackTrace'),
    );
    _handleGpuStateChange();
  }

  @override
  void dispose() {
    safeAsyncDispose(() async {
      await _drmDirectoryStream.cancel();

      _debounceTimer?.cancel();
      _debounceTimer = null;

      if (_isHandlerRunning && _currentExecutionCompleter != null) {
        await _currentExecutionCompleter!.future;
      }
    });
    super.dispose();
  }

  Map<String, String> getGraphicsEnvironmentVariables(bool useDiscreteGpu) {
    final envVars = <String, String>{};

    if (useDiscreteGpu && hasDiscreteGpu) {
      envVars.addAll({
        'DRI_PRIME': '1',
        '__NV_PRIME_RENDER_OFFLOAD': '1',
        '__GLX_VENDOR_LIBRARY_NAME': 'nvidia',
        '__VK_LAYER_NV_optimus': 'NVIDIA_only',
      });
    }

    return envVars;
  }

  void _onEventReceived(FileSystemEvent event) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      const Duration(milliseconds: 500),
      () => _handleGpuStateChange(),
    );
  }

  Future<void> _handleGpuStateChange() async {
    if (_isHandlerRunning) return;

    _isHandlerRunning = true;
    _currentExecutionCompleter = Completer<void>();

    try {
      _graphicsCardCount = await _checkGraphicsCardsCount();
      _hasDiscreteGpu = await _checkHasDiscreteGpu();
      notifyListeners();
    } finally {
      _isHandlerRunning = false;
      _currentExecutionCompleter?.complete();
      _currentExecutionCompleter = null;
    }
  }

  static Future<int> _checkGraphicsCardsCount() async {
    return (await _drmCards()).length;
  }

  static Future<bool> _checkHasDiscreteGpu() async {
    final cards = await _drmCards();

    if (cards.length <= 1) {
      return false;
    }

    for (final card in cards) {
      final vendorFile = File('${card.path}/device/vendor');

      try {
        final vendor =
            (await vendorFile.readAsString())
            .trim()
            .toLowerCase();

        if (vendor == '0x10de') {
          return true;
        }
      } on FileSystemException {
        continue;
      }
    }

    return false;
  }

  static String _entryName(FileSystemEntity entity) {
    return entity.path
        .split(Platform.pathSeparator)
        .where((part) => part.isNotEmpty)
        .last;
  }

  static Future<List<Directory>> _drmCards() async {
    if (!await _drmDirectory.exists()) {
      return [];
    }

    return _drmDirectory
        .list(followLinks: true)
        .where((entity) => entity is Directory)
        .where((entity) => _cardNamePattern.hasMatch(_entryName(entity)))
        .toList() as List<Directory>;
  }
}