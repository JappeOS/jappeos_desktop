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

import 'package:jappeos_desktop/src/constants.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'desktop_container.dart';

class DesktopNotificationArea extends StatefulWidget {
  const DesktopNotificationArea({super.key});

  @override
  State<DesktopNotificationArea> createState() => _DesktopNotificationAreaState();
}

class _DesktopNotificationAreaState extends State<DesktopNotificationArea> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned(
      top: DSKTP_UI_LAYER_TOPBAR_HEIGHT + (8 * theme.scaling),
      right: 8 * theme.scaling,
      width: 350 * theme.scaling,
      child: Column(
        children: [
          // TODO: Implement notifications through jappeos_services, this is just a placeholder for now
          /*NotificationCard.basic(
            title: "Email App",
            contentText: "You have a new email from John Doe.",
            actions: [
              ("Reply", () {}),
              ("Mark as Read", () {}),
            ],
          ),*/
        ],
      ),
    );
  }
}

class NotificationCard extends StatefulWidget {
  final String source;
  final String contentText;
  final bool isMedia;
  final List<(String, void Function())> actions;

  factory NotificationCard.basic({
    required String title,
    required String contentText,
    List<(String, void Function())> actions = const [],
  }) {
    return NotificationCard._(
      source: title,
      contentText: contentText,
      actions: actions,
    );
  }

  factory NotificationCard.media({
    required String title,
    required String contentText,
  }) {
    return NotificationCard._(
      source: title,
      contentText: contentText,
      isMedia: true
    );
  }

  const NotificationCard._({
    required this.source,
    required this.contentText,
    this.isMedia = false,
    this.actions = const [],
  });

  @override
  _NotificationCardState createState() => _NotificationCardState();
}

class _NotificationCardState extends State<NotificationCard> {
  bool _hovered = false;
  bool _expanded = false;

  Widget _iconButton(IconData icon, void Function() onPressed) => _hovered ? IconButton(
    onPressed: onPressed,
    icon: Icon(icon),
    size: ButtonSize.small,
    variance: ButtonVariance.secondary,
  ) : const SizedBox.shrink();

  Widget _arrowIconButton(void Function() onPressed) => _hovered ?IconButton(
    onPressed: onPressed,
    icon: AnimatedRotation(
      turns: _expanded ? 0.5 : 0, // 180° rotation
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: const Icon(Icons.keyboard_arrow_down),
    ),
    size: ButtonSize.small,
    variance: ButtonVariance.secondary,
  ) : const SizedBox.shrink();

  @override
  Widget build(BuildContext context) {
    final bool isExpandable = widget.actions.isNotEmpty;
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _hovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _hovered = false;
        });
      },
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: DesktopOverlayContainer(
          /*style: FilledButton.styleFrom( TODO
            padding: EdgeInsets.symmetric(horizontal: 4 * Theme.of(context).scaling, vertical: 4 * Theme.of(context).scaling * 1.1),
            shape: RoundedRectangleBorder(side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant), borderRadius: BorderRadius.circular(4 * Theme.of(context).scaling)),
          ),*/
          //onPressed: () {},
          padding: EdgeInsets.all(16 * theme.scaling),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8 * theme.scaling,
            children: [
              SizedBox(
                height: 35 / 1.25,
                child: Row(
                  spacing: 8 * theme.scaling,
                  children: [
                    const Icon(Icons.settings, size: 20).muted(),
                    Expanded(child: Text(widget.source).muted()),
                    if (isExpandable) _arrowIconButton(() => setState(() => _expanded = !_expanded)),
                    if (!widget.isMedia) _iconButton(Icons.close, () {}),
                  ],
                ),
              ),
              Row(
                spacing: 8 * theme.scaling,
                children: [
                  SizedBox.square(dimension: 50, child: Container(color: Colors.black)),
                  Expanded(
                    child: Text(
                      widget.contentText,
                      textAlign: TextAlign.left,
                      maxLines: 3,
                    ).small().ellipsis(),
                  ),
                  if (widget.isMedia) ... [
                    IconButton.ghost(onPressed: () {}, icon: const Icon(Icons.skip_previous)),
                    IconButton.secondary(onPressed: () {}, icon: const Icon(Icons.play_arrow)),
                    IconButton.ghost(onPressed: () {}, icon: const Icon(Icons.skip_next)),
                  ],
                ],
              ),
              if (_expanded) Row(
                //spacing: 4 * theme.scaling,
                children: List.generate(widget.actions.length, (index) => Expanded(
                  child: TextButton(
                    onPressed: widget.actions[index].$2,
                    child: Text(widget.actions[index].$1),
                  ),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}