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

import 'package:freedesktop_desktop_entry/freedesktop_desktop_entry.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../provider/desktop_entry_provider.dart';

/// A basic widget that has the logo of an app and also the name below.
class DesktopApplicationItem extends StatefulWidget {
  final String entry;
  final bool showTitle;
  final double sizeFactor;
  final double? borderRadius;
  final void Function()? onPress;

  const DesktopApplicationItem._({
    Key? key,
    required this.entry,
    this.showTitle = true,
    this.sizeFactor = 1.0,
    this.borderRadius,
    this.onPress,
  }) : super(key: key);

  factory DesktopApplicationItem.icon({
    required String entry,
    double sizeFactor = 1,
    double? borderRadius,
    void Function()? onPress,
  }) {
    return DesktopApplicationItem._(
      entry: entry,
      showTitle: false,
      sizeFactor: sizeFactor,
      borderRadius: borderRadius,
      onPress: onPress,
    );
  }

  factory DesktopApplicationItem.iconWithTitle({
    required String entry,
    double? borderRadius,
    void Function()? onPress,
  }) {
    return DesktopApplicationItem._(
      entry: entry,
      showTitle: true,
      borderRadius: borderRadius,
      onPress: onPress,
    );
  }

  @override
  _DesktopApplicationItemState createState() => _DesktopApplicationItemState();
}

class _DesktopApplicationItemState extends State<DesktopApplicationItem> {
  bool _isHovered = false, _isPressed = false;
  double? _width, _height;

  @override
  void initState() {
    super.initState();
    _width = widget.showTitle ? 100 * widget.sizeFactor : 80 * widget.sizeFactor;
    _height = widget.showTitle ? null : 80 * widget.sizeFactor;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hoveredColor = colorScheme.primary.withValues(alpha: 0.08);
    final pressedColor = colorScheme.primary.withValues(alpha: 0.08);

    var iconSize = _width! - (4 * theme.scaling) * 1.25;

    if (iconSize > 60) iconSize = 60;

    final entryProvider = context.watch<DesktopEntryProvider>();

    return FutureBuilder(
      future: entryProvider.getEntries(),
      builder: (context, snapshot) {
        DesktopEntry? entry;
        String title = "null";
        if (snapshot.connectionState == ConnectionState.done
            && snapshot.hasData
            && snapshot.data != null) {
          final data = snapshot.data!;
          entry = data[widget.entry];
          title = entry?.entries[DesktopEntryKey.name.string]?.value ?? "null";
        }

        return SizedBox(
          width: _width,
          height: _height,
          child: RepaintBoundary(
            child: Tooltip(
              tooltip: (_) => TooltipContainer(child: Text(title)),
              child: MouseRegion(
                onEnter: (p0) => setState(() => _isHovered = true),
                onExit: (p0) => setState(() => _isHovered = false),
                child: GestureDetector(
                  onTap: widget.onPress,
                  onTapDown: (p0) => setState(() => _isPressed = true),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _isPressed
                          ? pressedColor
                          : (_isHovered ? hoveredColor : null),
                      borderRadius: BorderRadius.circular(8 * theme.scaling),
                    ),
                    child: Padding(
                      padding: widget.showTitle
                          ? EdgeInsets.symmetric(vertical: 4 * theme.scaling)
                          : EdgeInsets.zero,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 4 * theme.scaling,
                        children: [
                          AnimatedScale(
                            scale: _isPressed ? 0.7 : 1,
                            curve: Curves.easeOut,
                            duration: const Duration(milliseconds: 75),
                            onEnd: () {
                              if (_isPressed) setState(() => _isPressed = false);
                            },
                            child: _buildIcon(
                              entryProvider: entryProvider,
                              entry: entry,
                              width: iconSize,
                              height: iconSize,
                            ),
                          ),
                          if (widget.showTitle) Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                          ).medium(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIcon({
    required DesktopEntryProvider entryProvider,
    DesktopEntry? entry,
    double? width,
    double? height,
  }) {
    Widget fallbackIcon = const FlutterLogo();
    if (entry == null) return fallbackIcon;

    return FutureBuilder(
      future: entryProvider.getIcon(entry),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return fallbackIcon;
        if (!snapshot.hasData || snapshot.data == null) return fallbackIcon;

        return Image.file(snapshot.data!, width: width, height: height);
      },
    );
  }
}