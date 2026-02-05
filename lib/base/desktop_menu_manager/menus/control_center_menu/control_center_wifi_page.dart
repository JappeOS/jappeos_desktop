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

part of 'control_center_menu.dart';

class _ControlCenterWifiPage extends StatefulWidget {
  const _ControlCenterWifiPage({super.key});

  @override
  _ControlCenterWifiPageState createState() => _ControlCenterWifiPageState();
}

class _ControlCenterWifiPageState extends State<_ControlCenterWifiPage> {
  @override
  Widget build(BuildContext context) {
    return _ControlCenterPageBase(
      title: "Wi-Fi",
      body: ListView.builder(
          itemCount: 5,
          itemBuilder: (context, index) {
            return _NetworkItem(ssid: "Network#$index");
          }),
    );
  }
}

class _NetworkItem extends StatefulWidget {
  final String ssid;

  const _NetworkItem({required this.ssid});

  @override
  _NetworkItemState createState() => _NetworkItemState();
}

class _NetworkItemState extends State<_NetworkItem> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final connectAction = isHovered ? () {} : null;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: (4 * Theme.of(context).scaling) / 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => isHovered = true),
        onExit: (_) => setState(() => isHovered = false),
        child: Container(
          color: Theme.of(context).colorScheme.card,
          padding: EdgeInsets.all(4 * Theme.of(context).scaling),
          child: Row(children: [
            const Icon(Icons.wifi_lock),
            SizedBox(width: 4 * Theme.of(context).scaling),
            Expanded(child: Text(widget.ssid)),
            AnimatedOpacity(duration: const Duration(milliseconds: 100), opacity: isHovered ? 1.0 : 0.0, child: OutlineButton(onPressed: connectAction, child: const Text("Connect"))),
          ]),
        ),
      ),
    );
  }
}
