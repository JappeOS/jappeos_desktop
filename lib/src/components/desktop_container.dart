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

import 'package:shadcn_flutter/shadcn_flutter.dart';

/// A wrapper around [DualBorderOutlinedContainer] that is used for the overlays and menus of the desktop.
class DesktopOverlayContainer extends StatelessWidget {
  final double? width, height;
  final EdgeInsetsGeometry? padding;
  final bool increasedBorderRadius;
  final Widget child;

  const DesktopOverlayContainer({super.key, required this.child, this.width, this.height, this.padding, this.increasedBorderRadius = false});

  @override
  Widget build(BuildContext context) {
    return DualBorderOutlinedContainer(
      width: width,
      height: height,
      padding: padding,
      surfaceOpacity: Theme.of(context).surfaceOpacity,
      surfaceBlur: Theme.of(context).surfaceBlur,
      borderRadius: increasedBorderRadius ? Theme.of(context).borderRadiusXl : Theme.of(context).borderRadiusLg,
      //elevation: 8, TODO
      child: child,
    );
  }
}

/// A basic container widget that allows blur.
class DesktopBlurContainer extends StatelessWidget {
  final Widget child;
  final double? width, height;

  const DesktopBlurContainer({super.key, required this.child, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background.scaleAlpha(Theme.of(context).surfaceOpacity ?? 0),
      ),
      //backgroundBlur: true,
      //borderRadius: Theme.of(context).borderRadiusMd,
      //border: ShadeContainerBorder.double,
      child: SurfaceBlur(
        surfaceBlur: Theme.of(context).surfaceBlur,
        child: child
      ),
    );
  }
}