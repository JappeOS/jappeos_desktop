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

import 'quick_settings/quick_settings_details_controller.dart';

class QuickSettingDetailsPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final void Function(bool) onToggle;
  final Widget child;

  const QuickSettingDetailsPage({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.all(16 * theme.scaling),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8 * theme.scaling,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              borderRadius: BorderRadius.circular(theme.radiusXl),
            ),
            child: ButtonStyleOverride.inherit(
              decoration: (context, states, value) => (value as BoxDecoration).copyWith(
                borderRadius: BorderRadius.circular(theme.radiusXl),
              ),
              child: Row(
                spacing: 8 * theme.scaling,
                children: _buildActionBarItems(context, theme),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  List<Widget> _buildActionBarItems(BuildContext context, ThemeData theme) => [
    IconButton.ghost(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => QuickSettingsDetailsController.of(context).close(),
    ),
    const Spacer(),
    Icon(icon),
    Text(title).semiBold(),
    const Spacer(),
    Switch(value: value, onChanged: onToggle),
    Gap(2 * theme.scaling),
  ];
}