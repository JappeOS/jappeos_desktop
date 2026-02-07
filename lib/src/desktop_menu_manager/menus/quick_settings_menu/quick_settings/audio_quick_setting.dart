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

import '../quick_setting_item.dart';
import '../quick_setting_tile.dart';
import 'quick_setting_contributor.dart';

class AudioQuickSetting extends StatelessWidget
    implements QuickSettingContributor {
  const AudioQuickSetting({super.key});

  @override
  String get id => 'audio';

  @override
  QuickSettingContributorType get type => QuickSettingContributorType.slider;

  @override
  IconData? createIcon(BuildContext context) => Icons.volume_up;

  @override
  bool get hasDetails => false;

  @override
  Widget buildDetails(BuildContext context) {
    return const AudioDetailsPage();
  }

  @override
  bool canBuild(BuildContext context) => true;

  @override
  Widget build(BuildContext context) {
    final item = QuickSettingSliderItem(
      id: id,
      icon: Icons.volume_up,
      value: 0.5,
      hasDetails: true,
    );

    return QuickSettingSliderTile(item: item);
  }
}

class AudioDetailsPage extends StatelessWidget {
  const AudioDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text("Not implemented yet");
  }
}