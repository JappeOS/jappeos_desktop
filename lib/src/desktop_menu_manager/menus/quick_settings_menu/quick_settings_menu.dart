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
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../components/desktop_widgets.dart';
import '../../desktop_menu_controller.dart';
import 'quick_setting_tile.dart';
import 'quick_settings/quick_setting_contributor.dart';
import 'quick_settings/quick_settings_details_controller.dart';
import 'quick_settings_menu_entry.dart';

class QuickSettingsMenu extends DesktopMenu {
  final QuickSettingsMenuEntry entry;

  QuickSettingsMenu({Key? key, required this.entry}) : super(key: key);

  @override
  _QuickSettingsMenuState createState() => _QuickSettingsMenuState();
}

class _QuickSettingsMenuState extends State<QuickSettingsMenu> {
  final GlobalKey<NavigatorState> _containerNavigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return DOverlayContainer(
      width: 450,
      child: ChangeNotifierProvider(
        create: (_) => QuickSettingsDetailsController(),
        builder: (context, _) {
          final controller = context.watch<QuickSettingsDetailsController>();

          if (controller.isOpen) {
            final contributor = controller.active!;
            return _QuickSettingsDetailsPage(contributor: contributor);
          }

          return _QuickSettingsMainPage(entry: widget.entry);
        },
      ),
    );
  }
}

class _QuickSettingsMainPage extends StatefulWidget {
  final QuickSettingsMenuEntry entry;

  const _QuickSettingsMainPage({super.key, required this.entry});

  @override
  _QuickSettingsMainPageState createState() => _QuickSettingsMainPageState();
}

class _QuickSettingsMainPageState extends State<_QuickSettingsMainPage> {
  Widget _buildTopActions(ThemeData theme, PowerManagerService powerService)
      => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton.secondary(
        icon: Row(
          children: [
            SizedBox(width: 4 * theme.scaling),
            const Icon(Icons.battery_full),
            SizedBox(width: 4 * theme.scaling),
            const Text("100%"),
            SizedBox(width: 4 * theme.scaling),
          ],
        ),
        onPressed: () {},
      ),
      const Spacer(),
      IconButton.secondary(icon: const Icon(Icons.settings), onPressed: () {}),
      SizedBox(width: 8 * theme.scaling),
      _QuickSettingsPowerButton(
        onSuspend: () => powerService.suspend(),
        onRestart: () => powerService.reboot(),
        onPowerOff: () => powerService.shutdown(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final powerService = context.read<PowerManagerService>();

    return Padding(
      padding: EdgeInsets.all(16 * theme.scaling),
      child: IntrinsicWidth(
        child: ButtonStyleOverride.inherit(
          decoration: (context, states, value) => (value as BoxDecoration).copyWith(
            borderRadius: BorderRadius.circular(theme.radiusXl),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8 * theme.scaling,
            children: [
              _buildTopActions(theme, powerService),
              _QuickSettingsChipPanel(contributors: widget.entry.qsChipContributors),
              _QuickSettingsSliderPanel(contributors: widget.entry.qsSliderContributors),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickSettingsDetailsPage extends StatelessWidget {
  final QuickSettingContributor contributor;

  const _QuickSettingsDetailsPage({super.key, required this.contributor});

  @override
  Widget build(BuildContext context) {
    return contributor.buildDetails(context);
  }
}

class _QuickSettingsChipPanel extends StatelessWidget {
  final List<QuickSettingContributor> contributors;

  const _QuickSettingsChipPanel({required this.contributors});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    List<Row> rows = [];
    final items = contributors
        .where((c) => c.canBuild(context))
        .map((c) => c.build(context))
        .toList();

    for (int i = 0; i < items.length; i += 2) {
      final firstItem = items[i];
      final secondItem = (i + 1 < items.length) ? items[i + 1] : null;

      assert(firstItem is QuickSettingChipTile, 'Expected QuickSettingTile');
      assert(
        secondItem == null || secondItem is QuickSettingChipTile,
        'Expected QuickSettingTile',
      );

      rows.add(Row(
        children: [
          Expanded(child: firstItem),
          SizedBox(width: 8 * theme.scaling),
          if (secondItem != null) Expanded(child: secondItem) else const Spacer(),
        ],
      ));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 8 * theme.scaling,
      children: rows,
    );
  }
}

class _QuickSettingsSliderPanel extends StatelessWidget {
  final List<QuickSettingContributor> contributors;

  const _QuickSettingsSliderPanel({required this.contributors});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = contributors
        .where((c) => c.canBuild(context))
        .map((c) => c.build(context))
        .toList();

    assert(
      !items.any((e) => e is! QuickSettingSliderTile),
      'All items must be QuickSettingSliderTile',
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 8 * theme.scaling,
      children: items,
    );
  }
}

class _QuickSettingsPowerButton extends StatelessWidget {
  final void Function()? onSuspend;
  final void Function()? onRestart;
  final void Function()? onPowerOff;

  const _QuickSettingsPowerButton({
    super.key,
    this.onSuspend,
    this.onRestart,
    this.onPowerOff,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton.secondary(
      icon: const Icon(Icons.power_settings_new),
      onPressed: () {
        showDropdown(
          context: context,
          builder: (context) {
            return DropdownMenu(
              children: [
                MenuButton(
                  onPressed: (_) => onSuspend?.call(),
                  child: const Text('Suspend'),
                ),
                MenuButton(
                  onPressed: (_) => onRestart?.call(),
                  child: const Text('Restart'),
                ),
                MenuButton(
                  onPressed: (_) => onPowerOff?.call(),
                  child: const Text('Power Off'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}