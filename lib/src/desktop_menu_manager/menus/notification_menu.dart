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

import 'package:flutter/material.dart' show DateUtils;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:jappeos_services/jappeos_services.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' hide Notification;

import '../../components/desktop_container.dart';
import '../../components/desktop_notifications.dart';
import '../../extensions.dart';
import '../desktop_menu_controller.dart';
import '../desktop_menu_entry.dart';

class NotificationMenuEntry extends DesktopMenuEntry {
  @override
  String get id => 'notification';

  @override
  DesktopMenuEntryType get type => DesktopMenuEntryType.tray;

  @override
  String get label => 'Notifications';

  @override
  LogicalKeySet? get shortcut => LogicalKeySet(
        LogicalKeyboardKey.superKey,
        LogicalKeyboardKey.keyX,
      );

  @override
  List<Widget> buildIcon(BuildContext context) {
    return const [_NotificationText(), _NotificationIcon()];
  }

  @override
  DesktopMenu createMenu() {
    return NotificationMenu();
  }
}

class _NotificationText extends StatefulWidget {
  const _NotificationText();

  @override
  _NotificationTextState createState() => _NotificationTextState();
}

class _NotificationTextState extends State<_NotificationText> {
  String _timeString = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer =
        Timer.periodic(const Duration(minutes: 1), (Timer t) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    final formattedTime = DateFormat('HH:mm').format(now);
    setState(() {
      _timeString = formattedTime;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(_timeString).small();
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon();

  @override
  Widget build(BuildContext context) {
    return Selector<NotificationManagerService, List<Notification>>(
      selector: (_, p) => p.notifications,
      builder: (_, notifications, __) => notifications.isEmpty
          ? Icon(Icons.notifications_outlined)
          : Icon(Icons.notifications_active),
    );
  }
}

class NotificationMenu extends DesktopMenu {
  NotificationMenu({super.key});

  @override
  _NotificationMenuState createState() => _NotificationMenuState();
}

// Retain removed snapshots until their cards finish animating out.
class _NotificationCardEntry {
  Notification notification;
  bool removing = false;
  bool swipeOut = false;

  _NotificationCardEntry(this.notification);
}

class _NotificationMenuState extends State<NotificationMenu> {
  final _cards = <_NotificationCardEntry>[];
  final _clearPaths = <String>{};
  bool _clearing = false;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final notifications = context
        .watch<NotificationManagerService>()
        .notifications
        .reversed
        .toList();

    final paths = notifications.map((n) => n.path.value).toSet();
    for (final entry in _cards) {
      if (!paths.contains(entry.notification.path.value) && !entry.removing) {
        entry.removing = true;
        entry.swipeOut = _clearPaths.remove(entry.notification.path.value);
      }
    }

    for (var index = 0; index < notifications.length; index++) {
      final notification = notifications[index];
      final existing = _cards.indexWhere(
        (entry) => entry.notification.path == notification.path,
      );

      if (existing >= 0) {
        _cards[existing]
          ..notification = notification
          ..removing = false
          ..swipeOut = false;
      } else {
        final following =
            notifications.skip(index + 1).map((n) => n.path).toSet();
        final insertion = _cards.indexWhere(
          (entry) => following.contains(entry.notification.path),
        );

        _cards.insert(
          insertion < 0 ? _cards.length : insertion,
          _NotificationCardEntry(notification),
        );
      }
    }

    // Reorder live cards without moving outgoing cards out of their slots.
    final live = {
      for (final entry in _cards)
        if (!entry.removing) entry.notification.path: entry,
    };

    var index = 0;
    for (var slot = 0; slot < _cards.length; slot++) {
      if (!_cards[slot].removing) {
        _cards[slot] = live[notifications[index++].path]!;
      }
    }
  }

  Future<void> _clearAll() async {
    if (_clearing) return;
    final service = context.read<NotificationManagerService>();

    // Capture only this batch: notifications arriving later must not inherit
    // its swipe animation. Keep cards until the service confirms their removal.
    final paths = service.notifications.map((n) => n.path.value).toSet();
    setState(() {
      _clearing = true;
      _clearPaths.addAll(paths);
    });

    try {
      await service.clear();
    } catch (error) {
      _clearPaths.removeAll(paths);
      debugPrint('Error clearing notifications: $error');
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  void _removeCard(_NotificationCardEntry entry) {
    if (!mounted || !entry.removing) return;
    setState(() => _cards.remove(entry));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultPadding = 16 * theme.scaling;
    final notificationPadding = theme.radiusLg;
    return LayoutBuilder(builder: (context, constraints) {
      // Leave room for the notification panel on short displays too.
      final calendarHeight = constraints.hasBoundedHeight
          ? (constraints.maxHeight * 0.65).clamp(0.0, 375.0)
          : 375.0;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DesktopOverlayContainer(
            width: 400,
            height: calendarHeight,
            padding: EdgeInsets.all(defaultPadding),
            child: _Calendar(),
          ),
          SizedBox(height: defaultPadding),
          Flexible(
            fit: FlexFit.loose,
            child: DesktopOverlayContainer(
              width: 400,
              padding: EdgeInsets.all(notificationPadding),
              child: _cards.isEmpty
                  ? SizedBox(
                      height: 50,
                      child: Center(
                        child: Text('No notifications').small().muted(),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Flexible(
                          fit: FlexFit.loose,
                          child: Scrollbar(
                            controller: _scrollController,
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              primary: false,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (final entry in _cards)
                                    _AnimatedNotificationCard(
                                      key: ValueKey(entry.notification.path),
                                      removing: entry.removing,
                                      swipeOut: entry.swipeOut,
                                      onRemoved: () => _removeCard(entry),
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                            bottom: 4 * theme.scaling),
                                        child: Card(
                                          padding: EdgeInsets.zero,
                                          filled: true,
                                          fillColor:
                                              theme.colorScheme.secondary,
                                          borderColor: theme.colorScheme.border,
                                          borderRadius: BorderRadius.circular(
                                            notificationPadding,
                                          ),
                                          child: ProvidedNotificationContent(
                                            notification: entry.notification,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        OutlineButton(
                          onPressed: _clearing ||
                                  _cards.every((entry) => entry.removing)
                              ? null
                              : _clearAll,
                          child: const Text('Clear All'),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      );
    });
  }
}

/// Owns each card's animation so insertions, removals and reversals are independent.
class _AnimatedNotificationCard extends StatefulWidget {
  final bool removing;
  final bool swipeOut;
  final VoidCallback onRemoved;
  final Widget child;

  const _AnimatedNotificationCard({
    super.key,
    required this.removing,
    required this.swipeOut,
    required this.onRemoved,
    required this.child,
  });

  @override
  State<_AnimatedNotificationCard> createState() =>
      _AnimatedNotificationCardState();
}

class _AnimatedNotificationCardState extends State<_AnimatedNotificationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;
  bool? _reducedMotion;
  double _swipeStart = 1;
  double _swipeScale = 1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: kDefaultDuration)
      ..addStatusListener(_onStatus);
    _progress = _controller.drive(CurveTween(curve: Curves.easeOutCubic));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_reducedMotion != reducedMotion) {
      _reducedMotion = reducedMotion;
      _animate();
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedNotificationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.removing != widget.removing ||
        oldWidget.swipeOut != widget.swipeOut) {
      _animate();
    }
  }

  void _animate() {
    if (widget.removing) {
      _swipeStart = _controller.value;
      _swipeScale = 0.9 + 0.1 * _progress.value;
      if (_reducedMotion == true) {
        _controller.value = 0;
      } else {
        _controller.reverse();
      }
      if (_controller.isDismissed) _scheduleRemoval();
    } else if (_reducedMotion == true) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && widget.removing) {
      _scheduleRemoval();
    }
  }

  void _scheduleRemoval() {
    // Zero-duration/reduced-motion transitions can complete during a rebuild.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.removing && _controller.isDismissed) {
        widget.onRemoved();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) {
      final swiping = widget.removing && widget.swipeOut;
      final offset = swiping && _swipeStart > 0
          ? 1 - _controller.value / _swipeStart
          : 0.0;
      return IgnorePointer(
        ignoring: widget.removing,
        child: ExcludeSemantics(
          excluding: widget.removing,
          child: SizeTransition(
            sizeFactor: _progress,
            //alignment: Alignment.topCenter,
            child: Opacity(
              opacity: _progress.value,
              child: FractionalTranslation(
                translation: Offset(offset, 0),
                child: Transform.scale(
                  scale:
                      swiping ? _swipeScale : 0.9 + 0.1 * _progress.value,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _Calendar extends StatefulWidget {
  const _Calendar();

  @override
  State<_Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<_Calendar> {
  static const double weekdayHeaderHeight = 32.0;

  late List<String> weekdays;

  DateTime _month = DateTime.now();
  DateTime? _selectedDate = DateTime.now();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    List<String> wdays = [];
    for (int i = 1; i <= 7; i++) {
      wdays.add(ShadcnLocalizations.of(context).getAbbreviatedWeekday(i));
    }
    weekdays = wdays;
  }

  @override
  Widget build(BuildContext context) {
    ShadcnLocalizations localizations = ShadcnLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            OutlineButton(
              density: ButtonDensity.icon,
              onPressed: () {
                setState(() {
                  _month = _month.addMonths(-1);
                });
              },
              child: const Icon(Icons.arrow_back).iconXSmall(),
            ),
            Text('${localizations.getMonth(_month.month)} ${_month.year}')
                .small()
                .medium()
                .center()
                .expanded(),
            OutlineButton(
              density: ButtonDensity.icon,
              onPressed: () {
                setState(() {
                  _month = _month.addMonths(1);
                });
              },
              child: const Icon(Icons.arrow_forward).iconXSmall(),
            ),
          ],
        ),
        const Gap(16),
        Expanded(child: _buildCalendar()),
      ],
    );
  }

  Widget _buildCalendar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Weekday header.
        SizedBox(
          height: weekdayHeaderHeight,
          child: Row(
            children: weekdays
                .map(
                  (weekday) => Expanded(
                    child: Center(
                      child: Text(
                        weekday,
                      ).small().muted(),
                    ),
                  ),
                )
                .toList(),
          ),
        ),

        // The grid fills the remaining height.
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const weeks = 6;
              const daysPerWeek = 7;
              const totalDays = weeks * daysPerWeek;

              final gridHeight = constraints.maxHeight;

              // The grid must have a finite, positive height.
              if (!gridHeight.isFinite || gridHeight <= 0) {
                throw FlutterError(
                  'Calendar requires a finite, positive height. '
                  'Ensure that _Calendar is placed inside a '
                  'parent with bounded height.',
                );
              }

              final cellHeight = gridHeight / weeks;

              final firstOfMonth = DateTime(
                _month.year,
                _month.month,
                1,
              );

              final leadingDays = (firstOfMonth.weekday - DateTime.monday) % 7;

              final firstDisplayedDay = DateTime(
                firstOfMonth.year,
                firstOfMonth.month,
                firstOfMonth.day - leadingDays,
              );

              return GridView.builder(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                primary: false,
                itemCount: totalDays,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: daysPerWeek,
                  mainAxisExtent: cellHeight,
                ),
                itemBuilder: (context, index) {
                  final day = DateTime(
                    firstDisplayedDay.year,
                    firstDisplayedDay.month,
                    firstDisplayedDay.day + index,
                  );

                  final isSelected = DateUtils.isSameDay(
                    day,
                    _selectedDate,
                  );

                  final isMuted = !isSelected &&
                      (day.month != _month.month ||
                          day.weekday == DateTime.sunday ||
                          day.weekday == DateTime.saturday);

                  return Center(
                    child: SizedBox.square(
                      dimension: 42,
                      child: IconButton(
                        variance: isSelected
                            ? ButtonVariance.primary
                            : ButtonVariance.ghost,
                        icon: Text(
                          '${day.day}',
                          overflow: TextOverflow.visible,
                          style: TextStyle(
                            color: isMuted
                                ? Theme.of(context).colorScheme.mutedForeground
                                : null,
                          ),
                        ),
                        onPressed: () => _onDateSelected(day),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }
}
