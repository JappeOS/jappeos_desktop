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

/// A basic widget that has the logo of an app and also the name below.
class DApplicationItem extends StatefulWidget {
  final SvgPicture image;
  final String title;
  final bool showTitle;
  final double sizeFactor;
  final void Function()? onPress;

  const DApplicationItem._({
    Key? key,
    required this.image,
    this.title = "null",
    this.showTitle = true,
    this.sizeFactor = 1.0,
    this.onPress,
  }) : super(key: key);

  factory DApplicationItem.icon({required SvgPicture image, required String title, double sizeFactor = 1, void Function()? onPress}) {
    return DApplicationItem._(image: image, title: title, showTitle: false, sizeFactor: sizeFactor, onPress: onPress);
  }

  factory DApplicationItem.iconWithTitle({required SvgPicture image, required String title, void Function()? onPress}) {
    return DApplicationItem._(image: image, title: title, showTitle: true, onPress: onPress);
  }

  @override
  _DApplicationItemState createState() => _DApplicationItemState();
}

class _DApplicationItemState extends State<DApplicationItem> {
  bool _isHovered = false, _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hoveredColor = colorScheme.primary.withValues(alpha: 0.08);
    final pressedColor = colorScheme.primary.withValues(alpha: 0.08);

    final width = widget.showTitle ? 100 * widget.sizeFactor : 80 * widget.sizeFactor;
    final height = widget.showTitle ? null : 80 * widget.sizeFactor;

    var iconSize = width - (4 * Theme.of(context).scaling) * 1.25;

    if (iconSize > 60) iconSize = 60;

    return SizedBox(
      width: width,
      height: height,
      child: RepaintBoundary(
        child: Tooltip(
          tooltip: (_) => Text(widget.title),
          child: MouseRegion(
            onEnter: (p0) => setState(() => _isHovered = true),
            onExit: (p0) => setState(() => _isHovered = false),
            child: GestureDetector(
              onTap: widget.onPress,
              onTapDown: (p0) => setState(() => _isPressed = true),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _isPressed ? pressedColor : (_isHovered ? hoveredColor : null),
                  borderRadius: BorderRadius.circular(8 * Theme.of(context).scaling),
                ),
                child: Padding(
                  padding: widget.showTitle ? EdgeInsets.symmetric(vertical: 4 * Theme.of(context).scaling) : EdgeInsets.zero,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 4 * Theme.of(context).scaling,
                    children: [
                      AnimatedScale(
                        scale: _isPressed ? 0.7 : 1,
                        curve: Curves.easeOut,
                        duration: const Duration(milliseconds: 75),
                        onEnd: () {
                          if (_isPressed) setState(() => _isPressed = false);
                        },
                        child: SvgPicture(widget.image.bytesLoader, width: iconSize, height: iconSize),
                      ),
                      if (widget.showTitle) Text(
                        widget.title,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ).medium(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// TODO
/// A wrapper around [ShadeContainer] that is used for the overlays and menus of the desktop.
class DOverlayContainer extends StatelessWidget {
  final double? width, height;
  final EdgeInsetsGeometry? padding;
  final bool increasedBorderRadius;
  final Widget child;

  const DOverlayContainer({super.key, required this.child, this.width, this.height, this.padding, this.increasedBorderRadius = false});

  @override
  Widget build(BuildContext context) {
    return DualBorderOutlinedContainer(
      width: width,
      height: height,
      padding: padding,
      surfaceOpacity: Theme.of(context).surfaceOpacity,
      surfaceBlur: Theme.of(context).surfaceBlur,
      borderRadius: increasedBorderRadius ? Theme.of(context).borderRadiusXl : Theme.of(context).borderRadiusLg,
      //elevation: 8, TODO
      child: child,
    );
  }
}

/// A topbar button that opens a desktop menu.
class DTopbarButton extends StatefulWidget {
  static const double _kIconSize = 17;

  final String? title;
  final List<Widget> children;
  final DesktopMenuController menuControllerRef;
  final DesktopMenu menu;

  final AlignmentGeometry alignment;

  const DTopbarButton._(
      {Key? key, this.title, this.children = const [], required this.menuControllerRef, required this.menu, this.alignment = Alignment.center})
      : super(key: key);

  factory DTopbarButton.text({
    required String text,
    required DesktopMenuController menuControllerRef,
    required DesktopMenu menu,
    AlignmentGeometry alignment = Alignment.center,
  }) {
    return DTopbarButton._(
      menuControllerRef: menuControllerRef,
      menu: menu,
      alignment: alignment,
      title: text,
    );
  }

  factory DTopbarButton.icon({
    required IconData icon,
    required DesktopMenuController menuControllerRef,
    required DesktopMenu menu,
    AlignmentGeometry alignment = Alignment.center,
  }) {
    return DTopbarButton._(
      menuControllerRef: menuControllerRef,
      menu: menu,
      alignment: alignment,
      children: [Icon(icon, size: _kIconSize)],
    );
  }

  factory DTopbarButton.icons({
    required List<IconData> icons,
    required DesktopMenuController menuControllerRef,
    required DesktopMenu menu,
    AlignmentGeometry alignment = Alignment.center,
  }) {
    return DTopbarButton._(
      menuControllerRef: menuControllerRef,
      menu: menu,
      alignment: alignment,
      children: [
        for (var icon in icons) Icon(icon, size: _kIconSize),
      ],
    );
  }

  factory DTopbarButton.textAndIcon({
    required String text,
    required IconData icon,
    required DesktopMenuController menuControllerRef,
    required DesktopMenu menu,
    AlignmentGeometry alignment = Alignment.center,
  }) {
    return DTopbarButton._(
      menuControllerRef: menuControllerRef,
      menu: menu,
      alignment: alignment,
      title: text,
      children: [Icon(icon, size: _kIconSize)],
    );
  }

  @override
  _DTopbarButtonState createState() => _DTopbarButtonState();
}

class _DTopbarButtonState extends State<DTopbarButton> {
  static const double _kHeight = 26;

  Offset _globalPosition = Offset.zero;

  bool _hovering = false;
  final _borderRad = BorderRadius.circular(100);
  final _borderWidth = 1.0;

  bool _isMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    //final accentColor = Theme.of(context).colorScheme.primary;
    final borderColor = Theme.of(context).colorScheme.border;
    //final splashColor = accentColor.withValues(alpha: 0.25);

    return Container(
      margin: const EdgeInsets.only(left: 5, right: 5),
      alignment: widget.alignment,
      height: _kHeight,
      decoration: BoxDecoration(
        borderRadius: _borderRad,
        color: _hovering || _isMenuOpen ? Theme.of(context).colorScheme.secondary.scaleAlpha(Theme.of(context).surfaceOpacity ?? 0) : Colors.transparent,
        border:
            _hovering || _isMenuOpen ? Border.all(width: _borderWidth, color: borderColor) : Border.all(width: _borderWidth, color: Colors.transparent),
      ),
      child: RepaintBoundary(
        child: Builder(
          builder: (context) {
            // Add a post frame callback to ensure the widget has been laid out
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Get the RenderBox of the widget
              final renderBox = context.findRenderObject() as RenderBox;

              // Get the global position of the widget
              final global = renderBox.localToGlobal(Offset.zero);
              _globalPosition = Offset(global.dx + renderBox.size.width / 2, global.dy);
            });

            return MouseRegion(
              onEnter: (value) => setState(() {
                _hovering = true;
              }),
              onExit: (value) => setState(() {
                _hovering = false;
              }),
              child: GestureDetector(
                //color: isMenuOpen ? splashColor : Colors.transparent,
                //borderRadius: borderRad,
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() => _isMenuOpen = true);
                  widget.menuControllerRef.openMenu(
                    widget.menu,
                    position: _globalPosition,
                    closeCallback: () {
                      setState(() => _isMenuOpen = false);
                    },
                  );
                },

                child: SizedBox(height: _kHeight, child: Padding(
                  padding: const EdgeInsets.only(left: 5, right: 5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: (4 * Theme.of(context).scaling) / 2,
                    children: [
                      if (widget.title != null) Text(widget.title!).small(),
                      ...widget.children,
                    ],
                  ),
                ),),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A background widget for desktop menus.
class DMenuBackground extends StatelessWidget {
  final Widget child;
  final double? width, height;

  const DMenuBackground({Key? key, required this.child, this.width, this.height}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DualBorderOutlinedContainer(
      width: width,
      height: height,
      surfaceBlur: Theme.of(context).surfaceBlur,
      surfaceOpacity: Theme.of(context).surfaceOpacity,
      //backgroundBlur: true,
      borderRadius: Theme.of(context).borderRadiusMd,
      //border: ShadeContainerBorder.double,
      child: child,
    );
  }
}

/// A basic container widget that allows blur.
class DBlurContainer extends StatelessWidget {
  final Widget child;
  final double? width, height;

  const DBlurContainer({Key? key, required this.child, this.width, this.height}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background.scaleAlpha(Theme.of(context).surfaceOpacity ?? 0),
      ),
      //backgroundBlur: true,
      //borderRadius: Theme.of(context).borderRadiusMd,
      //border: ShadeContainerBorder.double,
      child: SurfaceBlur(
        surfaceBlur: Theme.of(context).surfaceBlur,
        child: child
      ),
    );
  }
}

/// A pressable widget that shows a window's contents along with it's title.
class DWindowView extends StatefulWidget {
  final String title;
  final bool isHighlighted;
  final Image? image;
  final double aspectRatio;
  final double height;
  final void Function()? onPress;
  final bool isTitleEditable;
  final void Function(String)? onTitleEdited;
  final Widget Function(bool isHovered)? child;

  const DWindowView({
    Key? key,
    required this.title,
    this.isHighlighted = false,
    this.image,
    this.aspectRatio = 250 / 170,
    this.height = 170,
    this.onPress,
    this.isTitleEditable = false,
    this.onTitleEdited,
    this.child,
  }) : super(key: key);

  @override
  _DWindowViewState createState() => _DWindowViewState();
}

class _DWindowViewState extends State<DWindowView> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final borderRadius = Theme.of(context).borderRadiusMd;
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

/// The dock that shows pinned and open apps.
class DesktopDock extends StatefulWidget {
  final bool hasWindowIntersection;
  final List<(SvgPicture icon, String title, void Function() onPressed)> items;

  const DesktopDock({Key? key, required this.hasWindowIntersection, required this.items}) : super(key: key);

  @override
  _DesktopDockState createState() => _DesktopDockState();
}

class _DesktopDockState extends State<DesktopDock> {
  static const _kAnimDuration = Duration(milliseconds: 150);
  bool _showDock = true;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      widthFactor: 1.0,
      child: MouseRegion(
        onEnter: (event) {
          if (!_showDock) setState(() => _showDock = true);
        },
        onExit: (event) {
          if (_showDock && widget.hasWindowIntersection) setState(() => _showDock = false);
        },
        child: Padding(
          padding: _showDock ? EdgeInsets.only(bottom: 4 * Theme.of(context).scaling) : EdgeInsets.zero,
          child: Row(
            children: [
              const Spacer(),
              WidgetAnimator(
                incomingEffect: WidgetTransitionEffects.incomingSlideInFromBottom(duration: _kAnimDuration),
                outgoingEffect: WidgetTransitionEffects.outgoingSlideOutToBottom(duration: _kAnimDuration),
                child: _showDock ? DOverlayContainer(
                  key: const ValueKey('dockShown'),
                  increasedBorderRadius: true,
                  padding: EdgeInsets.all(4 * Theme.of(context).scaling),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(widget.items.length, (index) => DApplicationItem.icon(
                                  image: widget.items[index].$1, title: widget.items[index].$2, sizeFactor: 0.75, onPress: widget.items[index].$3)),
                  ),
                ) : SizedBox(key: const ValueKey('dockHidden'), height: 2 * Theme.of(context).scaling),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

/// The bar that shows system information and provides access to important parts of the OS-
class DesktopTopBar extends StatefulWidget {
  final DesktopMenuController menuController;

  const DesktopTopBar({Key? key, required this.menuController}) : super(key: key);

  @override
  _DesktopTopBarState createState() => _DesktopTopBarState();
}

class _DesktopTopBarState extends State<DesktopTopBar> {
  String _timeString = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(minutes: 1), (Timer t) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    final formattedTime = DateFormat('HH:mm').format(now);
    setState(() {
      _timeString = formattedTime;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: DSKTP_UI_LAYER_TOPBAR_HEIGHT,
      child: DBlurContainer(
        child: Row(
          children: [
            DTopbarButton.icon(icon: Icons.apps, menuControllerRef: widget.menuController, menu: LauncherMenu()),
            DTopbarButton.icon(icon: Icons.search, menuControllerRef: widget.menuController, menu: SearchMenu()),
            DTopbarButton.icon(icon: Icons.menu_open, menuControllerRef: widget.menuController, menu: OpenWindowsMenu()),
            const Spacer(),
            DTopbarButton.icons(icons: const [Icons.mic, Icons.camera], menuControllerRef: widget.menuController, menu: PermissionsMenu()),
            DTopbarButton.icons(icons: const [Icons.wifi, Icons.volume_mute, Icons.battery_full], menuControllerRef: widget.menuController, menu: ControlCenterMenu()),
            DTopbarButton.textAndIcon(icon: Icons.notifications, text: _timeString, menuControllerRef: widget.menuController, menu: NotificationMenu()),
          ],
        ),
      ),
    );
  }
}