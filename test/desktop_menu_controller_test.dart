import 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jappeos_desktop/src/desktop_menu_manager/desktop_menu_controller.dart';
import 'package:jdwm/jdwm.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

class _Menu extends DesktopMenu {
  final Widget child;

  _Menu({this.child = const SizedBox(width: 100, height: 100)});

  @override
  State<_Menu> createState() => _MenuState();
}

class _OtherMenu extends _Menu {}

class _MenuState extends State<_Menu> {
  @override
  Widget build(BuildContext context) => widget.child;
}

Future<void> _mount(
  WidgetTester tester,
  DesktopMenuController controller,
) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: DesktopMenuWidget(
        controller: controller,
        monitor: const MonitorConfig(
          id: 'test',
          bounds: Rect.fromLTWH(0, 0, 800, 600),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
      'context menu checkbox keeps both menus open, outside closes them',
      (tester) async {
    final controller = DesktopMenuController();
    addTearDown(controller.dispose);
    var checked = false;
    final menu = _Menu(
      child: shadcn.ContextMenu(
        items: [
          shadcn.MenuCheckbox(
            value: false,
            autoClose: false,
            onChanged: (_, value) => checked = value,
            child: const Text('Use Discrete GPU'),
          ),
        ],
        child: const SizedBox(width: 100, height: 100),
      ),
    );
    await tester.pumpWidget(shadcn.ShadcnApp(
      home: SizedBox.expand(
        child: DesktopMenuWidget(
          controller: controller,
          monitor: const MonitorConfig(
            id: 'test',
            bounds: Rect.fromLTWH(0, 0, 800, 600),
          ),
        ),
      ),
    ));
    controller.openMenu(menu, position: const Offset(100, 100));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(140, 100), buttons: kSecondaryMouseButton);
    await tester.pumpAndSettle();

    final checkbox = find.text('Use Discrete GPU');
    expect(checkbox, findsOneWidget);
    expect(tester.getCenter(checkbox).dx, greaterThan(150));
    await tester.tap(checkbox);
    await tester.pumpAndSettle();
    expect(checked, isTrue);
    expect(controller.currentMenu, same(menu));
    expect(find.byWidget(menu), findsOneWidget);
    expect(checkbox, findsOneWidget);

    await tester.tapAt(const Offset(700, 500));
    await tester.pumpAndSettle();
    expect(controller.currentMenu, isNull);
    expect(find.byWidget(menu), findsNothing);
    expect(checkbox, findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('closing retains menu state and anchor until exit completes',
      (tester) async {
    final controller = DesktopMenuController();
    addTearDown(controller.dispose);
    await _mount(tester, controller);
    final menu = _Menu();
    var closeCount = 0;
    controller.openMenu(
      menu,
      position: const Offset(400, 300),
      closeCallback: () => closeCount++,
    );
    await tester.pumpAndSettle();
    final state = tester.state(find.byWidget(menu));
    final positioned = tester.widget<Positioned>(find.byType(Positioned));

    controller.closeMenu();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(controller.currentMenu, isNull);
    expect(closeCount, 1);
    expect(tester.state(find.byWidget(menu)), same(state));
    final exiting = tester.widget<Positioned>(find.byType(Positioned));
    expect(exiting.left, positioned.left);
    expect(exiting.top, positioned.top);
    expect(
      tester.widget<IgnorePointer>(find.byType(IgnorePointer)).ignoring,
      isTrue,
    );
    expect(tester.widget<TapRegion>(find.byType(TapRegion)).enabled, isFalse);
    final opacity = tester.widget<FadeTransition>(find.byType(FadeTransition));
    expect(opacity.opacity.value, inExclusiveRange(0, 1));

    controller.closeMenu();
    await tester.pumpAndSettle();
    expect(find.byWidget(menu), findsNothing);
    expect(state.mounted, isFalse);
    expect(closeCount, 1);
  });

  testWidgets('replacement waits for exit and pending close cancels entry',
      (tester) async {
    final controller = DesktopMenuController();
    addTearDown(controller.dispose);
    await _mount(tester, controller);
    final first = _Menu();
    final second = _OtherMenu();
    controller.openMenu(first);
    await tester.pumpAndSettle();

    controller.openMenu(second);
    await tester.pump();
    expect(find.byWidget(first), findsOneWidget);
    expect(find.byWidget(second), findsNothing);
    await tester.pumpAndSettle();
    expect(find.byWidget(first), findsNothing);
    expect(find.byWidget(second), findsOneWidget);

    controller.openMenu(_Menu());
    await tester.pump();
    controller.closeMenu();
    await tester.pumpAndSettle();
    expect(find.byType(FadeTransition), findsNothing);
  });

  testWidgets('menu opened before mount animates and can reopen during exit',
      (tester) async {
    final controller = DesktopMenuController();
    addTearDown(controller.dispose);
    final menu = _Menu();
    controller.openMenu(menu);
    await _mount(tester, controller);
    await tester.pumpAndSettle();
    final state = tester.state(find.byWidget(menu));

    controller.closeMenu();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    controller.openMenu(menu);
    await tester.pumpAndSettle();
    expect(tester.state(find.byWidget(menu)), same(state));
    expect(
      tester.widget<FadeTransition>(find.byType(FadeTransition)).opacity.value,
      1,
    );
    controller.closeMenu();
    await tester.pumpAndSettle();
  });
}
