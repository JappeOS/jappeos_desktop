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

part of jappeos_desktop.base;

class NotificationMenuEntry extends DesktopMenuEntry {
  @override
  String get id => 'notification';

  @override
  DesktopMenuEntryType get type => DesktopMenuEntryType.tray;

  @override
  String get label => 'Notifications';

  @override
  LogicalKeySet? get shortcut => LogicalKeySet(
    LogicalKeyboardKey.superKey,
    LogicalKeyboardKey.keyX,
  );

  @override
  List<Widget> buildIcon(BuildContext context) {
    return const [NotificationText(), Icon(Icons.notifications)];
  }

  @override
  DesktopMenu createMenu() {
    return NotificationMenu();
  }
}

class NotificationText extends StatefulWidget {
  const NotificationText({Key? key}) : super(key: key);

  @override
  _NotificationTextState createState() => _NotificationTextState();
}

class _NotificationTextState extends State<NotificationText> {
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
    return Text(_timeString).small();
  }
}

class NotificationMenu extends DesktopMenu {
  NotificationMenu({Key? key}) : super(key: key);

  @override
  _NotificationMenuState createState() => _NotificationMenuState();
}

class _NotificationMenuState extends State<NotificationMenu> {
  CalendarValue? _value;
  CalendarView _view = CalendarView.now();

  @override
  Widget build(BuildContext context) {
    final defaultPadding = 4 * Theme.of(context).scaling;

    Widget buildCalendar() => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            OutlineButton(
              density: ButtonDensity.icon,
              onPressed: () {
                setState(() {
                  _view = _view.previous;
                });
              },
              child: const Icon(Icons.arrow_back).iconXSmall(),
            ),
            Text('${_view.month} ${_view.year}') // TODO: localizations.getMonth
                .small()
                .medium()
                .center()
                .expanded(),
            OutlineButton(
              density: ButtonDensity.icon,
              onPressed: () {
                setState(() {
                  _view = _view.next;
                });
              },
              child: const Icon(Icons.arrow_forward).iconXSmall(),
            ),
          ],
        ),
        const Gap(16),
        Calendar(
          value: _value,
          view: _view,
          onChanged: (value) {
            setState(() {
              _value = value;
            });
          },
          selectionMode: CalendarSelectionMode.range,
        ),
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DOverlayContainer(
          width: 400,
          padding: EdgeInsets.all(defaultPadding),
          child: buildCalendar(),
        ),
        SizedBox(height: defaultPadding),
        DOverlayContainer(
          width: 400,
          padding: EdgeInsets.all(defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 4 * Theme.of(context).scaling,
            children: [
              _NotificationCard.media(title: "YouTube", contentText: "YouTube Video\nYouTube Channel\nSomething"),
              _NotificationCard.basic(title: "Notification", contentText: "Hello, World!", actions: [("Dismiss", () {}), ("Do Something", () {})]),
              OutlineButton(onPressed: () {}, child: const Text("Clear All")),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotificationCard extends StatefulWidget {
  final String source;
  final String contentText;
  final bool isMedia;
  final List<(String, void Function())> actions;

  factory _NotificationCard.basic({required String title, required String contentText, List<(String, void Function())> actions = const []}) {
    return _NotificationCard._(source: title, contentText: contentText, actions: actions);
  }

  factory _NotificationCard.media({required String title, required String contentText}) {
    return _NotificationCard._(source: title, contentText: contentText, isMedia: true);
  }

  const _NotificationCard._({required this.source, required this.contentText, this.isMedia = false, this.actions = const []});

  @override
  _NotificationCardState createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> {
  bool _hovered = false;
  bool _expanded = false;

  Widget _iconButton(IconData icon, void Function() onPressed) => IconButton(
    onPressed: onPressed,
    icon: _hovered ? Icon(icon) : const SizedBox.shrink(),
    size: ButtonSize.small,
    variance: ButtonVariance.secondary,
  );

  Widget _arrowIconButton(void Function() onPressed) => IconButton(
    onPressed: onPressed,
    icon: _hovered ?
      AnimatedRotation(
        turns: _expanded ? 0.5 : 0, // 180° rotation
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: const Icon(Icons.keyboard_arrow_down),
      ) :
      const SizedBox.shrink(),
    size: ButtonSize.small,
    variance: ButtonVariance.secondary,
  );

  @override
  Widget build(BuildContext context) {
    final bool isExpandable = widget.actions.isNotEmpty;

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _hovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _hovered = false;
        });
      },
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: SecondaryButton(
          /*style: FilledButton.styleFrom( TODO
            padding: EdgeInsets.symmetric(horizontal: 4 * Theme.of(context).scaling, vertical: 4 * Theme.of(context).scaling * 1.1),
            shape: RoundedRectangleBorder(side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant), borderRadius: BorderRadius.circular(4 * Theme.of(context).scaling)),
          ),*/
          onPressed: () {},
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 4 * Theme.of(context).scaling,
            children: [
              SizedBox(
                height: 35 / 1.25,
                child: Row(
                  spacing: 4 * Theme.of(context).scaling,
                  children: [
                    const Icon(Icons.settings, size: 20).muted(),
                    Expanded(child: Text(widget.source).muted()),
                    if (isExpandable) _arrowIconButton(() => setState(() => _expanded = !_expanded)),
                    if (!widget.isMedia) _iconButton(Icons.close, () {}),
                  ],
                ),
              ),
              Row(
                spacing: 4 * Theme.of(context).scaling,
                children: [
                  SizedBox.square(dimension: 50, child: Container(color: Colors.black)),
                  Expanded(
                    child: Text(
                      widget.contentText,
                      style: Theme.of(context).typography.medium,
                      textAlign: TextAlign.left,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3,
                    ),
                  ),
                  if (widget.isMedia) ... [
                    IconButton(onPressed: () {}, icon: const Icon(Icons.skip_previous), variance: ButtonVariance.ghost),
                    IconButton(onPressed: () {}, icon: const Icon(Icons.play_arrow), variance: ButtonVariance.secondary),
                    IconButton(onPressed: () {}, icon: const Icon(Icons.skip_next), variance: ButtonVariance.ghost),
                  ],
                ],
              ),
              if (_expanded) Row(
                spacing: 4 * Theme.of(context).scaling,
                children: List.generate(widget.actions.length, (index) => Expanded(
                  child: TextButton(
                    onPressed: widget.actions[index].$2,
                    child: Text(widget.actions[index].$1),
                  ),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}