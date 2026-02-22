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

/// A pressable widget that shows a window's contents along with it's title.
class DesktopWindowView extends StatefulWidget {
  final String title;
  final bool isHighlighted;
  final Image? image;
  final double aspectRatio;
  final double height;
  final void Function()? onPress;
  final bool isTitleEditable;
  final void Function(String)? onTitleEdited;
  final Widget Function(bool isHovered)? child;

  const DesktopWindowView({
    super.key,
    required this.title,
    this.isHighlighted = false,
    this.image,
    this.aspectRatio = 250 / 170,
    this.height = 170,
    this.onPress,
    this.isTitleEditable = false,
    this.onTitleEdited,
    this.child,
  });

  @override
  _DesktopWindowViewState createState() => _DesktopWindowViewState();
}

class _DesktopWindowViewState extends State<DesktopWindowView> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final width = widget.height * widget.aspectRatio;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: width,
          height: widget.height,
          child: SecondaryButton(
            //borderRadius: borderRadius,
            onHover: (p0) => setState(() => _isHovered = p0),
            onPressed: widget.onPress,
            //isHighlighted: widget.isHighlighted,
            child: widget.child?.call(_isHovered) ?? const SizedBox.shrink(),
          ),
        ),
        SizedBox(height: 4 * Theme.of(context).scaling),
        if (widget.isTitleEditable)
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: width,
            ),
            child: IntrinsicWidth(/*child: ShadeEditableTextWidget(initialText: widget.title, onEditingComplete: widget.onTitleEdited, hintText: "Type Something...")*/), // TODO
          )
        else ...[
          const SizedBox(height: 11 / 2),
          Text(widget.title).large(),
          const SizedBox(height: 11 / 2),
        ]
      ],
    );
  }
}