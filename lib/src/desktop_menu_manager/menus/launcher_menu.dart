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

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:freedesktop_desktop_entry/freedesktop_desktop_entry.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:jappeos_desktop/src/components/desktop_application_item.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../components/desktop_container.dart';
import '../../provider/desktop_entry_provider.dart';
import '../desktop_menu_controller.dart';
import '../desktop_menu_entry.dart';

class LauncherMenuEntry extends DesktopMenuEntry {
  final DesktopMenuController _controller;

  LauncherMenuEntry(this._controller);

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
    return LauncherMenu(controller: _controller);
  }
}

class LauncherMenu extends CenteredDesktopMenu {
  final DesktopMenuController controller;

  LauncherMenu({super.key, required this.controller});

  @override
  _LauncherMenuState createState() => _LauncherMenuState();
}

class _LauncherMenuState extends State<LauncherMenu> {
  static const _columns = 5;
  static const _categories = [
    'All',
    'Multimedia',
    'Development',
    'Education',
    'Games',
    'Graphics',
    'Network',
    'Office',
    'Settings',
    'System',
    'Utilities',
  ];

  late final TextEditingController _controller;
  final ScrollController _scrollController = ScrollController();
  late Future<Map<String, DesktopEntry>> _entriesFuture;
  late List<MapEntry<String, DesktopEntry>> _entries;
  String _query = '';
  Timer? _debounce;
  List<MapEntry<String, DesktopEntry>> _lastResults = [];
  late final FocusNode _searchFocus;
  String? _selectedCategory;
  int _selectedIndex = 0;
  double _tileHeight = 0;

  @override
  void initState() {
    super.initState();

    _searchFocus = FocusNode();
    _controller = TextEditingController();
    _entriesFuture = context.read<DesktopEntryProvider>().getEntries();
    _entries = [];

    _controller.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 150), () {
        setState(() {
          _query = _controller.text.toLowerCase();
          _selectedIndex = 0;
          _selectionChanged();
        });
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Focus(
      canRequestFocus: false,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;

        if (_lastResults.isEmpty) return KeyEventResult.ignored;

        switch (event.logicalKey) {
          case LogicalKeyboardKey.arrowDown:
            setState(() {
              _selectedIndex =
                  (_selectedIndex + _columns).clamp(0, _lastResults.length - 1);
              _selectionChanged();
            });
            return KeyEventResult.handled;

          case LogicalKeyboardKey.arrowUp:
            setState(() {
              _selectedIndex =
                  (_selectedIndex - _columns).clamp(0, _lastResults.length - 1);
              _selectionChanged();
            });
            return KeyEventResult.handled;

          case LogicalKeyboardKey.arrowRight:
            setState(() {
              _selectedIndex =
                  (_selectedIndex + 1).clamp(0, _lastResults.length - 1);
              _selectionChanged();
            });
            return KeyEventResult.handled;

          case LogicalKeyboardKey.arrowLeft:
            setState(() {
              _selectedIndex =
                  (_selectedIndex - 1).clamp(0, _lastResults.length - 1);
              _selectionChanged();
            });
            return KeyEventResult.handled;

          case LogicalKeyboardKey.enter:
            final entry = _lastResults[_selectedIndex].value;
            _onDesktopMenuPressed(entry);
            return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      child: DesktopOverlayContainer(
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
                focusNode: _searchFocus,
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
            _HorizontalChipScroller(items: _buildCategories(theme)),
            Expanded(
              child: FutureBuilder(
                future: _entriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) return const SizedBox.shrink();
                  if (!snapshot.hasData || snapshot.data == null) return const SizedBox.shrink();

                  if (_entries.isEmpty) {
                    _entries = snapshot.data!.entries
                        .where((e) => !e.value.isHidden())
                        .toList();
                  }

                  final results = _searchEntries(_query);
                  _lastResults = results;
                  if (results.isEmpty) {
                    return Center(
                      child: Text('No results'),
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      const crossSpacing = 12.0;
                      const mainSpacing = 12.0;
                      const aspectRatio = 1.0;

                      final gridWidth = constraints.maxWidth;

                      final tileWidth =
                          (gridWidth - (_columns - 1) * crossSpacing) / _columns;

                      _tileHeight = tileWidth / aspectRatio;

                      final results = _searchEntries(_query);
                      _lastResults = results;

                      return GridView.builder(
                        controller: _scrollController,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _columns,
                          crossAxisSpacing: crossSpacing,
                          mainAxisSpacing: mainSpacing,
                          childAspectRatio: aspectRatio,
                        ),
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final e = results[index];

                          final selected = index == _selectedIndex;

                          return DecoratedBox(
                            decoration: selected
                                ? BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.primary,
                                      width: 2,
                                    ),
                                  )
                                : const BoxDecoration(),
                            child: DesktopApplicationItem.iconWithTitle(
                              key: ValueKey(e.key),
                              entry: e.key,
                              onPress: () => _onDesktopMenuPressed(e.value),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCategories(ThemeData theme) {
    return _categories.map((category) {
      final categoryValue = category == 'All' ? null : category;
      final selected = _selectedCategory == categoryValue;

      return Chip(
        style: selected
            ? const ButtonStyle.primary()
            : const ButtonStyle.outline(),
        trailing: selected && categoryValue != null
            ? const Icon(Icons.close)
            : null,
        onPressed: () {
          if (selected) {
            setState(() {
              _selectedCategory = null;
              _selectedIndex = 0;
            });
            return;
          }

          setState(() {
            _selectedCategory = categoryValue;
            _query = '';
            _controller.clear();
            _selectedIndex = 0;
          });
        },
        child: Text(category),
      );
    }).toList();
  }

  void _selectionChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      const columns = 5;
      const mainSpacing = 12.0;

      final row = _selectedIndex ~/ columns;
      final targetOffset = row * (_tileHeight + mainSpacing);

      final position = _scrollController.position;

      final clampedOffset = targetOffset.clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );

      _scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
    });
  }

  void _onDesktopMenuPressed(DesktopEntry entry) {
    context.read<DesktopEntryProvider>().launchDesktopEntry(entry);
    widget.controller.closeMenu();
  }

  bool _entryMatchesCategory(DesktopEntry entry, String category) {
    final categories =
        entry.entries[DesktopEntryKey.categories.string]?.value ?? '';

    return categories
        .split(';')
        .map((e) => e.trim())
        .any((c) => c.toLowerCase() == category.toLowerCase());
  }

  List<MapEntry<String, DesktopEntry>> _searchEntries(String query) {
    Iterable<MapEntry<String, DesktopEntry>> source = _entries;

    if (_selectedCategory != null) {
      source = source.where((e) => _entryMatchesCategory(e.value, _selectedCategory!));
      if (query.isEmpty) {
        final list = source.toList();
        list.sort((a, b) {
          final an = a.value.entries[DesktopEntryKey.name.string]?.value ?? '';
          final bn = b.value.entries[DesktopEntryKey.name.string]?.value ?? '';
          return an.compareTo(bn);
        });
        return list;
      }
    }

    if (query.isEmpty) return source.toList();

    final q = query.toLowerCase();

    final results = source.map((e) {
      final entry = e.value;

      final name = (entry.entries[DesktopEntryKey.name.string]?.value ?? '').toLowerCase();
      final comment = (entry.entries[DesktopEntryKey.comment.string]?.value ?? '').toLowerCase();
      final id = e.key.toLowerCase();

      int score = 0;

      // Exact match
      if (name == q) score += 1000;

      // Prefix match
      if (name.startsWith(q)) score += 600;

      // Word prefix match
      if (name.split(' ').any((w) => w.startsWith(q))) score += 500;

      // Substring match
      if (name.contains(q)) score += 400;

      // Fuzzy fallback
      score += weightedRatio(q, name);
      score += weightedRatio(q, comment) ~/ 2;
      score += weightedRatio(q, id) ~/ 2;

      return (entry: e, score: score);
    }).toList();

    results.sort((a, b) => b.score.compareTo(a.score));

    return results
        .where((r) => r.score > 100)
        .map((r) => r.entry)
        .toList();
  }
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