//  JappeOS-Desktop, The desktop environment for JappeOS.
//  Copyright (C) 2025  Jappe02
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

part of jappeos_desktop.base;

// TODO: Outgoing animation
class DesktopMenuController {
  static const kMenuAnimationDuration = Duration(milliseconds: 100);

  DesktopMenuController(this.rebuildCallback);

  final Function(void Function()?) rebuildCallback;
  DesktopMenu? _currentMenu;
  Offset? _currentMenuPosition;
  Size _currentMenuChildSize = Size.zero;
  Size _currentStackWSize = Size.zero;
  bool _currentMenuIsInitialBuild = true;

  void openMenu(DesktopMenu menu, {Offset? position, void Function()? closeCallback}) {
    _currentMenu = menu;
    _currentMenuPosition = position;
    _currentMenuIsInitialBuild = true;
    rebuildCallback(null);
    ServicesBinding.instance.keyboard.addHandler(_onKey);
    menu.onOpen.broadcast();

    if (closeCallback != null) {
      menu.onClose.subscribe((_) => closeCallback());
    }
  }

  void closeMenu() {
    if (_currentMenu == null) return; // <-- no menu open, so return

    ServicesBinding.instance.keyboard.removeHandler(_onKey);
    _currentMenu?.onClose.broadcast();
    _currentMenu?.onOpen.unsubscribeAll();
    _currentMenu?.onClose.unsubscribeAll();
    _currentMenu = null;
    _currentMenuPosition = null;
    rebuildCallback(null);
  }

  WidgetTransitionEffects _getAnimation() {
    if (_currentMenu is FullscreenDesktopMenu) {
      return WidgetTransitionEffects(duration: kMenuAnimationDuration, opacity: 0);
    } else if (_currentMenu is CenteredDesktopMenu) {
      return WidgetTransitionEffects.incomingScaleUp(duration: kMenuAnimationDuration * 3, curve: Curves.easeInOutBack);
    }

    return WidgetTransitionEffects(duration: kMenuAnimationDuration, offset: const Offset(0, -75));
  }

  bool _onKey(KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      closeMenu();
      return true;
    }

    return false;
  }

  Widget? getWidget(BuildContext context) {
    final double pad = _currentMenu is FullscreenDesktopMenu ? 0 : 4 * Theme.of(context).scaling;

    LayoutBuilder base() {
      return LayoutBuilder(
        builder: (context, constraints) {
          if (_currentMenuIsInitialBuild) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              //_focusNode!.requestFocus();
              _currentStackWSize = MediaQuery.of(context).size;

              final renderBox = context.findRenderObject() as RenderBox;
              _currentMenuChildSize = renderBox.size;

              final oldMenuPos = _currentMenuPosition;

              _currentMenuPosition = Offset(
                _currentMenuPosition!.dx - _currentMenuChildSize.width / 2,
                _currentMenuPosition!.dy - _currentMenuChildSize.height / 2,
              );

              // Ensure the menu is correctly positioned within the stack
              rebuildCallback(() {
                if (_currentMenu is CenteredDesktopMenu) {
                  _currentMenuPosition = Offset(
                    (_currentStackWSize.width / 2) - (_currentMenuChildSize.width / 2),
                    (_currentStackWSize.height / 2) - (_currentMenuChildSize.height / 2),
                  );
                  return;
                }

                var minX = pad;
                var maxX = _currentStackWSize.width - _currentMenuChildSize.width - pad;

                if (maxX < minX) {
                  maxX = minX;
                }

                var minY = DSKTP_UI_LAYER_TOPBAR_HEIGHT + pad;
                var maxY = _currentStackWSize.height - _currentMenuChildSize.height - pad;

                if (maxY < minY) {
                  maxY = minY;
                }

                _currentMenuPosition = Offset(
                  oldMenuPos!.dx - _currentMenuChildSize.width / 2,
                  oldMenuPos.dy - _currentMenuChildSize.height / 2,
                );

                _currentMenuPosition = Offset(
                  _currentMenuPosition!.dx.clamp(minX, maxX),
                  _currentMenuPosition!.dy.clamp(minY, maxY),
                );
              });
            });
          }

          _currentMenuIsInitialBuild = false;

          return TapRegion(
            onTapOutside: (_) => closeMenu(),
            child: WidgetAnimator(
                  incomingEffect: _getAnimation(),
                  child: RepaintBoundary(
                    child: () {
                      if (_currentMenu is FullscreenDesktopMenu) {
                        return DualBorderOutlinedContainer(
                          width: _currentStackWSize.width,
                          height: (_currentStackWSize.height - DSKTP_UI_LAYER_TOPBAR_HEIGHT).clamp(0, double.infinity),
                          //backgroundBlur: true,
                          padding: EdgeInsets.all(4 * Theme.of(context).scaling),
                          child: _currentMenu as Widget,
                        );
                      }

                      return _currentMenu as Widget;
                    }(),
                  ),
                ),


          );
        },
      );
    }

    return _currentMenu != null
        ? Positioned(
            left: _currentMenuPosition!.dx,
            top: _currentMenuPosition!.dy,
            child: base(),
          )
        : null;
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