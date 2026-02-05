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

import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../components/desktop_widgets.dart';
import '../desktop_menu_controller.dart';

class PermissionsMenu extends DesktopMenu {
  PermissionsMenu({Key? key}) : super(key: key);

  @override
  _PermissionsMenuState createState() => _PermissionsMenuState();
}

class _PermissionsMenuState extends State<PermissionsMenu> {
  final List<_ExpansionPanelListItem> _data = [
    _ExpansionPanelListItem(expandedValues: ["Google Chrome", "Discord"], headerValue: "Microphone", headerIcon: Icons.mic),
    _ExpansionPanelListItem(expandedValues: ["Google Chrome", "Discord"], headerValue: "Camera", headerIcon: Icons.camera),
  ];

  @override
  Widget build(BuildContext context) {
    final defaultPadding = 4 * Theme.of(context).scaling;

    return DOverlayContainer(
      width: 300,
      height: 300,
      child: Padding(
        padding: EdgeInsets.all(defaultPadding),
        child: const Placeholder() /* TODO: SingleChildScrollView(
          child: ExpansionPanelList(
            expansionCallback: (int index, bool isExpanded) {
              setState(() {
                _data[index].isExpanded = !isExpanded;
              });
            },
            children: _data.map<ExpansionPanel>((_ExpansionPanelListItem item) {
              return ExpansionPanel(
                headerBuilder: (BuildContext context, bool isExpanded) {
                  return ListTile(
                    leading: Icon(item.headerIcon),
                    title: Text(item.headerValue),
                  );
                },
                body: Text(item.expandedValues.join("\n")),
                isExpanded: item.isExpanded,
              );
            }).toList(),
          ),
        ),*/
      ),
    );
  }
}

class _ExpansionPanelListItem {
  _ExpansionPanelListItem({
    required this.expandedValues,
    required this.headerIcon,
    required this.headerValue,
    this.isExpanded = false,
  });

  List<String> expandedValues;
  IconData headerIcon;
  String headerValue;
  bool isExpanded;
}
