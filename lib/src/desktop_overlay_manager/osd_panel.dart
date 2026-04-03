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

import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../components/desktop_container.dart';

sealed class OsdData {
  const OsdData();

  @override
  bool operator ==(Object other);

  @override
  int get hashCode;
}

class OsdBarData extends OsdData {
  final String label;
  final IconData icon;
  final double value;
  final String text;

  const OsdBarData({
    required this.label,
    required this.icon,
    required this.value,
    required this.text,
  });

  @override
  bool operator ==(Object other) =>
      other is OsdBarData &&
      other.label == label &&
      other.icon == icon &&
      other.value == value &&
      other.text == text;

  @override
  int get hashCode => Object.hash(label, icon, value, text);
}

class OsdIconData extends OsdData {
  final IconData icon;

  const OsdIconData({required this.icon});

  @override
  bool operator ==(Object other) =>
      other is OsdIconData && other.icon == icon;

  @override
  int get hashCode => icon.hashCode;
}

/// Pure stateless rendering of an OSD notification panel.
class OsdPanel extends StatelessWidget {
  final OsdData data;

  const OsdPanel({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DesktopOverlayContainer(
      width: 280 * theme.scaling,
      padding: EdgeInsets.all(14 * theme.scaling),
      increasedBorderRadius: true,
      child: switch (data) {
        OsdBarData() => _BarLayout(data: data as OsdBarData),
        OsdIconData() => _IconLayout(data: data as OsdIconData),
      },
    );
  }
}

class _BarLayout extends StatelessWidget {
  final OsdBarData data;
  const _BarLayout({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(data.icon, size: 28 * theme.scaling),
        SizedBox(width: 12 * theme.scaling),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(data.label).semiBold()),
                  Text(data.text).small().muted(),
                ],
              ),
              SizedBox(height: 8 * theme.scaling),
              _ValueBar(value: data.value),
            ],
          ),
        ),
      ],
    );
  }
}

class _IconLayout extends StatelessWidget {
  final OsdIconData data;
  const _IconLayout({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Icon(data.icon, size: 48 * theme.scaling),
    );
  }
}

class _ValueBar extends StatelessWidget {
  final double value;
  const _ValueBar({required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clamped = value.clamp(0.0, 1.0);
    final height = 6 * theme.scaling;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 170 * theme.scaling,
        height: height,
        color: theme.colorScheme.secondary,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: clamped,
            child: Container(color: theme.colorScheme.primary),
          ),
        ),
      ),
    );
  }
}