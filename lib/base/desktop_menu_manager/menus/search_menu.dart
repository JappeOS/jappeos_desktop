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

class SearchMenu extends CenteredDesktopMenu {
  SearchMenu({Key? key}) : super(key: key);

  @override
  _SearchMenuState createState() => _SearchMenuState();
}

class _SearchMenuState extends State<SearchMenu> {
  @override
  Widget build(BuildContext context) {
    final defaultPadding = 8 * Theme.of(context).scaling;

    return SizedBox(
      width: 525,
      height: MediaQuery.of(context).size.height / 2,
      child: Column(
        children: [
          DOverlayContainer(
            child: Padding(
              padding: EdgeInsets.all(defaultPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const TextField(
                    features: [InputFeature.leading(Icon(Icons.search))],
                    hintText: "Search Files, Apps & More",
                    autofocus: true,
                  ),
                  const Divider(),
                  const Text("Results will be shown here.").medium().muted(),
                ],
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}