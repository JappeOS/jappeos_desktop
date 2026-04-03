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

/// Positions all OSD overlays at the same alignment; each overlay
/// is individually responsible for showing/hiding itself.
class DesktopOsdLayer extends StatelessWidget {
  final AlignmentGeometry alignment;
  final EdgeInsetsGeometry margin;
  final List<Widget> overlays;

  const DesktopOsdLayer({
    super.key,
    this.alignment = const Alignment(0, 0.75),
    this.margin = const EdgeInsets.symmetric(vertical: 16),
    this.overlays = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Padding(
          padding: margin,
          child: Align(
            alignment: alignment,
            child: Stack(
              alignment: Alignment.center,
              children: overlays,
            ),
          ),
        ),
      ),
    );
  }
}