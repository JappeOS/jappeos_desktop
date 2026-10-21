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
import 'package:jappeos_desktop_base/jappeos_desktop_base.dart';
import 'package:jdwm/jdwm.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'components/desktop_dock.dart';
import 'components/desktop_notifications.dart';
import 'components/desktop_top_bar.dart';
import 'components/login_screen.dart';
import 'constants.dart';
import 'desktop_actions.dart';
import 'desktop_keybinds.dart';
import 'desktop_menu_manager/desktop_menu_controller.dart';
import 'desktop_menu_manager/desktop_menu_registry.dart';
import 'desktop_menu_manager/menus/launcher_menu.dart';
import 'desktop_menu_manager/menus/notification_menu.dart';
import 'desktop_menu_manager/menus/overview_menu.dart';
import 'desktop_menu_manager/menus/quick_settings_menu/quick_settings_menu_entry.dart';
import 'desktop_menu_manager/menus/switcher_menu.dart';
import 'desktop_overlay_manager/desktop_osd_layer.dart';
import 'desktop_overlay_manager/overlays/audio_input_overlay.dart';
import 'desktop_overlay_manager/overlays/audio_output_overlay.dart';
import 'lifecycle_handler.dart';
import 'provider/auth_provider.dart';
import 'provider/desktop_entry_provider.dart';
import 'provider/gpu_info_provider.dart';

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
  static final GlobalKey<WindowManagerState> _wmControllerKey =
      GlobalKey<WindowManagerState>();
  static WindowManagerState? getWmController() => _wmControllerKey.currentState;

  late final DesktopMenuController _menuController;
  final DesktopMenuRegistry _menuRegistry = DesktopMenuRegistry();
  late final GlobalKeybindService _keybinds;

  final _shortcuts = <LogicalKeySet, Intent>{
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.tab):
        const SwitchWindowIntent(),
  };

  final _actions = const <Type, Action<Intent>>{};

  final _overlays = <Widget>[
    AudioInputOverlay(),
    AudioOutputOverlay(),
  ];

  @override
  void initState() {
    super.initState();
    _menuController = DesktopMenuController();
    _menuRegistry.register(LauncherMenuEntry(_menuController));
    _menuRegistry.register(OverviewMenuEntry());
    _menuRegistry.register(QuickSettingsMenuEntry());
    _menuRegistry.register(NotificationMenuEntry());
    _menuRegistry.register(SwitcherMenuEntry());
    _keybinds = GlobalKeybindService();
  }

  @override
  void dispose() {
    _keybinds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ApplicationLifecycleObserver(
      child: ShellApp(
        title: 'jappeos_desktop',
        debugShowCheckedModeBanner: false,
        wmKey: _wmControllerKey,
        providers: [
          ListenableProvider<AuthProvider>(create: (_) => AuthProvider()),
          ListenableProvider<DesktopEntryProvider>(
            create: (_) => DesktopEntryProvider(),
            lazy: false,
          ),
          ListenableProvider(
            create: (_) => GpuInfoProvider(),
            lazy: false,
          ),
        ],
        theme: _getTheme(false),
        darkTheme: _getTheme(true),
        shortcuts: _shortcuts,
        actions: _actions,
        keybinds: _keybinds,
        wrapBuilder: (_, p1) => DesktopKeybinds(
          registry: _menuRegistry,
          menuController: _menuController,
          child: p1,
        ),
        monitorLayoutBuilder: (p0, p1) {
          for (int i = 0; i < p1.length; i++) {
            final p = p1[i];
            if (p.isPrimary) {
              p1[i] = p.copyWith(
                margin: const EdgeInsets.only(top: DSKTP_UI_LAYER_TOPBAR_HEIGHT),
              );
              break;
            }
          }
          return p1;
        },
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
        monitorOverlayBuilder: (context, monitor) => monitor.isPrimary
            ? Consumer<AuthProvider>(
                builder: (context, auth, _) => Stack(
                  children: _buildDesktopOverlayLayers(context, auth, monitor),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  ThemeData _getTheme(bool dark) {
    final surfaceOpacity = 0.6;
    return ThemeData(
      colorScheme: dark
          ? _getDarkDefaultColor(surfaceOpacity)
          : _getLightDefaultColor(surfaceOpacity),
      radius: 0.9,
      surfaceOpacity: surfaceOpacity,
      surfaceBlur: 30,
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

  List<Widget> _buildDesktopOverlayLayers(
    BuildContext context,
    AuthProvider auth,
    MonitorConfig monitor,
  ) {
    return [
      if (auth.isLoggedIn) ...[
        _buildDock(),
        _buildTopBar(),
      ],
      DesktopNotificationArea(),
      Positioned.fill(
        top: DSKTP_UI_LAYER_TOPBAR_HEIGHT,
        child: DesktopMenuWidget(
          controller: _menuController,
          monitor: monitor,
        ),
      ),
      DesktopOsdLayer(overlays: _overlays),
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
      registry: _menuRegistry,
      menuController: _menuController,
    );
  }

  Widget _buildTopBar() {
    return DesktopTopBarNew(
      registry: _menuRegistry,
      menuController: _menuController,
    );
  }

  /// Light defaultcolor color scheme.
  static ColorScheme _getLightDefaultColor(double surfaceOpacity) {
    final bgColor = Color(0xFFFFFFFF);
    return ColorScheme(
      brightness: Brightness.light,
      background: bgColor,
      foreground: Color(0xFF0A0A0A),
      card: Color(0xFFFFFFFF),
      cardForeground: Color(0xFF0A0A0A),
      popover: Color(0xFFFFFFFF),
      popoverForeground: Color(0xFF0A0A0A),
      primary: Color(0xFF171717),
      primaryForeground: Color(0xFFFAFAFA),
      secondary: _calculateTransparentColorClamped(
        bgColor: bgColor,
        bgSecondaryColor: Color(0xFFF5F5F5),
        surfaceOpacity: surfaceOpacity,
      ),
      secondaryForeground: Color(0xFF171717),
      muted: _calculateTransparentColorClamped(
        bgColor: bgColor,
        bgSecondaryColor: Color(0xFFF5F5F5),
        surfaceOpacity: surfaceOpacity,
      ),
      mutedForeground: Color(0xFF737373),
      accent: _calculateTransparentColorClamped(
        bgColor: bgColor,
        bgSecondaryColor: Color(0xFFF5F5F5),
        surfaceOpacity: surfaceOpacity,
      ),
      accentForeground: Color(0xFF171717),
      destructive: Color(0xFFE7000B),
      border: Color(0xFFE5E5E5),
      input: Color(0xFFE5E5E5),
      ring: Color(0xFFA1A1A1),
      chart1: Color(0xFFF54900),
      chart2: Color(0xFF009689),
      chart3: Color(0xFF104E64),
      chart4: Color(0xFFFFB900),
      chart5: Color(0xFFFE9A00),
      sidebar: _calculateTransparentColorClamped(
        bgColor: bgColor,
        bgSecondaryColor: Color(0xFFFAFAFA),
        surfaceOpacity: surfaceOpacity,
      ),
      sidebarForeground: Color(0xFF0A0A0A),
      sidebarPrimary: Color(0xFF171717),
      sidebarPrimaryForeground: Color(0xFFFAFAFA),
      sidebarAccent: Color(0xFFF5F5F5),
      sidebarAccentForeground: Color(0xFF171717),
      sidebarBorder: Color(0xFFE5E5E5),
      sidebarRing: Color(0xFFA1A1A1),
    );
  }

  /// Dark defaultcolor color scheme.
  static ColorScheme _getDarkDefaultColor(double surfaceOpacity) {
    final bgColor = Color(0xFF0A0A0A);
    return ColorScheme(
      brightness: Brightness.dark,
      background: bgColor,
      foreground: Color(0xFFFAFAFA),
      card: Color(0xFF171717),
      cardForeground: Color(0xFFFAFAFA),
      popover: Color(0xFF171717),
      popoverForeground: Color(0xFFFAFAFA),
      primary: Color(0xFFE5E5E5),
      primaryForeground: Color(0xFF171717),
      secondary: _calculateTransparentColorClamped(
        bgColor: bgColor,
        bgSecondaryColor: Color(0xFF262626),
        surfaceOpacity: surfaceOpacity,
      ),
      secondaryForeground: Color(0xFFFAFAFA),
      muted: _calculateTransparentColorClamped(
        bgColor: bgColor,
        bgSecondaryColor: Color(0xFF262626),
        surfaceOpacity: surfaceOpacity,
      ),
      mutedForeground: Color(0xFFA1A1A1),
      accent: _calculateTransparentColorClamped(
        bgColor: bgColor,
        bgSecondaryColor: Color(0xFF262626),
        surfaceOpacity: surfaceOpacity,
      ),
      accentForeground: Color(0xFFFAFAFA),
      destructive: Color(0xFFFF6467),
      border: Color(0x1AFFFFFF),
      input: Color(0x26FFFFFF),
      ring: Color(0xFF737373),
      chart1: Color(0xFF1447E6),
      chart2: Color(0xFF00BC7D),
      chart3: Color(0xFFFE9A00),
      chart4: Color(0xFFAD46FF),
      chart5: Color(0xFFFF2056),
      sidebar: _calculateTransparentColorClamped(
        bgColor: bgColor,
        bgSecondaryColor: Color(0xFF171717),
        surfaceOpacity: surfaceOpacity,
      ),
      sidebarForeground: Color(0xFFFAFAFA),
      sidebarPrimary: Color(0xFF1447E6),
      sidebarPrimaryForeground: Color(0xFFFAFAFA),
      sidebarAccent: Color(0xFF262626),
      sidebarAccentForeground: Color(0xFFFAFAFA),
      sidebarBorder: Color(0x1AFFFFFF),
      sidebarRing: Color(0xFF737373),
    );
  }

  static Color _calculateTransparentColorClamped({
    required Color bgColor,
    required Color bgSecondaryColor,
    required double surfaceOpacity,
  }) {
    if (surfaceOpacity < 0.0 || surfaceOpacity > 1.0) {
      throw ArgumentError.value(
        surfaceOpacity,
        'surfaceOpacity',
        'Must be between 0.0 and 1.0.',
      );
    }

    // Flutter's Color.fromARGB uses an 8-bit alpha channel.
    final alphaByte = (surfaceOpacity * 255).round();
    final alpha = alphaByte / 255.0;

    // At zero opacity, the overlay cannot change the background.
    if (alphaByte == 0) {
      if (bgColor == bgSecondaryColor) {
        return Color.fromARGB(
          0,
          (bgSecondaryColor.r * 255.0).round() & 0xff,
          (bgSecondaryColor.g * 255.0).round() & 0xff,
          (bgSecondaryColor.b * 255.0).round() & 0xff,
        );
      }

      return Colors.transparent;
    }

    int adjustChannel(int background, int target) {
      // C_overlay = C_background + (C_target - C_background) / alpha
      final adjusted = background + (target - background) / alpha;
      return adjusted.clamp(0, 255).round();
    }

    final red = adjustChannel((bgSecondaryColor.r * 255.0).round() & 0xff, (bgColor.r * 255.0).round() & 0xff);
    final green = adjustChannel((bgSecondaryColor.g * 255.0).round() & 0xff, (bgColor.g * 255.0).round() & 0xff);
    final blue = adjustChannel((bgSecondaryColor.b * 255.0).round() & 0xff, (bgColor.b * 255.0).round() & 0xff);
    return Color.fromARGB(alphaByte, red, green, blue);
  }
}
