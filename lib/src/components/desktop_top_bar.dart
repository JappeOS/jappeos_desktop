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

import 'package:jappeos_desktop_base/jappeos_desktop_base.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../constants.dart';
import '../desktop_menu_manager/desktop_menu_controller.dart';
import '../desktop_menu_manager/desktop_menu_entry.dart';
import '../desktop_menu_manager/desktop_menu_registry.dart';
import 'desktop_container.dart';

/// The bar that shows system information and provides access to important parts
/// of the OS, like notifications and quick settings.
class DesktopTopBarNew extends StatelessWidget {
  final DesktopMenuRegistry registry;
  final DesktopMenuController menuController;

  const DesktopTopBarNew({
    super.key,
    required this.registry,
    required this.menuController,
  });

  Widget _button(BuildContext context, DesktopMenuEntry entry) {
    return ListenableBuilder(
      listenable: entry,
      builder: (_, __) {
        return DTopbarButtonNew(
          //tooltip: entry.label, TODO
          isSelected: entry.isOpen,
          shortcut: entry.shortcut,
          onPressed: (offset) => entry.toggle(menuController, offset),
          children: entry.buildIcon(context),
        );
      },
    );
  }

  List<Widget> _createLeftSide(BuildContext context) {
    return registry.entries
        .where((e) => e.type == DesktopMenuEntryType.launcher)
        .map((entry) => _button(context, entry)).toList();
  }

  List<Widget> _createRightSide(BuildContext context) {
    return registry.entries
        .where((e) => e.type == DesktopMenuEntryType.tray)
        .map((entry) => _button(context, entry)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: DSKTP_UI_LAYER_TOPBAR_HEIGHT,
      child: DesktopBlurContainer(
        child: Row(
          children: [
            ..._createLeftSide(context),
            const Spacer(),
            ..._createRightSide(context),
          ],
        ),
      ),
    );
  }
}

/// A topbar button that captures the global position of the button and is used
/// to open a desktop menu.
class DTopbarButtonNew extends StatefulWidget {
  final String? title;
  final bool isSelected;
  final List<Widget> children;
  final AlignmentGeometry alignment;
  final LogicalKeySet? shortcut;
  final void Function(Offset)? onPressed;

  const DTopbarButtonNew({
    super.key,
    this.title,
    this.isSelected = false,
    this.children = const [],
    this.alignment = Alignment.center,
    this.shortcut,
    this.onPressed
  });

  @override
  _DTopbarButtonNewState createState() => _DTopbarButtonNewState();
}

class _DTopbarButtonNewState extends State<DTopbarButtonNew> {
  static const double _kIconSize = 17;
  static const double _kHeight = 26;

  bool _init = false;
  Offset _globalPosition = Offset.zero;

  bool _hovering = false;
  final _borderRad = BorderRadius.circular(100);
  final _borderWidth = 1.0;

  @override
  void didChangeDependencies() {
    if (_init) return;
    _init = true;

    if (widget.shortcut != null) {
      final keybinds = GlobalKeybindScope.of(context);
      keybinds.register(
        widget.shortcut!,
        () {
          setState(() {});
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onPressed?.call(_globalPosition);
          });
          return true;
        },
      );
    }

    super.didChangeDependencies();
  }

  @override
  void dispose() {
    if (widget.shortcut != null) {
      final keybinds = GlobalKeybindScope.of(context);
      keybinds.unregister(widget.shortcut!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.border;

    return Container(
      margin: const EdgeInsets.only(left: 5, right: 5),
      alignment: widget.alignment,
      height: _kHeight,
      decoration: BoxDecoration(
        borderRadius: _borderRad,
        color: _hovering || widget.isSelected
            ? theme.colorScheme.secondary.scaleAlpha(theme.surfaceOpacity ?? 0)
            : Colors.transparent,
        border: _hovering || widget.isSelected
            ? Border.all(width: _borderWidth, color: borderColor)
            : Border.all(width: _borderWidth, color: Colors.transparent),
      ),
      child: RepaintBoundary(
        child: Builder(
          builder: (context) {
            // Use a post frame callback to ensure the widget has been laid out
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final renderBox = context.findRenderObject() as RenderBox;
              final global = renderBox.localToGlobal(Offset.zero);
              _globalPosition = Offset(
                global.dx + renderBox.size.width / 2,
                global.dy,
              );
            });

            return MouseRegion(
              onEnter: (value) => setState(() {
                _hovering = true;
              }),
              onExit: (value) => setState(() {
                _hovering = false;
              }),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  widget.onPressed?.call(_globalPosition);
                },
                child: SizedBox(
                  height: _kHeight,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 6 * theme.scaling,
                      right: 6 * theme.scaling,
                    ),
                    child: IconTheme(
                      data: IconTheme.of(context).copyWith(size: _kIconSize),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 6 * theme.scaling,
                        children: widget.children,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}