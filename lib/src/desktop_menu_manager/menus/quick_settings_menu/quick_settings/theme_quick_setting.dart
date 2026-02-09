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

import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../../provider/theme_provider.dart';
import '../quick_setting_item.dart';
import '../quick_setting_tile.dart';
import 'quick_setting_contributor.dart';

class ThemeQuickSetting extends StatelessWidget
    implements QuickSettingContributor {
  const ThemeQuickSetting({super.key});

  @override
  String get id => 'theme';

  @override
  QuickSettingContributorType get type => QuickSettingContributorType.chip;

  @override
  Icon? createIcon(BuildContext context) => null;

  @override
  bool get hasDetails => false;

  @override
  Widget buildDetails(BuildContext context) => throw UnimplementedError();

  @override
  bool canBuild(BuildContext context) => true;

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final item = QuickSettingChipItem(
      id: id,
      title: 'Theme',
      icon: Icons.brightness_6,
      isEnabled: theme.isDark,
      subtitle: theme.isDark ? 'Dark' : 'Light',
      hasDetails: false,
      onToggle: () => theme.toggleTheme(),
    );

    return QuickSettingChipTile(item: item);
  }
}
