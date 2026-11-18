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
import 'package:jappeos_desktop/src/extensions.dart';
import 'package:jappeos_services/jappeos_services.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' hide Notification;

import '../../components/desktop_container.dart';
import '../../components/desktop_notifications.dart';
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
    return const [NotificationText(), Icon(Icons.notifications)];
  }

  @override
  DesktopMenu createMenu() {
    return NotificationMenu();
  }
}

class NotificationText extends StatefulWidget {
  const NotificationText({super.key});

  @override
  _NotificationTextState createState() => _NotificationTextState();
}

class _NotificationTextState extends State<NotificationText> {
  String _timeString = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(minutes: 1), (Timer t) => _updateTime());
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

class NotificationMenu extends DesktopMenu {
  NotificationMenu({super.key});

  @override
  _NotificationMenuState createState() => _NotificationMenuState();
}

class _NotificationMenuState extends State<NotificationMenu> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultPadding = 16 * theme.scaling;
    final notificationPadding = theme.radiusLg;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DesktopOverlayContainer(
          width: 400,
          height: 375,
          padding: EdgeInsets.all(defaultPadding),
          child: _Calendar(),
        ),
        SizedBox(height: defaultPadding),
        DesktopOverlayContainer(
          width: 400,
          padding: EdgeInsets.all(notificationPadding),
          child: Selector<NotificationManagerService, List<Notification>>(
            selector: (_, provider) => provider.notifications,
            builder: (context, data, _) {
              if (data.isEmpty) {
                return SizedBox(
                  height: 50,
                  child: Center(
                    child: Text("No notifications").small().muted()
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 4 * theme.scaling,
                children: [
                  for (final notification in data.reversed)
                    Card(
                      padding: EdgeInsets.zero,
                      filled: true,
                      fillColor: theme.colorScheme.secondary,
                      borderColor: theme.colorScheme.border,
                      borderRadius: BorderRadius.circular(notificationPadding),
                      child: ProvidedNotificationContent(notification: notification),
                    ),
                  OutlineButton(
                    onPressed: () async {
                      try {
                        await context.read<NotificationManagerService>().clear();
                      } catch (e) {
                        debugPrint("Error clearing notifications: $e");
                      }
                    },
                    child: const Text("Clear All"),
                  ),
                ],
              );
            },
          ),
          /*child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 4 * theme.scaling,
            children: [
              Card(
                padding: EdgeInsets.zero,
                filled: true,
                fillColor: theme.colorScheme.secondary,
                borderColor: theme.colorScheme.border,
                borderRadius: BorderRadius.circular(notificationPadding),
                child: NotificationContent.basic(title: "Example App", contentText: "This is a sample notification.", actions: [("Dismiss", () {}), ("Do Something", () {})], padding: EdgeInsets.all(notificationPadding)),
              ),

              Card(
                padding: EdgeInsets.zero,
                filled: true,
                fillColor: theme.colorScheme.secondary,
                borderColor: theme.colorScheme.border,
                borderRadius: BorderRadius.circular(notificationPadding),
                child: NotificationContent.media(title: "Example App", contentText: "YouTube Video\nYouTube Channel\nSomething", padding: EdgeInsets.all(notificationPadding)),
              ),
              //_NotificationCard.media(title: "YouTube", contentText: "YouTube Video\nYouTube Channel\nSomething"),
              //_NotificationCard.basic(title: "Notification", contentText: "Hello, World!", actions: [("Dismiss", () {}), ("Do Something", () {})]),
              OutlineButton(onPressed: () {}, child: const Text("Clear All")),
            ],
          ),*/
        ),
      ],
    );
  }
}

class _Calendar extends StatefulWidget {
  const _Calendar({super.key});

  @override
  State<_Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<_Calendar> {
  static const double weekdayHeaderHeight = 32.0;

  late final List<String> weekdays;

  DateTime _month = DateTime.now();
  DateTime? _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    List<String> wdays = [];
    for (int i = 1; i <= 7; i++) {
      wdays.add(
        ShadcnLocalizations.of(context).getAbbreviatedWeekday(i)
      );
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
            children: weekdays.map((weekday) => Expanded(
                child: Center(
                  child: Text(
                    weekday,
                  ).small().muted(),
                ),
              ),
            ).toList(),
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

              final leadingDays =
                  (firstOfMonth.weekday - DateTime.monday) % 7;

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