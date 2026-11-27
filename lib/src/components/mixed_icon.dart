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

import 'dart:io';

import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../provider/application_icon_service.dart';
import 'icon_request_view.dart';

/// An icon widget that supports the following types of icons at the same time:
/// * **Freedesktop icons:** looks through the system icon theme,
///   provided with a standard icon name, like 'system-update'.
/// * **File icons:** loads an icon directly from a file Uri,
///   like 'file:///path/icon.png'.
/// * **Material icons:** returns a Flutter Material icon via its
///   name, prefixed with 'material:'.
///
/// This widget can be used when the provided icon name is a string.
/// This widget is perfect for notification cards, for example.
class MixedIcon extends StatelessWidget {
  /// The name of the icon. This can be a freedesktop icon name,
  /// [Uri] that starts with 'file://', or a material icon name
  /// (starts with 'material:').
  final String? iconName;

  /// The icon service used for querying freedesktop icons.
  final ApplicationIconService service;

  /// The size of the icon in logical pixels.
  ///
  /// Icons occupy a square with width and height equal to size.
  ///
  /// Defaults to the nearest [IconTheme]'s [IconThemeData.size].
  ///
  /// If this [MixedIcon] is being placed inside an [IconButton], then use
  /// [IconButton.iconSize] instead, so that the [IconButton] can make the splash
  /// area the appropriate size as well. The [IconButton] uses an [IconTheme] to
  /// pass down the size to the [MixedIcon].
  final double? size;

  /// The color to use when drawing the icon.
  ///
  /// Defaults to the nearest [IconTheme]'s [IconThemeData.color].
  ///
  /// The color (whether specified explicitly here or obtained from the
  /// [IconTheme]) will be further adjusted by the nearest [IconTheme]'s
  /// [IconThemeData.opacity].
  ///
  /// {@tool snippet}
  /// Typically, a Material Design color will be used, as follows:
  ///
  /// ```dart
  /// MixedIcon(
  ///   'material:widgets',
  ///   color: Colors.blue.shade400,
  /// )
  /// ```
  /// {@end-tool}
  final Color? color;

  /// Whether to scale the size of this widget using the ambient [MediaQuery]'s [TextScaler].
  ///
  /// This is specially useful when you have an icon associated with a text, as
  /// scaling the text without scaling the icon would result in a confusing
  /// interface.
  ///
  /// Defaults to the nearest [IconTheme]'s
  /// [IconThemeData.applyTextScaling].
  final bool? applyTextScaling;

  const MixedIcon(
    this.iconName, {
    super.key,
    required this.service,
    this.size,
    this.color,
    this.applyTextScaling,
  });

  @override
  Widget build(BuildContext context) {
    const uriScheme = "file";
    const materialPrefix = "material:";

    final IconThemeData iconTheme = IconTheme.of(context);
    final bool applyTextScaling = this.applyTextScaling
        ?? iconTheme.applyTextScaling
        ?? false;
    final double tentativeIconSize = size
        ?? iconTheme.size
        ?? kDefaultFontSize;
    final double iconSize =
        applyTextScaling
            ? MediaQuery.textScalerOf(context).scale(tentativeIconSize)
            : tentativeIconSize;

    final baseColor = color ?? iconTheme.color!;
    final iconColor = baseColor.withValues(
      alpha: baseColor.a * (iconTheme.opacity ?? 1.0),
    );

    final iconName = this.iconName;
    final fallback = Icon(
      Icons.settings_applications,
      size: tentativeIconSize,
      color: color,
      applyTextScaling: applyTextScaling,
    );

    if (iconName == null || iconName.startsWith(materialPrefix)) {
      final icon = kMaterialIcons[iconName?.replaceFirst(materialPrefix, "")];
      return icon != null ? Icon(
        icon,
        size: tentativeIconSize,
        color: color,
        applyTextScaling: applyTextScaling,
      ) : fallback;
    }

    ApplicationIconRequest request;
    final uri = Uri.tryParse(iconName);
    if (uri != null && uri.scheme == uriScheme) {
      request = service.requestFile(File.fromUri(uri));
    } else {
      request = service.requestNamed(
        iconName,
        size: iconSize,
        dpr: MediaQuery.devicePixelRatioOf(context)
      );
    }

    return IconRequestView(
      request: request,
      identity: (service, iconName),
      size: iconSize,
      color: iconColor,
      fallback: fallback,
    );
  }
}