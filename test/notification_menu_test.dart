// ignore_for_file: depend_on_referenced_packages
import 'package:dbus/dbus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jappeos_desktop/src/components/desktop_notifications.dart';
import 'package:jappeos_desktop/src/desktop_menu_manager/menus/notification_menu.dart';
import 'package:jappeos_desktop/src/provider/application_icon_service.dart';
import 'package:jappeos_desktop/src/provider/desktop_entry_provider.dart';
import 'package:jappeos_services/jappeos_services.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' hide Notification;

class _Notifications extends ChangeNotifier
    implements NotificationManagerService {
  @override
  List<Notification> notifications = [];

  void show(List<Notification> value) {
    notifications = value;
    notifyListeners();
  }

  Future<void> Function()? onClear;

  @override
  Future<void> clear() async {
    if (onClear != null) {
      await onClear!();
    } else {
      show([]);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DesktopEntries extends ChangeNotifier implements DesktopEntryProvider {
  @override
  final icons = ApplicationIconService((_) async => null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Notification notification(String id) => Notification(
      path: DBusObjectPath('/notifications/$id'),
      time: DateTime(2026),
      appName: id,
      appIcon: 'material:folder',
      summary: 'Message $id',
      body: '',
      actionKeys: const [],
    );

Finder card(String id) => find.byWidgetPredicate((widget) =>
    widget is ProvidedNotificationContent && widget.notification.appName == id);
Finder fade(String id) =>
    find.ancestor(of: card(id), matching: find.byType(Opacity)).first;
Finder slide(String id) => find
    .ancestor(of: card(id), matching: find.byType(FractionalTranslation))
    .first;

Future<void> _mount(WidgetTester tester, _Notifications service,
    {bool reducedMotion = false, double height = 584}) async {
  final entries = _DesktopEntries();
  addTearDown(entries.dispose);
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider<NotificationManagerService>.value(value: service),
      ChangeNotifierProvider<DesktopEntryProvider>.value(value: entries),
    ],
    child: ShadcnApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reducedMotion),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: height),
            child: NotificationMenu(),
          ),
        ),
      ),
    ),
  ));
  await tester.pump();
}

// Flush provider updates and let animations started during the rebuild tick.
Future<void> _flushUpdate(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('list grows to its limit and scrolls without moving Clear All',
      (tester) async {
    final service = _Notifications()..show([notification('a')]);
    addTearDown(service.dispose);
    await _mount(tester, service, height: 750);
    await tester.pumpAndSettle();
    final list = find.byType(SingleChildScrollView);
    final shortHeight = tester.getSize(list).height;
    service.show(List.generate(12, (i) => notification('n$i')));
    await _flushUpdate(tester);
    await tester.pumpAndSettle();
    expect(tester.getSize(list).height, greaterThan(shortHeight));
    expect(tester.getSize(find.byType(NotificationMenu)).height,
        lessThanOrEqualTo(750));
    final button = find.widgetWithText(OutlineButton, 'Clear All');
    final before = tester.getRect(button);
    final scroll = tester.widget<SingleChildScrollView>(list).controller!;
    expect(scroll.position.maxScrollExtent, greaterThan(0));
    scroll.jumpTo(scroll.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(tester.getRect(button), before);
    service.show([notification('a')]);
    await _flushUpdate(tester);
    await tester.pumpAndSettle();
    expect(tester.getSize(list).height, closeTo(shortHeight, 0.01));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('short display keeps the notification footer inside the menu',
      (tester) async {
    final service = _Notifications()
      ..show(List.generate(5, (i) => notification('n$i')));
    addTearDown(service.dispose);
    await _mount(tester, service, height: 400);
    await tester.pumpAndSettle();
    final button = find.widgetWithText(OutlineButton, 'Clear All');
    expect(tester.getRect(button).bottom, lessThanOrEqualTo(400));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('cards enter, update in place, and reverse on individual removal',
      (tester) async {
    final service = _Notifications();
    addTearDown(service.dispose);
    await _mount(tester, service);
    expect(find.text('No notifications'), findsOneWidget);
    service.show([notification('a')]);
    await _flushUpdate(tester);
    expect(tester.widget<Opacity>(fade('a')).opacity, 0);
    await tester.pump(kDefaultDuration ~/ 2);
    expect(tester.widget<Opacity>(fade('a')).opacity, inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    service.show([notification('a').copyWith(summary: 'Updated')]);
    await _flushUpdate(tester);
    expect(tester.widget<Opacity>(fade('a')).opacity, 1);
    service.show([]);
    await _flushUpdate(tester);
    await tester.pump(kDefaultDuration ~/ 2);
    expect(tester.widget<Opacity>(fade('a')).opacity, inExclusiveRange(0, 1));
    expect(tester.widget<FractionalTranslation>(slide('a')).translation.dx, 0);
    await tester.pumpAndSettle();
    expect(card('a'), findsNothing);
    expect(find.text('No notifications'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Clear All swipes confirmed removals; later arrivals exit normally',
      (tester) async {
    final service = _Notifications()
      ..show([notification('a'), notification('b')]);
    addTearDown(service.dispose);
    service.onClear = () async {}; // D-Bus removals can arrive after the reply.
    await _mount(tester, service);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Clear All'));
    await tester.tap(find.text('Clear All'));
    await _flushUpdate(tester);
    expect(tester.widget<Opacity>(fade('a')).opacity, 1);
    service.show([notification('c')]);
    await _flushUpdate(tester);
    await tester.pump(kDefaultDuration ~/ 2);
    for (final id in ['a', 'b']) {
      expect(tester.widget<FractionalTranslation>(slide(id)).translation.dx,
          greaterThan(0));
      expect(tester.widget<Opacity>(fade(id)).opacity, inExclusiveRange(0, 1));
    }
    await tester.pumpAndSettle();
    expect(card('a'), findsNothing);
    expect(card('b'), findsNothing);
    expect(card('c'), findsOneWidget);
    service.show([]);
    await _flushUpdate(tester);
    await tester.pump(kDefaultDuration ~/ 2);
    expect(tester.widget<FractionalTranslation>(slide('c')).translation.dx, 0);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'failed clear keeps cards and does not mark later removals as swipes',
      (tester) async {
    final service = _Notifications()..show([notification('a')]);
    addTearDown(service.dispose);
    service.onClear = () async => throw StateError('failed');
    await _mount(tester, service);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Clear All'));
    await tester.tap(find.text('Clear All'));
    await _flushUpdate(tester);
    expect(tester.widget<Opacity>(fade('a')).opacity, 1);
    service.show([]);
    await _flushUpdate(tester);
    await tester.pump(kDefaultDuration ~/ 2);
    expect(tester.widget<FractionalTranslation>(slide('a')).translation.dx, 0);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'reappearing cards cancel removal and reduced motion removes immediately',
      (tester) async {
    final service = _Notifications()..show([notification('a')]);
    addTearDown(service.dispose);
    await _mount(tester, service);
    await tester.pumpAndSettle();
    service.show([]);
    await _flushUpdate(tester);
    await tester.pump(kDefaultDuration ~/ 2);
    service.show([notification('a')]);
    await _flushUpdate(tester);
    await tester.pumpAndSettle();
    expect(card('a'), findsOneWidget);
    expect(tester.widget<Opacity>(fade('a')).opacity, 1);
    await tester.pumpWidget(const SizedBox());
    await _mount(tester, service, reducedMotion: true);
    expect(tester.widget<Opacity>(fade('a')).opacity, 1);
    service.show([]);
    await _flushUpdate(tester);
    expect(card('a'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
