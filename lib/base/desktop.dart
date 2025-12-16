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

// ignore_for_file: constant_identifier_names, non_constant_identifier_names

part of jappeos_desktop.base;

/// The stateful widget for the base desktop UI.
class Desktop extends StatefulWidget {
  const Desktop({super.key});

  @override
  DesktopState createState() => DesktopState();
}

/// This is the public class for the JappeOS Desktop, the `wmController` object can be accessed for using the windowing system.
///
/// See [WmController] for more information on the windowing system.
class DesktopState extends State<Desktop> {
  static WindowStackController? _wmController;
  static WindowStackController? getWmController() => _wmController;

  /// Whether to render GUI on the desktop or not, if false, only the WM windows will be rendered.
  static bool renderGUI = true;

  late final DesktopMenuController _menuController;

  final _shortcuts = <LogicalKeySet, Intent>{
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.tab):
        const SwitchWindowIntent(),
  };

  final _actions = const <Type, Action<Intent>>{};

  @override
  void initState() {
    super.initState();
    _menuController = DesktopMenuController((x) => setState(x ?? () {}));
  }

  @override
  Widget build(BuildContext context) {
    // TODO
    //if (!renderGUI) {
    //  return _DesktopWindowLayer(onWmController: (p) => _wmController = p);
    //}

    return _buildFullDesktop(context);
  }

  Widget _buildFullDesktop(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return MediaQuery(
      // TODO: Correctly integrate system text scaling by changing scales of icons and other UI elements with text.
      data: mediaQuery.copyWith(textScaler: const TextScaler.linear(1.0)),
      child: ShadcnApp(
        title: 'jappeos_desktop',
        debugShowCheckedModeBanner: false,
        theme: const ThemeData(
          colorScheme: ColorSchemes.darkOrange,
          radius: 0.9,
          surfaceOpacity: 0.85,
          surfaceBlur: 9,
        ),
        home: MultiProvider(
          providers: [
            ListenableProvider<AuthProvider>(create: (_) => AuthProvider()),
          ],
          child: _DesktopScaffoldNew(
            menuController: _menuController,
            shortcuts: _shortcuts,
            actions: _actions,
            onWmController: (p) => _wmController = p,
          ),
        ),
      ),
    );
  }
}

class _DesktopScaffoldNew extends StatefulWidget {
  final DesktopMenuController menuController;
  final Map<LogicalKeySet, Intent> shortcuts;
  final Map<Type, Action<Intent>> actions;
  final void Function(WindowStackController) onWmController;

  const _DesktopScaffoldNew({
    required this.menuController,
    required this.shortcuts,
    required this.actions,
    required this.onWmController,
  });

  @override
  _DesktopScaffoldNewState createState() => _DesktopScaffoldNewState();
}

/// Internal scaffold widget for the desktop UI
class _DesktopScaffoldNewState extends State<_DesktopScaffoldNew> {
  late final WindowStackController _wmController;

  @override
  void initState() {
    super.initState();
    _wmController = WindowStackController();
    widget.onWmController(_wmController);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      child: Shortcuts(
        shortcuts: widget.shortcuts,
        child: Actions(
          actions: widget.actions,
          child: DesktopBase(
            wmConfig: WmConfig(
              dynamicMonitorInsets: const EdgeInsets.only(top: DSKTP_UI_LAYER_TOPBAR_HEIGHT),
              wmController: _wmController,
            ),
            monitorConfig: MonitorConfig(
              monitors: [
                Monitor(id: "a", name: "First Monitor",  x: 0,   y: 0,   width: 960, height: 540, insets: const EdgeInsets.only(top: DSKTP_UI_LAYER_TOPBAR_HEIGHT), isPrimary: true),
                Monitor(id: "b", name: "Second Monitor", x: 960, y: 0,   width: 960, height: 540,                                                                   isPrimary: false),
                Monitor(id: "c", name: "Third Monitor",  x: 0,   y: 540, width: 960, height: 540,                                                                   isPrimary: false),
              ],
            ),
            monitorBuilder: (context, monitor) => Consumer<AuthProvider>(
              builder: (context, auth, _) {
                if (!auth.isLoggedIn) {
                  return _buildLoginScreen(auth); // TODO: Handle multiple monitors
                }
                return ContextMenu(
                  items: _buildContextMenuItems(),
                  child: Container(
                    width: monitor.width.toDouble(),
                    height: monitor.height.toDouble(),
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(DSKTP_UI_LAYER_BACKGROUND_WALLPAPER_DIR),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
            monitorOverlayBuilder: (context, monitor) => monitor.isPrimary ? Consumer<AuthProvider>(
              builder: (context, auth, _) => Stack(
                children: _buildDesktopOverlayLayers(context, auth),
              ),
            ) : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  List<MenuItem> _buildContextMenuItems() {
    return [
      const MenuButton(
        leading: Icon(Icons.wallpaper),
        child: Text('Change Wallpaper'),
      ),
      const MenuButton(
        leading: Icon(Icons.display_settings),
        child: Text('Display Settings'),
      ),
    ];
  }

  List<Widget> _buildDesktopOverlayLayers(BuildContext context, AuthProvider auth) {
    return [
      if (auth.isLoggedIn) ...[
        _buildDock(),
        _buildTopBar(),
      ],
      if (widget.menuController.getWidget(context) != null)
        widget.menuController.getWidget(context)!,
    ];
  }

  Widget _buildLoginScreen(AuthProvider auth) {
    return Positioned.fill(
      child: LoginScreen(
        usersList: const ["Joe", "Mama"], // TODO
        onLogin: (p0, p1) {
          auth.logIn();
          return null;
        },
      ),
    );
  }

  Widget _buildDock() {
    return DesktopDock(
      hasWindowIntersection: false,
      items: [
        (
          SvgPicture.asset(
            "resources/images/_icontheme/Default/apps/development-appmaker.svg"
          ),
          "App Maker",
          () {}
        ),
        (
          SvgPicture.asset(
            "resources/images/_icontheme/Default/apps/accessories-calculator.svg"
          ),
          "Calculator",
          () {}
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return DesktopTopBar(menuController: widget.menuController);
  }
}