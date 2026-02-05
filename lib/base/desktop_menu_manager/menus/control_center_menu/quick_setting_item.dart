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

part of 'control_center_menu.dart';

class QuickSettingChipItem {
  final String id;

  final String title;
  final IconData icon;

  final String? subtitle;
  final bool isEnabled;

  final bool hasDetails;

  final VoidCallback? onToggle;
  final VoidCallback? onOpenDetails;

  QuickSettingChipItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.isEnabled,
    this.subtitle,
    this.hasDetails = false,
    this.onToggle,
    this.onOpenDetails,
  });
}

class QuickSettingSliderItem {
  final String id;

  final IconData icon;
  final double value;

  final bool hasDetails;

  final VoidCallback? onIconTap;
  final Function(double)? onChanged;
  final VoidCallback? onOpenDetails;

  final Widget Function(BuildContext)? detailsBuilder;

  QuickSettingSliderItem({
    required this.id,
    required this.icon,
    required this.value,
    this.hasDetails = false,
    this.onIconTap,
    this.onChanged,
    this.onOpenDetails,
    this.detailsBuilder,
  });
}
