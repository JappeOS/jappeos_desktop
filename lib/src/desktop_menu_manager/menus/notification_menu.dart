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
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../components/desktop_container.dart';
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
    final defaultPadding = 16 * Theme.of(context).scaling;
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
          padding: EdgeInsets.all(defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 4 * Theme.of(context).scaling,
            children: [
              _NotificationCard.media(title: "YouTube", contentText: "YouTube Video\nYouTube Channel\nSomething"),
              _NotificationCard.basic(title: "Notification", contentText: "Hello, World!", actions: [("Dismiss", () {}), ("Do Something", () {})]),
              OutlineButton(onPressed: () {}, child: const Text("Clear All")),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotificationCard extends StatefulWidget {
  final String source;
  final String contentText;
  final bool isMedia;
  final List<(String, void Function())> actions;

  factory _NotificationCard.basic({required String title, required String contentText, List<(String, void Function())> actions = const []}) {
    return _NotificationCard._(source: title, contentText: contentText, actions: actions);
  }

  factory _NotificationCard.media({required String title, required String contentText}) {
    return _NotificationCard._(source: title, contentText: contentText, isMedia: true);
  }

  const _NotificationCard._({required this.source, required this.contentText, this.isMedia = false, this.actions = const []});

  @override
  _NotificationCardState createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> {
  bool _hovered = false;
  bool _expanded = false;

  Widget _iconButton(IconData icon, void Function() onPressed) => IconButton(
    onPressed: onPressed,
    icon: _hovered ? Icon(icon) : const SizedBox.shrink(),
    size: ButtonSize.small,
    variance: ButtonVariance.secondary,
  );

  Widget _arrowIconButton(void Function() onPressed) => IconButton(
    onPressed: onPressed,
    icon: _hovered ?
      AnimatedRotation(
        turns: _expanded ? 0.5 : 0, // 180° rotation
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: const Icon(Icons.keyboard_arrow_down),
      ) :
      const SizedBox.shrink(),
    size: ButtonSize.small,
    variance: ButtonVariance.secondary,
  );

  @override
  Widget build(BuildContext context) {
    final bool isExpandable = widget.actions.isNotEmpty;

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
        child: SecondaryButton(
          /*style: FilledButton.styleFrom( TODO
            padding: EdgeInsets.symmetric(horizontal: 4 * Theme.of(context).scaling, vertical: 4 * Theme.of(context).scaling * 1.1),
            shape: RoundedRectangleBorder(side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant), borderRadius: BorderRadius.circular(4 * Theme.of(context).scaling)),
          ),*/
          onPressed: () {},
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 4 * Theme.of(context).scaling,
            children: [
              SizedBox(
                height: 35 / 1.25,
                child: Row(
                  spacing: 4 * Theme.of(context).scaling,
                  children: [
                    const Icon(Icons.settings, size: 20).muted(),
                    Expanded(child: Text(widget.source).muted()),
                    if (isExpandable) _arrowIconButton(() => setState(() => _expanded = !_expanded)),
                    if (!widget.isMedia) _iconButton(Icons.close, () {}),
                  ],
                ),
              ),
              Row(
                spacing: 4 * Theme.of(context).scaling,
                children: [
                  SizedBox.square(dimension: 50, child: Container(color: Colors.black)),
                  Expanded(
                    child: Text(
                      widget.contentText,
                      style: Theme.of(context).typography.medium,
                      textAlign: TextAlign.left,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3,
                    ),
                  ),
                  if (widget.isMedia) ... [
                    IconButton(onPressed: () {}, icon: const Icon(Icons.skip_previous), variance: ButtonVariance.ghost),
                    IconButton(onPressed: () {}, icon: const Icon(Icons.play_arrow), variance: ButtonVariance.secondary),
                    IconButton(onPressed: () {}, icon: const Icon(Icons.skip_next), variance: ButtonVariance.ghost),
                  ],
                ],
              ),
              if (_expanded) Row(
                spacing: 4 * Theme.of(context).scaling,
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