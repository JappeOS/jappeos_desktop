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
import 'package:flutter_svg/svg.dart';
import 'package:jdwm_flutter/jdwm_flutter.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../components/desktop_widgets.dart';
import '../../desktop.dart';
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
  LauncherMenu({Key? key}) : super(key: key);

  @override
  _LauncherMenuState createState() => _LauncherMenuState();
}

class _LauncherMenuState extends State<LauncherMenu> {
  final PageController _pageController = PageController();
  int _pageCount = 1;

  @override
  Widget build(BuildContext context) {
    final defaultPadding = 8 * Theme.of(context).scaling;

    Widget horizontalIndicatorCircleBar(int count, int active) {
      List<Widget> circles = [];

      for (int i = 0; i < count; i++) {
        circles.add(Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: i == active ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.foreground,
            borderRadius: BorderRadius.circular(2.5),
          ),
        ));

        if (count != i) {
          circles.add(const SizedBox(
            height: 10,
          ));
        }
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: circles,
      );
    }

    return DOverlayContainer(
      width: 500,
      height: 400,
      child: Column(
        children: [
          SizedBox(
              width: double.infinity,
              child: Container(
                  margin: EdgeInsets.all(defaultPadding),
                  child: const TextField(
                    features: [InputFeature.leading(Icon(Icons.search))],
                    hintText: "Search Files, Apps & More",
                    autofocus: true,
                  ))),
          Expanded(
            child: Container(
              margin: EdgeInsets.all(defaultPadding),
              child: Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      scrollDirection: Axis.vertical,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                DApplicationItem.iconWithTitle(
                                    image: SvgPicture.asset("resources/images/_icontheme/Default/apps/utilities-terminal.svg"),
                                    title: "Terminal",
                                    onPress: () {
                                      DesktopState.getWmController()!.pushWindow(
                                        WindowEntry(
                                          icon: const NetworkImage(
                                            "https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcR1HDcyXu9SHC4glO2kFKjVhcy9kU6Q1S9T2g&usqp=CAU",
                                          ),
                                          title: "Example",
                                          content: const Placeholder(),
                                        ),
                                      );
                                        /*..setResizable(true)
                                        ..setMinSize(Vector2(300, 300))
                                        ..setSize(Vector2(300, 300))
                                        ..setTitle("Window Title")
                                        ..setBgRenderMode(BackgroundMode.blurredTransp);*/
                                    }),
                                DApplicationItem.iconWithTitle(
                                    image: SvgPicture.asset("resources/images/_icontheme/Default/apps/system-settings.svg"),
                                    title: "Settings",
                                    onPress: () /*=> Settings.new().app$launch()*/ {}),
                                DApplicationItem.iconWithTitle(
                                    image: SvgPicture.asset("resources/images/_icontheme/Default/apps/utilities-terminal.svg"),
                                    title: "Terminal",
                                    onPress: () {}),
                                DApplicationItem.iconWithTitle(
                                    image: SvgPicture.asset("resources/images/_icontheme/Default/apps/utilities-terminal.svg"),
                                    title: "Terminal",
                                    onPress: () {}),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                DApplicationItem.iconWithTitle(
                                    image: SvgPicture.asset("resources/images/_icontheme/Default/apps/utilities-terminal.svg"),
                                    title: "Terminal",
                                    onPress: () {}),
                                DApplicationItem.iconWithTitle(
                                    image: SvgPicture.asset("resources/images/_icontheme/Default/apps/utilities-terminal.svg"),
                                    title: "Terminal",
                                    onPress: () {}),
                                DApplicationItem.iconWithTitle(
                                    image: SvgPicture.asset("resources/images/_icontheme/Default/apps/utilities-terminal.svg"),
                                    title: "Terminal",
                                    onPress: () {}),
                                DApplicationItem.iconWithTitle(
                                    image: SvgPicture.asset("resources/images/_icontheme/Default/apps/utilities-terminal.svg"),
                                    title: "Terminal",
                                    onPress: () {}),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                DApplicationItem.iconWithTitle(
                                    image: SvgPicture.asset("resources/images/_icontheme/Default/apps/utilities-terminal.svg"),
                                    title: "Terminal",
                                    onPress: () {}),
                                DApplicationItem.iconWithTitle(
                                    image: SvgPicture.asset("resources/images/_icontheme/Default/apps/utilities-terminal.svg"),
                                    title: "Terminal",
                                    onPress: () {}),
                                DApplicationItem.iconWithTitle(
                                    image: SvgPicture.asset("resources/images/_icontheme/Default/apps/utilities-terminal.svg"),
                                    title: "Terminal",
                                    onPress: () {}),
                                DApplicationItem.iconWithTitle(
                                    image: SvgPicture.asset("resources/images/_icontheme/Default/apps/utilities-terminal.svg"),
                                    title: "Terminal",
                                    onPress: () {}),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: defaultPadding,
                  ),
                  horizontalIndicatorCircleBar(_pageCount, 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
