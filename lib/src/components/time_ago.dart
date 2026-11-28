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

import 'dart:async';
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// A text widget that shows how long ago a certain event occurred.
/// The point in time at which the event occurred is provided by [dateTime].
/// A curstom [style] can also be provided, just like with a [Text] widget.
class TimeAgo extends StatefulWidget {
  final DateTime dateTime;
  final TextStyle? style;

  const TimeAgo({
    super.key,
    required this.dateTime,
    this.style,
  });

  @override
  State<TimeAgo> createState() => _TimeAgoState();
}

class _TimeAgoState extends State<TimeAgo> {
  Timer? _timer;
  late String _text;

  @override
  void initState() {
    super.initState();
    _update();
  }

  @override
  void didUpdateWidget(covariant TimeAgo oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.dateTime != widget.dateTime) {
      _update();
    }
  }

  void _update() {
    _timer?.cancel();

    final now = DateTime.now();
    final difference = now.difference(widget.dateTime);

    _text = _format(difference);

    final nextUpdate = _nextUpdate(difference);

    _timer = Timer(nextUpdate, () {
      if (!mounted) return;

      setState(() {
        _update();
      });
    });
  }

  String _format(Duration difference) {
    final seconds = difference.inSeconds;

    if (seconds < 0) {
      return 'in ${_format(Duration(seconds: -seconds))}';
    }

    if (seconds < 60) {
      return 'Just now';
    }

    final minutes = difference.inMinutes;

    if (minutes < 60) {
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    }

    final hours = difference.inHours;

    if (hours < 24) {
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    }

    final days = difference.inDays;

    if (days == 1) {
      return 'Yesterday';
    }

    if (days < 7) {
      return '$days days ago';
    }

    if (days < 30) {
      final weeks = (days / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    }

    if (days < 365) {
      final months = (days / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }

    final years = (days / 365).floor();
    return '$years ${years == 1 ? 'year' : 'years'} ago';
  }

  Duration _nextUpdate(Duration difference) {
    final seconds = difference.inSeconds;

    if (seconds < 0) {
      return Duration(seconds: -seconds);
    }

    if (seconds < 60) {
      return Duration(seconds: 60 - seconds);
    }

    if (seconds < 3600) {
      return Duration(seconds: 60 - seconds % 60);
    }

    if (seconds < 86400) {
      return Duration(seconds: 3600 - seconds % 3600);
    }

    if (seconds < 604800) {
      return Duration(days: 1) -
          Duration(seconds: seconds % 86400);
    }

    if (seconds < 2592000) {
      final nextDay = 7 - difference.inDays % 7;
      return Duration(days: nextDay) -
          Duration(seconds: seconds % 86400);
    }

    if (seconds < 31536000) {
      final nextDay = 30 - difference.inDays % 30;
      return Duration(days: nextDay) -
          Duration(seconds: seconds % 86400);
    }

    final nextDay = 365 - difference.inDays % 365;

    return Duration(days: nextDay) -
        Duration(seconds: seconds % 86400);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _text,
      style: widget.style,
    );
  }
}