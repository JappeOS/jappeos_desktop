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

import 'package:jappeos_services/jappeos_services.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' hide Notification;

import '../constants.dart';
import 'application_icon.dart';
import 'desktop_container.dart';

/// A widget that displays the notification area on the desktop, showing
/// notifications provided by the [NotificationManagerService] as overlays.
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
          // Single notification for now.
          Selector<NotificationManagerService, List<Notification>>(
            selector: (_, provider) => provider.notifications,
            builder: (context, data, _) {
              if (data.isEmpty) {
                return const SizedBox.shrink();
              }
              return DesktopOverlayContainer(
                child: ProvidedNotificationContent(notification: data.last),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// A widget that displays the content of a notification provided
/// by the [NotificationManagerService].
class ProvidedNotificationContent extends StatefulWidget {
  final Notification notification;

  const ProvidedNotificationContent({super.key, required this.notification});

  @override
  State<ProvidedNotificationContent> createState() => _ProvidedNotificationContentState();
}

class _ProvidedNotificationContentState extends State<ProvidedNotificationContent> {
  List<(String, void Function())> _actions = [];
  bool _isLoading = false;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _updateObjects();
  }

  @override
  void didUpdateWidget(covariant ProvidedNotificationContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.notification != widget.notification) {
      _updateObjects();
    }
  }

  Future<void> _updateObjects() async {
    final requestId = ++_requestId;
    final data = widget.notification;

    setState(() => _isLoading = true);

    try {
      final result = await _buildActionsAsync(data);

      if (!mounted || requestId != _requestId) return;

      setState(() {
        _actions = result;
      });
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<List<(String, void Function())>> _buildActionsAsync(Notification data) async {
    List<(String, void Function())> list = [];
    int i = 0;

    for (final action in data.actionKeys) {
      if (!mounted) break;
      try {
        final actionName =
            await context.read<NotificationManagerService>()
            .getActionName(data, action);

        list.add((
          actionName,
          () async {
            try {
              await context.read<NotificationManagerService>().invokeAction(data, i);
            } catch (e) {
              debugPrint("Failed to invoke action for notification $action: $e");
            }
          },
        ));

      } catch (e) {
        debugPrint("Failed to get action name for action $action: $e");
      } finally {
        i++;
      }
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationContent.basic(
      title: widget.notification.appName,
      contentText: widget.notification.body,
      onClose: () async {
        try {
          await context.read<NotificationManagerService>()
              .dismiss(widget.notification);
        } catch (e) {
          debugPrint("Failed to dismiss notification: $e");
        }
      },
      actions: _isLoading ? const [] : _actions,
    );
  }
}

/// A widget that displays the content of a notification with
/// customizable properties. Use [ProvidedNotificationContent] to display
/// a notification provided by the [NotificationManagerService].
class NotificationContent extends StatefulWidget {
  final ApplicationIcon? appIcon;
  final Image? smallImage;
  final String source;
  final String contentText;
  final bool isMedia;
  final void Function()? onClose;
  final List<(String, void Function())> actions;
  final EdgeInsetsGeometry? padding;

  factory NotificationContent.basic({
    ApplicationIcon? appIcon,
    Image? smallImage,
    required String title,
    required String contentText,
    void Function()? onClose,
    List<(String, void Function())> actions = const [],
    EdgeInsetsGeometry? padding,
  }) {
    return NotificationContent._(
      appIcon: appIcon,
      smallImage: smallImage,
      source: title,
      contentText: contentText,
      onClose: onClose,
      actions: actions,
      padding: padding,
    );
  }

  factory NotificationContent.media({
    ApplicationIcon? appIcon,
    Image? smallImage,
    required String title,
    required String contentText,
    EdgeInsetsGeometry? padding,
  }) {
    return NotificationContent._(
      appIcon: appIcon,
      smallImage: smallImage,
      source: title,
      contentText: contentText,
      isMedia: true,
      padding: padding,
    );
  }

  const NotificationContent._({
    this.appIcon,
    this.smallImage,
    required this.source,
    required this.contentText,
    this.isMedia = false,
    this.onClose,
    this.actions = const [],
    this.padding,
  });

  @override
  State<NotificationContent> createState() => _NotificationContentState();
}

class _NotificationContentState extends State<NotificationContent> {
  bool _hovered = false;
  bool _expanded = false;

  Widget _iconButton(IconData icon, void Function() onPressed) => _hovered ? IconButton(
    onPressed: onPressed,
    icon: Icon(icon),
    size: ButtonSize.small,
    variance: ButtonVariance.secondary,
  ) : const SizedBox.shrink();

  Widget _arrowIconButton(void Function() onPressed) => _hovered ? IconButton(
    onPressed: onPressed,
    icon: AnimatedRotation(
      turns: _expanded ? 0.5 : 0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: const Icon(Icons.keyboard_arrow_down),
    ),
    size: ButtonSize.small,
    variance: ButtonVariance.secondary,
  ) : const SizedBox.shrink();

  Widget _buildAppIcon(ThemeData theme) => SizedBox.square(
    dimension: 20 * theme.scaling,
    child: widget.appIcon
        ?? Icon(
            Icons.notifications,
            size: 20 * theme.scaling,
            color: theme.colorScheme.mutedForeground,
          ),
  );

  @override
  Widget build(BuildContext context) {
    final bool isExpandable = widget.actions.isNotEmpty;
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
      },
      onExit: (_) {
        setState(() => _hovered = false);
      },
      child: GestureDetector(
        onTap: isExpandable
            ? () => setState(() => _expanded = !_expanded)
            : null,
        behavior: HitTestBehavior.translucent,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: Padding(
            padding: widget.padding ?? EdgeInsets.all(16 * theme.scaling),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: (35 / 1.25) * theme.scaling,
                  child: Row(
                    spacing: 8 * theme.scaling,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAppIcon(theme),
                      Expanded(
                        child: Text(widget.source).small().medium().muted(),
                      ),
                      if (isExpandable)
                        _arrowIconButton(() => setState(() => _expanded = !_expanded)),
                      if (!widget.isMedia)
                        _iconButton(Icons.close, widget.onClose ?? () {}),
                    ],
                  ),
                ),
                Gap(6 * theme.scaling),
                Row(
                  spacing: 12 * theme.scaling,
                  children: [
                    if (widget.smallImage != null)
                      SizedBox.square(
                        dimension: 50 * theme.scaling,
                        child: widget.smallImage,
                      ),
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
                if (_expanded) ...[
                  Gap(8 * theme.scaling),
                  Row(
                    //spacing: 4 * theme.scaling,
                    children: List.generate(widget.actions.length, (index) => Expanded(
                      child: TextButton(
                        onPressed: widget.actions[index].$2,
                        child: Text(widget.actions[index].$1),
                      ),
                    )),
                 ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}