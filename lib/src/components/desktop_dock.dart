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

// ignore_for_file: library_private_types_in_public_api

import 'dart:async';

import 'package:jappeos_desktop/src/provider/desktop_entry_provider.dart';
import 'package:jdwm/jdwm.dart';
import 'package:jappeos_desktop/src/desktop_menu_manager/menus/launcher_menu.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../desktop_menu_manager/desktop_menu_controller.dart';
import '../desktop_menu_manager/desktop_menu_registry.dart';
import 'desktop_application_item.dart';
import 'desktop_container.dart';

/// The dock that shows pinned and open apps.
class DesktopDock extends StatefulWidget {
  final DesktopMenuRegistry registry;
  final DesktopMenuController menuController;
  final bool autoHide;

  const DesktopDock({
    super.key,
    required this.registry,
    required this.menuController,
    this.autoHide = true,
  });

  @override
  _DesktopDockState createState() => _DesktopDockState();
}

class _DesktopDockState extends State<DesktopDock> {
  static const _kAnimDuration = Duration(milliseconds: 150);
  static const _kUnhideDebounce = Duration(milliseconds: 120);
  final GlobalKey _dockShownKey = GlobalKey();
  bool _showDock = true;
  bool _hoveringDock = false;
  bool _focusedWindowIntersectsDock = false;
  bool _dockRectRefreshScheduled = false;
  bool _intersectionRecomputeScheduled = false;
  WindowManagerState? _observedWm;
  WindowEntry? _focusedWindow;
  Rect? _dockRect;
  List<DockEntry> _entries = const <DockEntry>[];
  String _entrySignature = '';
  Timer? _unhideDebounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bindWindowManager());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bindWindowManager();
  }

  @override
  void didUpdateWidget(covariant DesktopDock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.autoHide != widget.autoHide) {
      _refreshDockVisibility();
    }
  }

  @override
  void dispose() {
    _unhideDebounceTimer?.cancel();
    _observedWm?.removeWindowStateListener(_onWindowManagerStateChanged);
    _setFocusedWindow(null);
    super.dispose();
  }

  void _bindWindowManager() {
    if (!mounted) {
      return;
    }
    final wm = WindowManager.of(context);
    if (wm == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _bindWindowManager());
      return;
    }
    if (identical(_observedWm, wm)) {
      return;
    }
    _observedWm?.removeWindowStateListener(_onWindowManagerStateChanged);
    _observedWm = wm;
    _observedWm?.addWindowStateListener(_onWindowManagerStateChanged);
    _onWindowManagerStateChanged();
  }

  void _onWindowManagerStateChanged() {
    final wm = _observedWm;
    if (!mounted || wm == null) {
      return;
    }
    final windows = wm.getManagedWindowsByFocus();
    final grouped = <String, List<ManagedWindowInfo>>{};
    for (final window in windows) {
      final normalizedAppId = window.appId.trim().toLowerCase();
      final key =
          normalizedAppId.isEmpty ? "__view_${window.viewId}" : normalizedAppId;
      grouped.putIfAbsent(key, () => <ManagedWindowInfo>[]).add(window);
    }

    final entries = <DockEntry>[];
    final signatureParts = <String>[];
    for (final group in grouped.values) {
      if (group.isEmpty) {
        continue;
      }
      final focused = group.any((window) => window.focused);
      final representative =
          focused ? group.firstWhere((window) => window.focused) : group.first;
      final itemId = representative.appId.trim().isNotEmpty
          ? representative.appId
          : representative.title;
      if (itemId.trim().isEmpty) {
        continue;
      }
      final state = focused
          ? DesktopApplicationItemState.focused
          : DesktopApplicationItemState.open;
      entries.add(
        DockEntry.application(
          item: itemId,
          state: state,
          onPressed: () {
            int? currentFocusedViewId;
            for (final window in group) {
              if (window.focused) {
                currentFocusedViewId = window.viewId;
                break;
              }
            }
            final target = group.firstWhere(
              (window) => window.viewId != currentFocusedViewId,
              orElse: () => group.first,
            );
            _focusBackendWindow(target.viewId);
          },
          onQuit: () {
            // TODO: Implement quitting the app, e.g., by sending a close request to all windows in the group.
          },
        ),
      );
      signatureParts.add(
        "${itemId.toLowerCase()}|${state.name}|${group.length}|${representative.viewId}",
      );
    }

    WindowEntry? focusedWindow;
    int? lastViewId;
    if (windows.isNotEmpty) {
      lastViewId = windows.last.viewId;
    }
    for (final info in windows) {
      if (!info.focused) {
        continue;
      }
      for (final window in wm.getAllWindows()) {
        if (window.backendViewId == info.viewId) {
          focusedWindow = window;
          break;
        }
      }
      break;
    }
    if (focusedWindow == null && lastViewId != null) {
      for (final window in wm.getAllWindows()) {
        if (window.backendViewId == lastViewId) {
          focusedWindow = window;
          break;
        }
      }
    }
    _setFocusedWindow(focusedWindow);

    final nextSignature = signatureParts.join(";");
    if (nextSignature != _entrySignature) {
      setState(() {
        _entries = entries;
        _entrySignature = nextSignature;
      });
      if (_showDock) {
        _scheduleDockRectRefresh();
      }
    }
    _recomputeFocusedWindowIntersection();
    _scheduleIntersectionRecompute();
  }

  void _setFocusedWindow(WindowEntry? window) {
    if (identical(_focusedWindow, window)) {
      return;
    }
    _focusedWindow?.removeListener(_onFocusedWindowUpdated);
    _focusedWindow = window;
    _focusedWindow?.addListener(_onFocusedWindowUpdated);
    _recomputeFocusedWindowIntersection();
  }

  void _onFocusedWindowUpdated() {
    _recomputeFocusedWindowIntersection();
    _scheduleIntersectionRecompute();
  }

  void _scheduleIntersectionRecompute() {
    if (_intersectionRecomputeScheduled || !mounted) {
      return;
    }
    _intersectionRecomputeScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _intersectionRecomputeScheduled = false;
      if (!mounted) {
        return;
      }
      if (_showDock) {
        _dockRect = _readRenderBounds(_dockShownKey) ?? _dockRect;
      }
      _recomputeFocusedWindowIntersection();
    });
  }

  void _scheduleDockRectRefresh() {
    if (_dockRectRefreshScheduled || !mounted) {
      return;
    }
    _dockRectRefreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dockRectRefreshScheduled = false;
      if (!mounted) {
        return;
      }
      _dockRect = _readRenderBounds(_dockShownKey) ?? _dockRect;
      _recomputeFocusedWindowIntersection();
    });
  }

  Rect? _readRenderBounds(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) {
      return null;
    }
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return null;
    }
    final origin = renderObject.localToGlobal(Offset.zero);
    return origin & renderObject.size;
  }

  Rect? _resolveDockRect() {
    if (_showDock) {
      final liveDockRect = _readRenderBounds(_dockShownKey);
      if (liveDockRect != null) {
        _dockRect = liveDockRect;
        return liveDockRect;
      }
    }
    return _dockRect;
  }

  Rect _resolveFocusedWindowRect(
      WindowManagerState wm, WindowEntry focusedWindow) {
    final backendDecorated = focusedWindow.backendViewId != null &&
        focusedWindow.chromeMode == WindowChromeMode.decorated &&
        focusedWindow.usesToolbar;

    final liveFocusedRect = _readRenderBounds(focusedWindow.repaintBoundaryKey);
    if (liveFocusedRect != null) {
      if (backendDecorated && focusedWindow.backendContentInsetTop > 0) {
        return Rect.fromLTWH(
          liveFocusedRect.left,
          liveFocusedRect.top - focusedWindow.backendContentInsetTop,
          liveFocusedRect.width,
          liveFocusedRect.height + focusedWindow.backendContentInsetTop,
        );
      }
      return liveFocusedRect;
    }

    var fallbackRect = wm.targetRectForWindow(focusedWindow);
    if (backendDecorated && focusedWindow.backendContentInsetTop > 0) {
      fallbackRect = Rect.fromLTWH(
        fallbackRect.left,
        fallbackRect.top,
        fallbackRect.width,
        fallbackRect.height + focusedWindow.backendContentInsetTop,
      );
    }
    return fallbackRect;
  }

  void _recomputeFocusedWindowIntersection() {
    final wm = _observedWm;
    final focusedWindow = _focusedWindow;
    final dockRect = _resolveDockRect();
    bool intersects = false;
    if (wm != null && focusedWindow != null && dockRect != null) {
      final focusedRect = _resolveFocusedWindowRect(wm, focusedWindow);
      intersects = focusedRect.overlaps(dockRect);
    }
    if (intersects) {
      _unhideDebounceTimer?.cancel();
      if (!_focusedWindowIntersectsDock) {
        _focusedWindowIntersectsDock = true;
      }
      _refreshDockVisibility();
      return;
    }
    if (!_focusedWindowIntersectsDock) {
      _refreshDockVisibility();
      return;
    }
    _unhideDebounceTimer?.cancel();
    _unhideDebounceTimer = Timer(_kUnhideDebounce, () {
      if (!mounted) {
        return;
      }
      _focusedWindowIntersectsDock = false;
      _refreshDockVisibility();
    });
  }

  void _refreshDockVisibility() {
    if (!mounted) {
      return;
    }
    final shouldShow =
        !widget.autoHide || !_focusedWindowIntersectsDock || _hoveringDock;
    if (shouldShow == _showDock) {
      return;
    }
    setState(() {
      _showDock = shouldShow;
    });
    if (shouldShow) {
      _scheduleDockRectRefresh();
    }
  }

  void _focusBackendWindow(int viewId) {
    final wm = _observedWm;
    if (wm == null) {
      return;
    }
    WindowEntry? target;
    for (final window in wm.getAllWindows()) {
      if (window.backendViewId == viewId) {
        target = window;
        break;
      }
    }
    if (target != null) {
      wm.requestFocus(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pad = 8 * theme.scaling;
    final itemRad = BorderRadius.circular((theme.radiusLg * 2) - pad);
    final List<Widget> dockWidgets = [
      DesktopApplicationItem.custom(
        key: const ValueKey('dock-launcher'),
        sizeFactor: 0.75,
        borderRadius: itemRad,
        child: FittedBox(
          fit: BoxFit.contain,
          child: Icon(Icons.apps),
        ),
        onPressed: () => widget.menuController.openMenu(
          widget.registry.entries
              .firstWhere((e) => e is LauncherMenuEntry)
              .createMenu(),
        ),
      ),
      ..._entries.map((entry) {
        /*if (entry.custom != null) {
          return DesktopApplicationItem.custom(
            key: ValueKey<String>(
              "dock-custom-${entry.item ?? entry.hashCode}",
            ),
            sizeFactor: 0.75,
            borderRadius: itemRad,
            itemState: entry.state,
            onPressed: entry.onPressed,
            child: entry.custom!,
          );
        }*/
        if (entry.item != null) {
          return DesktopApplicationContextMenu(
            key: ValueKey<String>("dock-app-${entry.item!}"),
            entry: entry.item!,
            onOpenDetails: () {
              // TODO
            },
            onQuit: () {
              // TODO
            },
            child: DesktopApplicationItem.icon(
              sizeFactor: 0.75,
              borderRadius: itemRad,
              entry: entry.item!,
              itemState: entry.state,
              onPressed: entry.onPressed,
            ),
          );
        }
        return const SizedBox.shrink();
      }),
    ];
    return Align(
      alignment: Alignment.bottomCenter,
      widthFactor: 1.0,
      child: MouseRegion(
        onEnter: (event) {
          _hoveringDock = true;
          _refreshDockVisibility();
        },
        onExit: (event) {
          _hoveringDock = false;
          _refreshDockVisibility();
        },
        child: Padding(
          padding: _showDock
              ? EdgeInsets.only(bottom: 4 * Theme.of(context).scaling)
              : EdgeInsets.zero,
          child: Row(
            children: [
              const Spacer(),
              AnimatedSwitcher(
                duration: _kAnimDuration,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final slide = Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(animation);
                  return ClipRect(
                    clipBehavior: Clip.none,
                    child: FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: slide, child: child),
                    ),
                  );
                },
                child: _showDock
                    ? DesktopOverlayContainer(
                        key: _dockShownKey,
                        increasedBorderRadius: true,
                        padding: EdgeInsets.all(pad),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: pad,
                          children: dockWidgets,
                        ),
                      )
                    : SizedBox(
                        key: const ValueKey('dockHidden'),
                        height: 2 * Theme.of(context).scaling,
                      ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class DockEntry {
  final String? item;
  //final Widget? custom;
  final DesktopApplicationItemState state;
  //final bool launcher;
  final void Function()? onPressed;
  final void Function()? onQuit;

  DockEntry._({
    this.item,
    //this.custom,
    this.state = DesktopApplicationItemState.none,
    //this.launcher = false,
    this.onPressed,
    this.onQuit,
  });

  factory DockEntry.application({
    required String item,
    DesktopApplicationItemState state = DesktopApplicationItemState.none,
    void Function()? onPressed,
    void Function()? onQuit,
  }) {
    return DockEntry._(
      item: item,
      state: state,
      onPressed: onPressed,
      onQuit: onQuit,
    );
  }

  /*factory DockEntry.custom({
    required Widget custom,
    DesktopApplicationItemState state = DesktopApplicationItemState.none,
    bool launcher = false,
    void Function()? onPressed,
  }) {
    return DockEntry._(
      custom: custom,
      state: state,
      launcher: launcher,
      onPressed: onPressed,
    );
  }*/
}
