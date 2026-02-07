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

import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../desktop_menu_controller.dart';
import '../../desktop_menu_entry.dart';
import 'quick_settings_menu.dart';
import 'quick_settings/audio_quick_setting.dart';
import 'quick_settings/brightness_quick_setting.dart';
import 'quick_settings/ethernet_quick_setting.dart';
import 'quick_settings/quick_setting_contributor.dart';
import 'quick_settings/theme_quick_setting.dart';
import 'quick_settings/wifi_quick_setting.dart';

class QuickSettingsMenuEntry extends DesktopMenuEntry {
  final List<QuickSettingContributor> qsContributors = [
    const WifiQuickSetting(),
    const EthernetQuickSetting(),
    const ThemeQuickSetting(),
    const AudioQuickSetting(),
    const BrightnessQuickSetting(),
  ];

  late final List<QuickSettingContributor> qsChipContributors
      = qsContributors.where((c) => c.type == QuickSettingContributorType.chip)
        .toList();

  late final List<QuickSettingContributor> qsSliderContributors
      = qsContributors.where((c) => c.type == QuickSettingContributorType.slider)
        .toList();

  @override
  String get id => 'quick_settings';

  @override
  DesktopMenuEntryType get type => DesktopMenuEntryType.tray;

  @override
  String get label => 'Quick Settings';

  @override
  LogicalKeySet? get shortcut => LogicalKeySet(
    LogicalKeyboardKey.superKey,
    LogicalKeyboardKey.keyZ,
  );

  @override
  List<Widget> buildIcon(BuildContext context) {
    List<Widget> icons = [];
    for (final contributor in qsContributors) {
      final iconData = contributor.createIcon(context);
      if (iconData != null) {
        icons.add(Icon(iconData));
      }
    }
    icons.add(const Icon(Icons.power_settings_new));
    return icons;
  }

  @override
  DesktopMenu createMenu() {
    return QuickSettingsMenu(entry: this);
  }
}
