import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jdwm/jdwm.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import 'package:jappeos_desktop/src/components/desktop_panel_visibility.dart';
import 'package:jappeos_desktop/src/desktop_menu_manager/desktop_menu_controller.dart';

class _Menu extends DesktopMenu {
  @override
  State<_Menu> createState() => _MenuState();
}

class _MenuState extends State<_Menu> {
  @override
  Widget build(BuildContext context) => const SizedBox();
}

void main() {
  testWidgets(
      'fullscreen panels stay hidden at screen edge; menus and focus restore them',
      (tester) async {
    final menu = DesktopMenuController();
    final managerKey = GlobalKey<WindowManagerState>();
    final panelKey = GlobalKey();
    var enters = 0;
    var clicks = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('platform'), (_) async => null);
    await tester.pumpWidget(shadcn.Theme(
      data: const shadcn.ThemeData(),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: WindowManager(
          key: managerKey,
          monitorOverlayBuilder: (_, __) => DesktopPanelVisibility(
            menuController: menu,
            child: Stack(children: [
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 20,
                child: MouseRegion(
                    key: panelKey,
                    onEnter: (_) => enters++,
                    child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => clicks++,
                        child: const SizedBox.expand())),
              )
            ]),
          ),
        ),
      ),
    ));
    final panelElement = panelKey.currentContext;
    Future<void> event(String method, int id,
        [Map<String, Object> data = const {}]) async {
      final done = Completer<void>();
      tester.binding.channelBuffers.push(
          'platform',
          const StandardMethodCodec().encodeMethodCall(MethodCall(method, {
            'view_id': id,
            'protocol': 'xdg',
            ...data,
          })),
          (_) => done.complete());
      await done.future;
      await tester.pump();
      await tester.pump();
    }

    bool hidden() => tester
        .widget<Offstage>(find
            .descendant(
                of: find.byType(DesktopPanelVisibility),
                matching: find.byType(Offstage),
                skipOffstage: false)
            .first)
        .offstage;
    await event('commit_toplevel_surface', 1,
        {'has_decoration': true, 'decoration': 2});
    await event('map_toplevel_surface', 1);
    expect(hidden(), isFalse);
    await event('set_toplevel_state', 1,
        {'visible': true, 'maximized': false, 'fullscreen': true});
    expect(hidden(), isTrue);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(400, 300));
    await mouse.moveTo(const Offset(400, 599));
    await tester.pump();
    expect(enters, 0);
    expect(hidden(), isTrue);
    await tester.tapAt(const Offset(400, 599));
    expect(clicks, 0);
    menu.openMenu(_Menu());
    await tester.pump();
    expect(hidden(), isFalse);
    expect(panelKey.currentContext, same(panelElement));
    menu.closeMenu();
    await tester.pump();
    expect(hidden(), isTrue);
    await event('commit_toplevel_surface', 2,
        {'has_decoration': true, 'decoration': 2});
    await event('map_toplevel_surface', 2);
    expect(hidden(), isFalse);
    final manager = managerKey.currentState!;
    manager.requestFocus(
        manager.getAllWindows().firstWhere((w) => w.backendViewId == 1));
    await tester.pump();
    expect(hidden(), isTrue);
    await event('set_toplevel_state', 1,
        {'visible': true, 'maximized': false, 'fullscreen': false});
    expect(hidden(), isFalse);
    await event('set_toplevel_state', 1,
        {'visible': true, 'maximized': false, 'fullscreen': true});
    expect(hidden(), isTrue);
    await event('unmap_toplevel_surface', 1);
    expect(hidden(), isFalse);
    await mouse.removePointer();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    menu.dispose();
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('platform'), null);
  });
}
