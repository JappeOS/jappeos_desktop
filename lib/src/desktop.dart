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

import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jappeos_desktop_base/jappeos_desktop_base.dart';
import 'package:jdwm_flutter/jdwm_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'components/desktop_widgets.dart';
import 'components/login_screen.dart';
import 'constants.dart';
import 'desktop_actions.dart';
import 'desktop_menu_manager/desktop_menu_controller.dart';
import 'desktop_menu_manager/desktop_menu_registry.dart';
import 'desktop_menu_manager/menus/launcher_menu.dart';
import 'desktop_menu_manager/menus/notification_menu.dart';
import 'desktop_menu_manager/menus/overview_menu.dart';
import 'desktop_menu_manager/menus/quick_settings_menu/quick_settings_menu_entry.dart';
import 'provider/auth_provider.dart';

/// The stateful widget for the base desktop UI.
class Desktop extends StatefulWidget {
  const Desktop({super.key});

  @override
  DesktopState createState() => DesktopState();
}

/// This is the public class for the JappeOS Desktop,
/// the `wmController` object can be accessed for using the windowing system.
///
/// See [WmController] for more information on the windowing system.
class DesktopState extends State<Desktop> {
  static final GlobalKey<WindowManagerState> _wmControllerKey
      = GlobalKey<WindowManagerState>();
  static WindowManagerState? getWmController()
      => _wmControllerKey.currentState;

  late final DesktopMenuController _menuController;
  final DesktopMenuRegistry _menuRegistry = DesktopMenuRegistry();
  late final GlobalKeybindService _keybinds;

  final _shortcuts = <LogicalKeySet, Intent>{
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.tab):
        const SwitchWindowIntent(),
  };

  final _actions = const <Type, Action<Intent>>{};

  final List<MonitorConfig> _monitors = [
    //const MonitorConfig(id: "a", bounds: Rect.fromLTWH(0,    0, 1920, 1080), margin: EdgeInsets.only(top: DSKTP_UI_LAYER_TOPBAR_HEIGHT)),
    //const MonitorConfig(id: "b", bounds: Rect.fromLTWH(1920, 0, 1920, 1080)),
    //const MonitorConfig(id: "c", bounds: Rect.fromLTWH(0,   540, 960, 540)),
  ];

  @override
  void initState() {
    super.initState();
    _menuController = DesktopMenuController((x) => setState(x ?? () {}));
    _menuRegistry.register(LauncherMenuEntry());
    _menuRegistry.register(OverviewMenuEntry());
    _menuRegistry.register(QuickSettingsMenuEntry());
    _menuRegistry.register(NotificationMenuEntry());
    _keybinds = GlobalKeybindService();
  }

  @override
  void dispose() {
    _keybinds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShellApp(
      title: 'jappeos_desktop',
      debugShowCheckedModeBanner: false,
      wmKey: _wmControllerKey,
      providers: [
        ListenableProvider<AuthProvider>(create: (_) => AuthProvider()),
        ListenableProvider<ThemeProvider>(create: (_) => ThemeProvider()),
      ],
      theme: _getTheme(false),
      darkTheme: _getTheme(true),
      shortcuts: _shortcuts,
      actions: _actions,
      keybinds: _keybinds,
      dynamicMonitorInsets: const EdgeInsets.only(top: DSKTP_UI_LAYER_TOPBAR_HEIGHT),
      monitors: _monitors,
      monitorBuilder: (context, monitor) => Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (!auth.isLoggedIn) {
            return _buildLoginScreen(auth); // TODO: Handle multiple monitors
          }
          return ContextMenu(
            items: _buildContextMenuItems(),
            child: Container(
              width: monitor.bounds.width.toDouble(),
              height: monitor.bounds.height.toDouble(),
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
      monitorOverlayBuilder: (context, monitor) =>
        _monitors.isEmpty || _monitors.first == monitor
            ? Consumer<AuthProvider>(
        builder: (context, auth, _) => Stack(
          children: _buildDesktopOverlayLayers(context, auth, monitor),
        ),
      ) : const SizedBox.shrink(),
    );
  }

  ThemeData _getTheme(bool dark) => ThemeData(
    colorScheme: dark
        ? ColorSchemes.darkDefaultColor
        : ColorSchemes.lightDefaultColor,
    radius: 0.9,
    surfaceOpacity: 0.85,
    surfaceBlur: 9,
  );

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

  List<Widget> _buildDesktopOverlayLayers(
    BuildContext context,
    AuthProvider auth,
    MonitorConfig monitor,
  ) {
    final dmenuWidget = _menuController.getWidget(context, monitor);
    return [
      if (auth.isLoggedIn) ...[
        _buildDock(),
        _buildTopBar(),
      ],
      if (dmenuWidget != null)
        dmenuWidget,
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
    return DesktopTopBarNew(
      registry: _menuRegistry,
      menuController: _menuController,
    );
  }
}