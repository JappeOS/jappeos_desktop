import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:jdwm/jdwm.dart';

import '../desktop_menu_manager/desktop_menu_controller.dart';

/// Keeps panel state alive while excluding hidden panels from painting, input,
/// semantics and keyboard focus. In particular, the dock's reveal area cannot
/// intercept the fullscreen client's pointer events.
class DesktopPanelVisibility extends StatefulWidget {
  const DesktopPanelVisibility({
    super.key,
    required this.menuController,
    required this.child,
  });

  final DesktopMenuController menuController;
  final Widget child;

  @override
  State<DesktopPanelVisibility> createState() => _DesktopPanelVisibilityState();
}

class _DesktopPanelVisibilityState extends State<DesktopPanelVisibility> {
  WindowManagerState? _manager;
  bool _hidden = false;
  bool _refreshScheduled = false;

  @override
  void initState() {
    super.initState();
    widget.menuController.addListener(_refresh);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final manager = WindowManager.of(context);
    if (!identical(manager, _manager)) {
      _manager?.removeWindowStateListener(_refresh);
      _manager = manager;
      _manager?.addWindowStateListener(_refresh);
    }
    _hidden = _shouldHide;
  }

  @override
  void didUpdateWidget(covariant DesktopPanelVisibility oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.menuController != widget.menuController) {
      oldWidget.menuController.removeListener(_refresh);
      widget.menuController.addListener(_refresh);
    }
    _hidden = _shouldHide;
  }

  bool get _shouldHide =>
      widget.menuController.currentMenu == null &&
      (_manager?.getManagedWindowsByFocus().any(
                (window) =>
                    window.focused && window.visible && window.fullscreen,
              ) ??
          false);

  void _refresh() {
    if (!mounted || _hidden == _shouldHide) return;
    // Inventory notifications can arrive during the manager's layout/build.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_refreshScheduled) return;
      _refreshScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshScheduled = false;
        _refresh();
      });
      return;
    }
    setState(() => _hidden = _shouldHide);
  }

  @override
  void dispose() {
    _manager?.removeWindowStateListener(_refresh);
    widget.menuController.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeFocus(
        excluding: _hidden,
        child: TickerMode(
          enabled: !_hidden,
          child: Offstage(offstage: _hidden, child: widget.child),
        ),
      );
}
