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

import 'package:flutter/services.dart';
import 'package:freedesktop_desktop_entry/freedesktop_desktop_entry.dart';
import 'package:jappeos_desktop/src/components/desktop_application_item.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../components/desktop_container.dart';
import '../../provider/desktop_entry_provider.dart';
import '../desktop_menu_controller.dart';
import '../desktop_menu_entry.dart';

class LauncherMenuEntry extends DesktopMenuEntry {
  @override
  String get id => 'launcher';

  @override
  DesktopMenuEntryType get type => DesktopMenuEntryType.launcher;

  @override
  String get label => 'Launcher';

  @override
  LogicalKeySet? get shortcut => LogicalKeySet(
    LogicalKeyboardKey.superKey,
  );

  @override
  List<Widget> buildIcon(BuildContext context) {
    return const [Icon(Icons.apps)];
  }

  @override
  DesktopMenu createMenu() {
    return LauncherMenu();
  }
}

class LauncherMenu extends CenteredDesktopMenu {
  LauncherMenu({super.key});

  @override
  _LauncherMenuState createState() => _LauncherMenuState();
}

class _LauncherMenuState extends State<LauncherMenu> {
  late final TextEditingController _controller;
  late Future<Map<String, DesktopEntry>> _entriesFuture;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _entriesFuture = context.read<DesktopEntryProvider>().getEntries();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DesktopOverlayContainer(
      width: 620,
      height: 575,
      padding: EdgeInsets.all(16 * theme.scaling),
      child: Column(
        spacing: 8 * theme.scaling,
        children: [
          ComponentTheme(
            data: FocusOutlineTheme(
              border: Border(),
            ),
            child: TextField(
              controller: _controller,
              features: [InputFeature.leading(Icon(Icons.search))],
              keyboardType: TextInputType.text,
              placeholder: Text('Search Files, Apps & More'),
              autofocus: true,
              filled: false,
              decoration: BoxDecoration(
                border: null,
                color: Colors.transparent,
                borderRadius: BorderRadius.zero,
              ),
              border: null,
              padding: EdgeInsets.all(2 * theme.scaling),
            ),
          ),
          Divider(),
          _HorizontalChipScroller(items: _buildCategrories(theme)),
          Expanded(
            child: FutureBuilder(
              future: _entriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) return const SizedBox.shrink();
                if (!snapshot.hasData || snapshot.data == null) return const SizedBox.shrink();

                final data = snapshot.data!;
                List<Widget> items = [];
                data.forEach((id, entry) {
                  if (entry.isHidden()) return;
                  items.add(DesktopApplicationItem.iconWithTitle(entry: id));
                });
                return GridView(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  children: items,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCategrories(ThemeData theme) => [
    Chip(
      style: const ButtonStyle.outline(),
      child: const Text('Multimedia'),
    ),
    Chip(
      style: const ButtonStyle.outline(),
      child: const Text('Development'),
    ),
    Chip(
      style: const ButtonStyle.outline(),
      child: const Text('Education'),
    ),
    Chip(
      style: const ButtonStyle.outline(),
      child: const Text('Games'),
    ),
    Chip(
      style: const ButtonStyle.outline(),
      child: const Text('Graphics'),
    ),
    Chip(
      style: const ButtonStyle.outline(),
      child: const Text('Network'),
    ),
    Chip(
      style: const ButtonStyle.outline(),
      child: const Text('Office'),
    ),
    Chip(
      style: const ButtonStyle.outline(),
      child: const Text('Settings'),
    ),
    Chip(
      style: const ButtonStyle.outline(),
      child: const Text('System'),
    ),
    Chip(
      style: const ButtonStyle.outline(),
      child: const Text('Utilities'),
    ),
  ];
}

class _HorizontalChipScroller extends StatefulWidget {
  final List<Widget> items;

  const _HorizontalChipScroller({super.key, required this.items});

  @override
  State<_HorizontalChipScroller> createState() =>
      _HorizontalChipScrollerState();
}

class _HorizontalChipScrollerState extends State<_HorizontalChipScroller> {
  final ScrollController _controller = ScrollController();

  bool _showLeft = false;
  bool _showRight = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateState);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateState());
  }

  void _updateState() {
    if (!_controller.hasClients) return;

    final max = _controller.position.maxScrollExtent;
    final offset = _controller.offset;

    setState(() {
      _showLeft = offset > 0;
      _showRight = offset < max;
    });
  }

  void _scrollBy(double amount) {
    _controller.animateTo(
      (_controller.offset + amount)
          .clamp(0.0, _controller.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      alignment: Alignment.center,
      children: [
        // Fade mask
        ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                _showLeft ? Colors.transparent : Colors.black,
                Colors.black,
                Colors.black,
                _showRight ? Colors.transparent : Colors.black,
              ],
              stops: const [0.0, 0.1, 0.9, 1.0],
            ).createShader(rect);
          },
          blendMode: BlendMode.dstIn,
          child: SingleChildScrollView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8 * theme.scaling,
              children: widget.items,
            ),
          ),
        ),

        // Left Button
        if (_showLeft)
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton.link(
              icon: Icon(Icons.chevron_left),
              density: ButtonDensity.dense,
              onPressed: () => _scrollBy(-200),
            ),
          ),

        // Right Button
        if (_showRight)
          Align(
            alignment: Alignment.centerRight,
            child: IconButton.link(
              icon: Icon(Icons.chevron_right),
              density: ButtonDensity.dense,
              onPressed: () => _scrollBy(200),
            ),
          ),
      ],
    );
  }
}