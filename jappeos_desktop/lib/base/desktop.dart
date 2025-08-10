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
  const Desktop({Key? key}) : super(key: key);

  @override
  DesktopState createState() => DesktopState();
}

// TODO: Split parts of desktop into their own widgets.
/// This is the public class for the JappeOS Desktop, the `wmController` object can be accessed for using the windowing system.
///
/// See [WmController] for more information on the windowing system.
class DesktopState extends State<Desktop> {
  static WindowStackController? _wmController;
  static WindowStackController? getWmController() => _wmController;

  /// Whether to render GUI on the desktop or not, if false, only the WM windows will be rendered.
  static bool renderGUI = true;

  late final DesktopMenuController _menuController;

  final shortcuts = <LogicalKeySet, Intent>{
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.tab): const SwitchWindowIntent(),
  };

  final actions = const <Type, Action<Intent>>{};

  @override
  void initState() {
    super.initState();
    _menuController = DesktopMenuController((x) => setState(x ?? () {}));
  }

  @override
  Widget build(BuildContext context) {
    /*TODO: Remove*/ print("DESKTOP REBUILD");

    final contextMenuEntries = [
      const MenuButton(
        leading: Icon(Icons.wallpaper),
        child: Text('Change Wallpaper'),
      ),
      const MenuButton(
        leading: Icon(Icons.display_settings),
        child: Text('Display Settings'),
      ),
    ];

    final windowLayer = _DesktopWindowLayer(onWmController: (p) => _wmController = p);

    Widget buildDock() => DesktopDock(
      hasWindowIntersection: false,
      items: [
        (SvgPicture.asset("resources/images/_icontheme/Default/apps/development-appmaker.svg"), "App Maker", () {}),
        (SvgPicture.asset("resources/images/_icontheme/Default/apps/accessories-calculator.svg"), "Calculator", () {}),
      ],
    );

    Widget buildTopBar() => DesktopTopBar(menuController: _menuController);

    Widget buildLoginScreen(AuthProvider auth) => Positioned.fill(
      child: LoginScreen(usersList: const [ "Joe", "Mama" ], onLogin: (p0, p1) {auth.logIn(); return null;}) // TODO
    );

    List<Widget> buildDesktopLayersUI(BuildContext context, AuthProvider auth) {
      List<Widget> widgets = [
        if (!auth.isLoggedIn)
          buildLoginScreen(auth),
        windowLayer,
        if (auth.isLoggedIn) ... [
          buildDock(),
          buildTopBar(),
        ],
        if (_menuController.getWidget(context) != null)
          _menuController.getWidget(context) as Widget
      ];

      return widgets;
    }

    Widget buildBase() {
      // ignore: curly_braces_in_flow_control_structures
      if (!renderGUI) return windowLayer;
      // ignore: curly_braces_in_flow_control_structures
      else return Scaffold(
        child: ContextMenu(
          items: contextMenuEntries,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(
              image: DecorationImage(
                // The desktop background image.
                image: AssetImage(DSKTP_UI_LAYER_BACKGROUND_WALLPAPER_DIR),
                fit: BoxFit.cover,
              ),
            ),
            child: Shortcuts(
              shortcuts: shortcuts,
              child: Actions(
                actions: actions,
                child: Consumer<AuthProvider>(
                  builder: (context, auth, child) {
                    return Stack(
                      children: buildDesktopLayersUI(context, auth),
                    );
                  }
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Desktop UI.
    return Builder(
      builder: (context) {
        // Capture the original MediaQuery
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          // TODO: Correctly integrate system text scaling by changing scales of icons and other UI elements with text.
          // Scale factor is overridden to 1.0 for the time being.
          data: mediaQuery.copyWith(textScaler: const TextScaler.linear(1.0)),
          child: ShadcnApp(
            title: 'jappeos_desktop',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
		          colorScheme: ColorSchemes.darkBlue(),
		          radius: 0.9,
              surfaceOpacity: 0.65,
	            surfaceBlur: 9,
	          ),
            //customThemeProperties: ShadeCustomThemeProperties(themeMode: ThemeMode.dark, primary: const Color.fromARGB(255, 173, 44, 100), accentifyColors: true),
            home: MultiProvider(
              providers: [
                ListenableProvider<AuthProvider>(create: (_) => AuthProvider()),
              ],
              child: buildBase(),
            ),
          ),
        );
      }
    );
  }
}

/// The layer of the desktop where windows can be moved around.
class _DesktopWindowLayer extends StatefulWidget {
  const _DesktopWindowLayer({Key? key, required this.onWmController}) : super(key: key);

  final void Function(WindowStackController) onWmController;

  @override
  _DesktopWindowLayerState createState() => _DesktopWindowLayerState();
}

class _DesktopWindowLayerState extends State<_DesktopWindowLayer> {
  // Create a new instance of [WmController].
  // TODO: remove
  static WindowStackController? _wmController;

  final GlobalKey<WindowNavigatorHandle> navigatorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _wmController ??= WindowStackController(navigatorKey: navigatorKey);
    widget.onWmController(_wmController!);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: WindowStack(
        wmController: _wmController,
        insets: const EdgeInsets.only(top: DSKTP_UI_LAYER_TOPBAR_HEIGHT),
      ),
    );
  }
}