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

import 'control_center_menu.dart';

class QuickSettingChipTile extends StatelessWidget {
  final QuickSettingChipItem item;

  const QuickSettingChipTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const size = ButtonSize.normal;
    const density = ButtonDensity.normal;
    const shape = ButtonShape.rectangle;

    return Button(
      style: item.isEnabled ? const ButtonStyle.primary(size: size, density: density, shape: shape) : const ButtonStyle.secondary(size: size, density: density, shape: shape),
      onPressed: () => item.onToggle?.call(),
      child: Row(
        children: [
          Icon(item.icon),
          SizedBox(width: 8 * theme.scaling),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title).medium(),
              if (item.subtitle != null) Text(item.subtitle!).xSmall().withOpacity(0.7),
            ],
          ),
          const Spacer(),
          if (item.hasDetails) ...[
            SizedBox(height: 30 * theme.scaling, child: VerticalDivider(color: Colors.gray.withValues(alpha: 0.5))),
            SizedBox(width: 8 * theme.scaling),
            IconButton(
              variance: item.isEnabled ? ButtonVariance.primary : ButtonVariance.secondary,
              size: ButtonSize.normal,
              density: ButtonDensity.iconDense,
              onPressed: item.onOpenDetails,
              icon: const Icon(Icons.arrow_forward_ios),
            ),
          ],
        ],
      ),
    );
  }
}

class QuickSettingSliderTile extends StatelessWidget {
  final QuickSettingSliderItem item;

  const QuickSettingSliderTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        IconButton.ghost(
          icon: Icon(item.icon),
          onPressed: item.onIconTap ?? (() {}),
        ),
        Expanded(
          child: Slider(
            value: SliderValue.single(item.value),
            onChanged: (p0) => item.onChanged?.call(p0.value),
          ),
        ),
        IconButton.ghost(
          icon: const Icon(Icons.arrow_drop_down),
          onPressed: item.hasDetails ? item.onOpenDetails : null,
        ),
      ],
    );
  }
}