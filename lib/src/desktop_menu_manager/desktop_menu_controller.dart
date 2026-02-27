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

import 'package:event/event.dart';
import 'package:flutter/services.dart';
import 'package:jdwm/jdwm.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

// TODO: Outgoing animation
class DesktopMenuController extends ChangeNotifier {
  static const kMenuAnimationDuration = Duration(milliseconds: 100);

  DesktopMenu? _currentMenu;
  Offset? _anchorPosition;

  DesktopMenu? get currentMenu => _currentMenu;
  Offset? get anchorPosition => _anchorPosition;

  void openMenu(
    DesktopMenu menu, {
    Offset? position,
    void Function()? closeCallback,
  }) {
    _currentMenu = menu;
    _anchorPosition = position;

    ServicesBinding.instance.keyboard.addHandler(_onKey);

    menu.onOpen.broadcast();

    if (closeCallback != null) {
      menu.onClose.subscribe((_) => closeCallback());
    }

    notifyListeners();
  }

  void closeMenu() {
    if (_currentMenu == null) return;

    ServicesBinding.instance.keyboard.removeHandler(_onKey);

    _currentMenu?.onClose.broadcast();
    _currentMenu?.onOpen.unsubscribeAll();
    _currentMenu?.onClose.unsubscribeAll();

    _currentMenu = null;
    _anchorPosition = null;

    notifyListeners();
  }

  bool _onKey(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      closeMenu();
      return true;
    }
    return false;
  }
}

abstract class DesktopMenu extends StatefulWidget {
  final onOpen = Event();
  final onClose = Event();

  DesktopMenu({super.key});
}

abstract class FullscreenDesktopMenu extends DesktopMenu {
  FullscreenDesktopMenu({super.key});
}

abstract class CenteredDesktopMenu extends DesktopMenu {
  CenteredDesktopMenu({super.key});
}

class DesktopMenuWidget extends StatefulWidget {
  final DesktopMenuController controller;
  final MonitorConfig monitor;

  const DesktopMenuWidget({
    super.key,
    required this.controller,
    required this.monitor,
  });

  @override
  State<DesktopMenuWidget> createState() => _DesktopMenuWidgetState();
}

class _DesktopMenuWidgetState extends State<DesktopMenuWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  Offset? _position;
  Size _menuSize = Size.zero;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: DesktopMenuController.kMenuAnimationDuration,
    );

    _fade = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _scale = Tween(begin: 0.9, end: 1.0).animate(_fade);

    _slide = Tween(
      begin: const Offset(0, -0.05),
      end: Offset.zero,
    ).animate(_fade);

    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _animationController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (widget.controller.currentMenu != null) {
      _animationController.forward(from: 0);
    } else {
      _animationController.reverse();
    }
    setState(() {
      _position = null;
      _menuSize = Size.zero;
    });
  }

  void _computePosition(DesktopMenu menu) {
    final bounds = widget.monitor.bounds;
    final anchor = widget.controller.anchorPosition;

    const double pad = 8;

    if (menu is FullscreenDesktopMenu) {
      _position = Offset.zero;
      return;
    }

    if (menu is CenteredDesktopMenu) {
      _position = Offset(
        (bounds.width - _menuSize.width) / 2,
        (bounds.height - _menuSize.height) / 2,
      );
      return;
    }

    // Regular anchored menu
    if (anchor == null) return;

    double left = anchor.dx - _menuSize.width / 2;
    double top = anchor.dy - _menuSize.height / 2;

    final minX = pad;
    final maxX = bounds.width - _menuSize.width - pad;

    final minY = pad;
    final maxY = bounds.height - _menuSize.height - pad;

    left = left.clamp(minX, maxX);
    top = top.clamp(minY, maxY);

    _position = Offset(left, top);
  }

  @override
  Widget build(BuildContext context) {
    final menu = widget.controller.currentMenu;
    if (menu == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _animationController,
      child: KeyedSubtree(
        key: ValueKey(menu), // preserves state
        child: RepaintBoundary(child: menu),
      ),
      builder: (context, child) {
        return Stack(
          children: [
            /// Positioned menu
            Builder(
              builder: (context) {
                return Positioned(
                  left: _position?.dx ?? 0,
                  top: _position?.dy ?? 0,
                  child: TapRegion(
                    onTapOutside: (_) => widget.controller.closeMenu(),
                    behavior: HitTestBehavior.translucent,
                    child: SlideTransition(
                      position: _slide,
                      child: ScaleTransition(
                        scale: _scale,
                        child: FadeTransition(
                          opacity: _fade,
                          child: Builder(
                            builder: (context) {
                              final capturedMenu = menu;
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) return;
                                final box = context.findRenderObject() as RenderBox?;
                                if (box == null) return;
                                final newSize = box.size;
                                if (newSize != _menuSize) {
                                  _menuSize = newSize;
                                  _computePosition(capturedMenu);
                                  setState(() {});
                                }
                              });

                              if (menu is FullscreenDesktopMenu) {
                                final bounds = widget.monitor.bounds;
                                return SizedBox(
                                  width: bounds.width,
                                  height: bounds.height,
                                  child: child!,
                                );
                              }

                              return child!;
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
