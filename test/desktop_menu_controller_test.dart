import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jappeos_desktop/src/desktop_menu_manager/desktop_menu_controller.dart';
import 'package:jdwm/jdwm.dart';

class _Menu extends DesktopMenu {
  @override
  State<_Menu> createState() => _MenuState();
}

class _OtherMenu extends _Menu {}

class _MenuState extends State<_Menu> {
  @override
  Widget build(BuildContext context) => const SizedBox(width: 100, height: 100);
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
