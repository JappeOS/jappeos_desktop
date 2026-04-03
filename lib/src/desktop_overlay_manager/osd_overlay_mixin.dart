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
import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'osd_panel.dart';

/// Mix this into a [State] to get automatic show/hide/timer behaviour.
///
/// The concrete state only needs to implement [buildOsdData] and [listenables].
///
/// Example:
/// ```dart
/// class _AudioOverlayState extends State<AudioOverlay>
///     with OsdOverlayMixin<AudioOverlay> { ... }
/// ```
mixin OsdOverlayMixin<T extends StatefulWidget> on State<T> {
  /// How long the overlay stays visible after the last change.
  Duration get visibleDuration => const Duration(seconds: 2);

  /// Return the current [OsdData] to display, or `null` to suppress the overlay.
  OsdData? buildOsdData();

  /// Listenables this overlay should subscribe to.
  ///
  /// Whenever any of them notifies, [onProviderChanged] is called.
  List<Listenable> get listenables;

  /// Override to suppress the OSD when an unrelated field changed.
  ///
  /// [previous] is the last [OsdData] snapshot; [current] is the new one.
  /// Return false to ignore this notification.
  /// Default: show whenever [current] differs from [previous].
  bool shouldShow(OsdData? previous, OsdData? current) => previous != current;

  // Internals

  bool _visible = false;
  Timer? _hideTimer;
  late final Listenable _merged;
  OsdData? _lastData;

  bool get isVisible => _visible;

  @override
  void initState() {
    super.initState();
    _lastData = buildOsdData();
    _merged = Listenable.merge(listenables);
    _merged.addListener(_onProviderChanged);
  }

  @override
  void dispose() {
    _merged.removeListener(_onProviderChanged);
    _hideTimer?.cancel();
    super.dispose();
  }

  void _onProviderChanged() {
    final next = buildOsdData();
    if (!shouldShow(_lastData, next)) {
      _lastData = next;
      return;
    }
    _lastData = next;
    _hideTimer?.cancel();
    _hideTimer = Timer(visibleDuration, _hide);
    setState(() => _visible = true);
  }

  void _hide() {
    if (mounted) setState(() => _visible = false);
  }

  /// Call inside [build] to get the correctly animated overlay child.
  ///
  /// Returns a widget that fades + slides in/out based on [isVisible].
  Widget buildOverlay() {
    final data = buildOsdData();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 160),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: (_visible && data != null)
          ? OsdPanel(key: const ValueKey('osd-visible'), data: data)
          : const SizedBox.shrink(),
    );
  }
}