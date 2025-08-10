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

library;

import 'package:jappeos_desktop/base/base.dart';
import 'package:shade_ui/shade_ui.dart';

part 'control_center_wifi_page.dart';

class ControlCenterMenu extends DesktopMenu {
  ControlCenterMenu({Key? key}) : super(key: key);

  @override
  _ControlCenterMenuState createState() => _ControlCenterMenuState();
}

class _ControlCenterMenuState extends State<ControlCenterMenu> {
  final GlobalKey<NavigatorState> _containerNavigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return DOverlayContainer(
      width: 400,
      child: Navigator(
        key: _containerNavigatorKey,
        onGenerateRoute: (RouteSettings settings) {
          builder(BuildContext _) => const _ControlCenterMainPage();
          return MaterialPageRoute(builder: builder, settings: settings);
        },
      ),
    );
  }
}

class _QuickActionItem extends StatefulWidget {
  final String text;
  final IconData icon;
  final bool isSelected;
  final void Function(bool)? onSelectionChange;
  final void Function()? onAdditionalDetailsButtonPressed;

  const _QuickActionItem(
      {required this.text, required this.icon, required this.isSelected, this.onSelectionChange, this.onAdditionalDetailsButtonPressed});

  @override
  _QuickActionItemState createState() => _QuickActionItemState();
}

class _QuickActionItemState extends State<_QuickActionItem> {
  @override
  Widget build(BuildContext context) {
    //final foregroundColor = widget.isSelected ? Theme.of(context).colorScheme.foreground : null;

    return SecondaryButton(
        onPressed: () => widget.onSelectionChange?.call(widget.isSelected),
        /*style: ButtonStyle(
          backgroundColor: widget.isSelected ? WidgetStatePropertyAll(Theme.of(context).colorScheme.primary) : null,
          foregroundColor: WidgetStatePropertyAll(foregroundColor),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          padding: WidgetStatePropertyAll(
              EdgeInsets.only(left: BPPresets.medium / 4 * 3, right: widget.onAdditionalDetailsButtonPressed != null ? 0 : BPPresets.medium / 4 * 3)),
        ),*/
        child: Row(children: [
          Icon(widget.icon),
          SizedBox(width: 8 * Theme.of(context).scaling),
          Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.text).medium(),
            Text(widget.isSelected.toString()).small(),
          ]),
          const Spacer(),
          if (widget.onAdditionalDetailsButtonPressed != null)
            IconButton.secondary(
              size: ButtonSize.normal,
              density: ButtonDensity.iconDense,
              onPressed: widget.onAdditionalDetailsButtonPressed,
              icon: const Icon(Icons.arrow_forward_ios),
            ),

        ]),

    );
  }
}

class _ControlCenterPageBase extends StatelessWidget {
  final String title;
  final Widget body;

  const _ControlCenterPageBase({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(/*backgroundColor: Theme.of(context).colorScheme.surface,*/
      content: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(children: [
            IconButton.secondary(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back)),
            const Spacer(flex: 4),
            Text(title).large(),
            const Spacer(flex: 5),
          ]),
          SizedBox(height: 4 * Theme.of(context).scaling),
          //const Divider(),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _ControlCenterMainPage extends StatefulWidget {
  const _ControlCenterMainPage({super.key});

  @override
  _ControlCenterMainPageState createState() => _ControlCenterMainPageState();
}

class _ControlCenterMainPageState extends State<_ControlCenterMainPage> {
  /*Widget cont(Widget child) {
    return AdvancedContainer(
      height: 46,
      padding: EdgeInsets.symmetric(horizontal: (4 * Theme.of(context).scaling) / 2),
      borderRadius: 100,
      child: child,
    );
  }*/

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8 * Theme.of(context).scaling),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton.secondary(
                icon: Row(children: [
                  SizedBox(width: 4 * Theme.of(context).scaling),
                  const Icon(Icons.battery_full),
                  SizedBox(width: 4 * Theme.of(context).scaling),
                  const Text("100%"),
                  SizedBox(width: 4 * Theme.of(context).scaling),
                ],),
                onPressed: () {},
              ),
              const Spacer(),
              IconButton.secondary(icon: const Icon(Icons.settings), onPressed: () {}),
              SizedBox(width: 4 * Theme.of(context).scaling),
              IconButton.secondary(icon: const Icon(Icons.power_settings_new), onPressed: () {}),
            ]),
            SizedBox(height: 4 * Theme.of(context).scaling),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Expanded(
                  child: _QuickActionItem(
                      text: "Wi-Fi",
                      icon: Icons.wifi_rounded,
                      isSelected: true,
                      onSelectionChange: (p0) {},
                      onAdditionalDetailsButtonPressed: () => showDialog(context: context, fullScreen: true, builder: (_) => const _ControlCenterWifiPage(), useRootNavigator: false))),
              SizedBox(width: 4 * Theme.of(context).scaling),
              Expanded(child: _QuickActionItem(text: "Bluetooth", icon: Icons.bluetooth_rounded, isSelected: false, onSelectionChange: (p0) {})),
            ]),
            SizedBox(height: 4 * Theme.of(context).scaling),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Expanded(child: _QuickActionItem(text: "Airplane Mode", icon: Icons.airplanemode_off, isSelected: false, onSelectionChange: (p0) {})),
              SizedBox(width: 4 * Theme.of(context).scaling),
              Expanded(child: _QuickActionItem(text: "Do not Disturb", icon: Icons.do_not_disturb_on, isSelected: true, onSelectionChange: (p0) {})),
            ]),
            SizedBox(height: 4 * Theme.of(context).scaling),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Expanded(child: _QuickActionItem(text: "Dark Theme", icon: Icons.dark_mode_rounded, isSelected: true, onSelectionChange: (p0) {})),
              SizedBox(width: 4 * Theme.of(context).scaling),
              Expanded(child: _QuickActionItem(text: "EN_US", icon: Icons.keyboard, isSelected: false, onSelectionChange: (p0) {})),
            ]),
            SizedBox(height: 4 * Theme.of(context).scaling),
            Row(mainAxisSize: MainAxisSize.max, children: [
              IconButton.ghost(icon: const Icon(Icons.volume_up), onPressed: () {}),
              Expanded(child: Slider(value: const SliderValue.single(0.5), onChanged: (p0) {})),
              IconButton.ghost(icon: const Icon(Icons.arrow_drop_down), onPressed: () {}),
            ]),
            SizedBox(height: 4 * Theme.of(context).scaling),
            Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton.ghost(icon: const Icon(Icons.brightness_auto), onPressed: () {}),
              Expanded(child: Slider(value: const SliderValue.single(0.5), onChanged: (p0) {})),
              IconButton.ghost(icon: const Icon(Icons.arrow_drop_down), onPressed: () {}),
            ]),
          ],
        ),
      ),
    );
  }
}