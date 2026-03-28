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

import 'quick_setting_item.dart';

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

class QuickSettingSliderTile extends StatefulWidget {
  final QuickSettingSliderItem item;

  const QuickSettingSliderTile({super.key, required this.item});

  @override
  State<QuickSettingSliderTile> createState() => _QuickSettingSliderTileState();
}

class _QuickSettingSliderTileState extends State<QuickSettingSliderTile> {
  double? _localValue; // non-null only while dragging

  @override
  void didUpdateWidget(QuickSettingSliderTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the external value changed while NOT dragging, clear local override
    if (oldWidget.item.value != widget.item.value) {
      _localValue = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayValue = _localValue ?? widget.item.value;

    return Row(
      mainAxisSize: MainAxisSize.max,
      spacing: 4 * Theme.of(context).scaling,
      children: [
        IconButton.ghost(
          icon: Icon(widget.item.icon),
          onPressed: widget.item.onIconTap ?? (() {}),
        ),
        Expanded(
          child: Slider(
            value: SliderValue.single(displayValue),
            onChanged: (p0) {
              setState(() => _localValue = p0.value);
              widget.item.onChanged?.call(p0.value);
            },
            onChangeEnd: (p0) {
              // Release local override - let the service value take over
              setState(() => _localValue = null);
            },
          ),
        ),
        IconButton.ghost(
          icon: const Icon(Icons.arrow_drop_down),
          onPressed: widget.item.hasDetails ? widget.item.onOpenDetails : null,
        ),
      ],
    );
  }
}

class QuickSettingPowerTile extends StatelessWidget {
  final List<QuickSettingPowerItem> items;

  const QuickSettingPowerTile({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8 * theme.scaling,
      children: items.map((item) {
        return Tooltip(
          tooltip: (context) => item.tooltip != null
              ? TooltipContainer(child: Text(item.tooltip!))
              : const SizedBox.shrink(),
          child: IconButton.secondary(
          icon: Row(
            children: [
              SizedBox(width: 4 * theme.scaling),
              item.icon,
              if (item.label != null && item.label!.isNotEmpty) ...[
                SizedBox(width: 4 * theme.scaling),
                Text(item.label!),
              ],
              SizedBox(width: 4 * theme.scaling),
            ],
          ),
          onPressed: item.onTap ?? () {},
          ),
        );
      }).toList(),
    );
  }
}