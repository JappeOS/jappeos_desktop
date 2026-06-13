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
import 'package:freedesktop_desktop_entry/src/entry.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../provider/desktop_entry_provider.dart';

enum DesktopApplicationItemState {
  none,
  open,
  focused,
}

/// A basic widget that has the logo of an app and also the name below.
class DesktopApplicationItem extends StatefulWidget {
  final bool custom;
  final Widget? customChild;
  final String? entry;
  final bool showTitle;
  final DesktopApplicationItemState itemState;
  final double sizeFactor;
  final BorderRadiusGeometry? borderRadius;
  final void Function()? onPressed;
  final void Function()? onPressedSecondary;

  const DesktopApplicationItem._({
    super.key,
    this.custom = false,
    this.customChild,
    this.entry,
    this.showTitle = true,
    this.itemState = DesktopApplicationItemState.none,
    this.sizeFactor = 1.0,
    this.borderRadius,
    this.onPressed,
    this.onPressedSecondary,
  });

  factory DesktopApplicationItem.icon({
    Key? key,
    required String entry,
    DesktopApplicationItemState itemState = DesktopApplicationItemState.none,
    double sizeFactor = 1,
    BorderRadiusGeometry? borderRadius,
    void Function()? onPressed,
    void Function()? onPressedSecondary,
  }) {
    return DesktopApplicationItem._(
      key: key,
      entry: entry,
      showTitle: false,
      itemState: itemState,
      sizeFactor: sizeFactor,
      borderRadius: borderRadius,
      onPressed: onPressed,
      onPressedSecondary: onPressedSecondary,
    );
  }

  factory DesktopApplicationItem.iconWithTitle({
    Key? key,
    required String entry,
    DesktopApplicationItemState itemState = DesktopApplicationItemState.none,
    BorderRadiusGeometry? borderRadius,
    void Function()? onPressed,
    void Function()? onPressedSecondary,
  }) {
    return DesktopApplicationItem._(
      key: key,
      entry: entry,
      showTitle: true,
      itemState: itemState,
      borderRadius: borderRadius,
      onPressed: onPressed,
      onPressedSecondary: onPressedSecondary,
    );
  }

  factory DesktopApplicationItem.custom({
    Key? key,
    required Widget child,
    DesktopApplicationItemState itemState = DesktopApplicationItemState.none,
    double sizeFactor = 1,
    BorderRadiusGeometry? borderRadius,
    void Function()? onPressed,
    void Function()? onPressedSecondary,
  }) {
    return DesktopApplicationItem._(
      key: key,
      custom: true,
      customChild: child,
      showTitle: false,
      itemState: itemState,
      sizeFactor: sizeFactor,
      borderRadius: borderRadius,
      onPressed: onPressed,
      onPressedSecondary: onPressedSecondary,
    );
  }

  @override
  _DesktopApplicationItemState createState() => _DesktopApplicationItemState();
}

class _DesktopApplicationItemState extends State<DesktopApplicationItem> {
  late Future<Map<String, DesktopEntry>> _entriesFuture;
  Future<Widget>? _iconFuture;
  String? _title;
  bool _isHovered = false, _isPressed = false;

  double get _width =>
      widget.showTitle ? 100 * widget.sizeFactor : 80 * widget.sizeFactor;

  double? get _height => widget.showTitle ? null : 80 * widget.sizeFactor;

  @override
  void initState() {
    super.initState();
    _entriesFuture = context.read<DesktopEntryProvider>().getEntries();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    var iconSize = _width - (4 * theme.scaling) * 1.25;
    if (iconSize > 60) iconSize = 60;
    iconSize *= widget.sizeFactor;

    if (widget.custom) {
      return _buildBase(
        iconSize: iconSize,
        onTap: widget.onPressed,
        onSecondaryTap: widget.onPressedSecondary,
        child: widget.customChild,
      );
    }

    return FutureBuilder(
      future: _entriesFuture,
      builder: (context, snapshot) {
        final desktopEntryProvider = context.read<DesktopEntryProvider>();
        DesktopEntry? entry;
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData &&
            snapshot.data != null) {
          final data = snapshot.data!;
          entry = _resolveDesktopEntry(data, widget.entry);
          _title ??=
              entry?.entries[DesktopEntryKey.name.string]?.value ?? "Unknown";
          if (entry != null) {
            _iconFuture ??=
                desktopEntryProvider.getIconWidget(entry, size: iconSize);
          }
        }

        final title = _title ?? "Unknown";

        return _buildBase(
          iconSize: iconSize,
          title: title,
          onTap: widget.onPressed ??
              (entry != null
                  ? () => desktopEntryProvider.launchDesktopEntry(entry!)
                  : null),
          onSecondaryTap: widget.onPressedSecondary,
        );
      },
    );
  }

  // TODO: Move this to a more appropriate place, e.g., DesktopEntryProvider or even a utility file.
  DesktopEntry? _resolveDesktopEntry(
    Map<String, DesktopEntry> entries,
    String? query,
  ) {
    if (query == null || query.isEmpty) {
      return null;
    }
    final direct = entries[query];
    if (direct != null) {
      return direct;
    }
    final withDesktop = entries["$query.desktop"];
    if (withDesktop != null) {
      return withDesktop;
    }

    String normalize(String value) {
      var result = value.trim().toLowerCase();
      if (result.endsWith(".desktop")) {
        result = result.substring(0, result.length - ".desktop".length);
      }
      return result;
    }

    final normalizedQuery = normalize(query);
    for (final candidate in entries.entries) {
      final normalizedKey = normalize(candidate.key);
      if (normalizedKey == normalizedQuery) {
        return candidate.value;
      }
    }
    return null;
  }

  Widget _buildBase({
    required double iconSize,
    String title = "Unknown",
    void Function()? onTap,
    void Function()? onSecondaryTap,
    Widget? child,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hoveredColor = colorScheme.primary.withValues(alpha: 0.08);
    final pressedColor = colorScheme.primary.withValues(alpha: 0.12);
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
              onTap: onTap,
              onTapDown: (p0) => setState(() => _isPressed = true),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
              onSecondaryTap: onSecondaryTap,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _isPressed
                      ? pressedColor
                      : (_isHovered ||
                              widget.itemState ==
                                  DesktopApplicationItemState.focused
                          ? hoveredColor
                          : null),
                  borderRadius: widget.borderRadius ??
                      BorderRadius.circular(8 * theme.scaling),
                ),
                child: Padding(
                  padding: widget.showTitle
                      ? EdgeInsets.symmetric(vertical: 4 * theme.scaling)
                      : EdgeInsets.zero,
                  child: _buildMaybeIndicator(
                    theme: theme,
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
                          child: SizedBox(
                            width: iconSize,
                            height: iconSize,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: child ??
                                  _buildIcon(
                                    width: iconSize,
                                    height: iconSize,
                                  ),
                            ),
                          ),
                        ),
                        if (widget.showTitle)
                          Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                          ).small(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon({
    double? width,
    double? height,
  }) {
    Widget fallbackIcon = SizedBox(
      width: width,
      height: height,
      child: Icon(Icons.settings_applications, size: width),
    );

    return FutureBuilder(
      future: _iconFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return fallbackIcon;
        }
        if (!snapshot.hasData || snapshot.data == null) return fallbackIcon;
        return SizedBox(
          width: width,
          height: height,
          child: snapshot.data!,
        );
      },
    );
  }

  Widget _buildMaybeIndicator({
    required ThemeData theme,
    required Widget child,
  }) {
    if (widget.itemState == DesktopApplicationItemState.none) return child;
    final isExpanded = widget.itemState == DesktopApplicationItemState.focused;
    return Stack(
      alignment: Alignment.center,
      children: [
        child,
        Align(
          alignment: Alignment(0.0, 0.9),
          child: SizedBox(
            width: isExpanded ? 27 * theme.scaling : 4 * theme.scaling,
            height: 4 * theme.scaling,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(theme.radiusLg),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DesktopApplicationContextMenu extends StatefulWidget {
  final String entry;
  final Widget child;
  final void Function()? onQuit;
  final void Function()? onOpenDetails;

  const DesktopApplicationContextMenu({
    super.key, required this.entry,
    required this.child,
    this.onQuit,
    this.onOpenDetails,
  });

  @override
  State<DesktopApplicationContextMenu> createState()
      => _DesktopApplicationContextMenuState();
}

class _DesktopApplicationContextMenuState extends State<DesktopApplicationContextMenu> {
  late Future<Map<String, DesktopEntry>> _entriesFuture;
  Map<String, Map<String, Entry>>? _actions;

  @override
  void initState() {
    super.initState();
    _entriesFuture = context.read<DesktopEntryProvider>().getEntries();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _entriesFuture,
      builder: (context, snapshot) {
        final desktopEntryProvider = context.read<DesktopEntryProvider>();
        DesktopEntry? entry;
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData &&
            snapshot.data != null) {
          final data = snapshot.data!;
          entry = data[widget.entry];
          _actions ??= entry?.actions;
        }

        final actionItems = _actions?.entries.map((action) {
          final name = action.value[DesktopEntryKey.name.string]?.value ?? action.key;
          return MenuButton(
            child: Text(name),
            onPressed: (_) {
              desktopEntryProvider.launchDesktopEntry(entry!, action.key);
            },
          );
        }).toList() ?? [];

        return ContextMenu(
          items: [
            if (actionItems.isNotEmpty) ... [
              ...actionItems,
              const MenuDivider(),
            ],
            if (widget.onOpenDetails != null) ... [
              const MenuButton(
                child: Text('Open Details'),
              ),
            ],
            if (widget.onQuit != null) ... [
              const MenuButton(
                child: Text('Quit'),
              ),
            ],
          ],
          child: widget.child,
        );
      },
    );
  }
}