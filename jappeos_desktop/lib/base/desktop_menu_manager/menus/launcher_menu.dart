//  JappeOS-Desktop, The desktop environment for JappeOS.
//  Copyright (C) 2025  Jappe02
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

class LauncherMenu extends DesktopMenu {
  LauncherMenu({Key? key}) : super(key: key);

  @override
  _LauncherMenuState createState() => _LauncherMenuState();
}

class _LauncherMenuState extends State<LauncherMenu> {
  final PageController _pageController = PageController();
  int _pageCount = 1;

  @override
  Widget build(BuildContext context) {
    final defaultPadding = 4 * Theme.of(context).scaling;

    Widget verticalIndicatorCircleBar(int count, int active) {
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

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: circles,
      );
    }

    return DOverlayContainer(
      width: 500,
      height: 500,
      child: Column(
        children: [
          SizedBox(
              width: double.infinity,
              child: Container(
                  margin: EdgeInsets.all(defaultPadding),
                  child: OutlineButton(onPressed: () {}, child: const Text("Search Files, Apps & More")))),
          Expanded(
            child: Container(
              margin: EdgeInsets.all(defaultPadding),
              child: Row(
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
                                      DesktopState.getWmController()!.createWindow();
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
                    width: defaultPadding,
                  ),
                  verticalIndicatorCircleBar(_pageCount, 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
