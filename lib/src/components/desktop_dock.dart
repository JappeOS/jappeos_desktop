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

import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:widget_and_text_animator/widget_and_text_animator.dart';

import 'desktop_application_item.dart';
import 'desktop_container.dart';

/// The dock that shows pinned and open apps.
class DesktopDock extends StatefulWidget {
  final bool hasWindowIntersection;
  final List<String> items;

  const DesktopDock({
    super.key,
    required this.hasWindowIntersection,
    required this.items,
  });

  @override
  _DesktopDockState createState() => _DesktopDockState();
}

class _DesktopDockState extends State<DesktopDock> {
  static const _kAnimDuration = Duration(milliseconds: 150);
  bool _showDock = true;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      widthFactor: 1.0,
      child: MouseRegion(
        onEnter: (event) {
          if (!_showDock) setState(() => _showDock = true);
        },
        onExit: (event) {
          if (_showDock && widget.hasWindowIntersection) setState(() => _showDock = false);
        },
        child: Padding(
          padding: _showDock ? EdgeInsets.only(bottom: 4 * Theme.of(context).scaling) : EdgeInsets.zero,
          child: Row(
            children: [
              const Spacer(),
              WidgetAnimator(
                incomingEffect: WidgetTransitionEffects.incomingSlideInFromBottom(duration: _kAnimDuration),
                outgoingEffect: WidgetTransitionEffects.outgoingSlideOutToBottom(duration: _kAnimDuration),
                child: _showDock ? DesktopOverlayContainer(
                  key: const ValueKey('dockShown'),
                  increasedBorderRadius: true,
                  padding: EdgeInsets.all(4 * Theme.of(context).scaling),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      widget.items.length,
                      (index) => DesktopApplicationItem.icon( entry: widget.items[index]),
                    ),
                  ),
                ) : SizedBox(key: const ValueKey('dockHidden'), height: 2 * Theme.of(context).scaling),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}