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
import 'dart:ui';

import 'package:shadcn_flutter/shadcn_flutter.dart';

bool _hasLifecycleObserver = false;
List<Future<void>> _exitCallbacks = [];

/// Use this function when you need to perform asynchronous cleanup tasks
/// before the application exits, inside of a synchronous dispose function.
void safeAsyncDispose(Future<void> Function() disposeFunction) {
  if (_hasLifecycleObserver) {
    Future<void>? call;
    call = disposeFunction().whenComplete(() {
      _exitCallbacks.remove(call);
    });
    _exitCallbacks.add(call);
  } else {
    throw StateError(
      'No ApplicationLifecycleObserver found. Please wrap your app with ApplicationLifecycleObserver to use safeAsyncDispose.',
    );
  }
}

class ApplicationLifecycleObserver extends StatefulWidget {
  final Widget child;

  const ApplicationLifecycleObserver({super.key, required this.child});

  @override
  State<ApplicationLifecycleObserver> createState() => _ApplicationLifecycleObserverState();
}

class _ApplicationLifecycleObserverState extends State<ApplicationLifecycleObserver> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onExitRequested: () => _handleExit(),
    );
    _hasLifecycleObserver = true;
  }

  @override
  void dispose() {
    _hasLifecycleObserver = false;
    _listener.dispose();
    super.dispose();
  }

  Future<AppExitResponse> _handleExit() async {
    for (final callback in _exitCallbacks) {
      try {
        await callback;
      } catch (e) {
        stderr.writeln('Error during exit callback: $e');
      }
    }
    _exitCallbacks.clear();
    return AppExitResponse.exit;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}