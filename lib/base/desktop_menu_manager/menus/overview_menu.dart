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

part of jappeos_desktop.base;

class OverviewMenuEntry extends DesktopMenuEntry {
  @override
  String get id => 'overview';

  @override
  DesktopMenuEntryType get type => DesktopMenuEntryType.launcher;

  @override
  String get label => 'Overview';

  @override
  LogicalKeySet? get shortcut => LogicalKeySet(
    LogicalKeyboardKey.superKey,
    LogicalKeyboardKey.tab,
  );

  @override
  List<Widget> buildIcon(BuildContext context) {
    return const [Icon(Icons.menu_open)];
  }

  @override
  DesktopMenu createMenu() {
    return OverviewMenu();
  }
}

class OverviewMenu extends FullscreenDesktopMenu {
  OverviewMenu({Key? key}) : super(key: key);

  @override
  _OpenWindowsMenuState createState() => _OpenWindowsMenuState();
}

class _OpenWindowsMenuState extends State<OverviewMenu> {
  Widget _buildDesktopItem(String title, bool isCurrent, void Function() onPress, void Function() onDelete) {
    return DWindowView(
      title: title,
      isTitleEditable: true,
      isHighlighted: isCurrent,
      onPress: onPress,
      child: (isHovered) => Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: EdgeInsets.all(4 * Theme.of(context).scaling),
          child: AnimatedScale(
            scale: isHovered ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 100),
            child: Tooltip(tooltip: (_) => const Text("Remove Desktop"), child: IconButton.destructive(onPressed: onDelete, icon: const Icon(Icons.delete))),
          ),
        ),
      ),
    );
  }

  Widget _buildWindowItem(String title) {
    Widget btn(bool isHovered, IconData icon, String tooltip) {
      return AnimatedScale(
        scale: isHovered ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 100),
        child: Tooltip(tooltip: (_) => Text(tooltip), child: IconButton.secondary(onPressed: () {}, icon: Icon(icon))),
      );
    }

    return DWindowView(
      title: title,
      height: 300,
      isTitleEditable: false,
      isHighlighted: false,
      onPress: () {},
      child: (isHovered) => Padding(
        padding: EdgeInsets.all(4 * Theme.of(context).scaling),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4 * Theme.of(context).scaling,
          children: [
            btn(isHovered, Icons.flip_to_front, "Bring to Front"),
            btn(isHovered, Icons.close, "Close"),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(4 * Theme.of(context).scaling),
      child: Row(
        children: [
          SurfaceCard(
            padding: EdgeInsets.all(4 * Theme.of(context).scaling),
            borderRadius: BorderRadius.circular(Theme.of(context).radiusMd),
            child: Column(
              spacing: 4 * Theme.of(context).scaling,
              children: [
                const Spacer(),
                _buildDesktopItem("Desktop 1", true, () {}, () {}),
                _buildDesktopItem("Desktop 2", false, () {}, () {}),
                DWindowView(
                  title: "Add Desktop",
                  isTitleEditable: false,
                  onPress: () {},
                  child: (isHovered) => const Center(
                    child: Icon(Icons.add, size: 30),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          SizedBox(width: 4 * Theme.of(context).scaling),
          Expanded(
            child: Center(
              child: Wrap(
                spacing: 8 * Theme.of(context).scaling,
                runSpacing: 8 * Theme.of(context).scaling,
                alignment: WrapAlignment.center,
                children: [
                  _buildWindowItem("My First Window"),
                  _buildWindowItem("My Second Window"),
                  _buildWindowItem("My Third Window"),
                  _buildWindowItem("My Fourth Window"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
