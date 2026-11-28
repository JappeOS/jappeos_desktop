// ignore_for_file: depend_on_referenced_packages
import 'package:dbus/dbus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jappeos_desktop/src/components/desktop_notifications.dart';
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

Finder get _content => find.byType(ProvidedNotificationContent);
Finder get _fade =>
    find.ancestor(of: _content, matching: find.byType(Opacity)).first;
double opacity(WidgetTester tester) => tester.widget<Opacity>(_fade).opacity;
String displayed(WidgetTester tester) =>
    tester.widget<ProvidedNotificationContent>(_content).notification.appName;

Future<void> _mount(WidgetTester tester, _Notifications service,
    {bool reducedMotion = false}) async {
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
        child: const Stack(children: [DesktopNotificationArea()]),
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
  testWidgets('entrance moves down and fades in; removal shrinks and fades out',
      (tester) async {
    final service = _Notifications();
    addTearDown(service.dispose);
    await _mount(tester, service);
    expect(_content, findsNothing);
    service.show([notification('a')]);
    await _flushUpdate(tester);
    expect(opacity(tester), 0);
    final slide = find
        .ancestor(of: _content, matching: find.byType(FractionalTranslation))
        .first;
    expect(tester.widget<FractionalTranslation>(slide).translation.dy,
        lessThan(0));
    await tester.pump(kDefaultDuration ~/ 2);
    expect(opacity(tester), inExclusiveRange(0, 1));
    await tester.pump(kDefaultDuration);
    expect(opacity(tester), 1);
    service.show([]);
    await _flushUpdate(tester);
    expect(_content, findsOneWidget);
    await tester.pump(kDefaultDuration ~/ 2);
    expect(opacity(tester), inExclusiveRange(0, 1));
    final transform =
        find.ancestor(of: _content, matching: find.byType(Transform)).first;
    expect(
        tester.widget<Transform>(transform).transform.entry(0, 0), lessThan(1));
    await tester.pump(kDefaultDuration + const Duration(milliseconds: 1));
    expect(_content, findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'replacement exits first and only shows the latest pending target',
      (tester) async {
    final service = _Notifications()..show([notification('a')]);
    addTearDown(service.dispose);
    await _mount(tester, service);
    await tester.pumpAndSettle();
    service.show([notification('b')]);
    await _flushUpdate(tester);
    await tester.pump(kDefaultDuration ~/ 2);
    expect(displayed(tester), 'a');
    service.show([notification('c')]);
    await _flushUpdate(tester);
    // Step just past the endpoint to avoid floating-point timing rounding.
    await tester.pump(kDefaultDuration ~/ 2 + const Duration(milliseconds: 1));
    expect(displayed(tester), 'c');
    expect(opacity(tester), 0);
    await tester.pumpAndSettle();
    expect(opacity(tester), 1);
    final updated = notification('c').copyWith(summary: 'Updated');
    service.show([updated]);
    await _flushUpdate(tester);
    expect(opacity(tester), 1);
    expect(tester.widget<ProvidedNotificationContent>(_content).notification,
        same(updated));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'removal mid-entrance is continuous and clears pending replacements',
      (tester) async {
    final service = _Notifications()..show([notification('a')]);
    addTearDown(service.dispose);
    await _mount(tester, service);
    await tester.pump(kDefaultDuration ~/ 2);
    final before = opacity(tester);
    service.show([notification('b')]);
    await _flushUpdate(tester);
    expect(opacity(tester), closeTo(before, 0.00001));
    service.show([]);
    await _flushUpdate(tester);
    await tester.pump(kDefaultDuration + const Duration(milliseconds: 1));
    expect(_content, findsNothing);
    service.show([notification('c')]);
    await _flushUpdate(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(kDefaultDuration * 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion replaces and removes immediately',
      (tester) async {
    final service = _Notifications()..show([notification('a')]);
    addTearDown(service.dispose);
    await _mount(tester, service, reducedMotion: true);
    expect(opacity(tester), 1);
    service.show([notification('b')]);
    await _flushUpdate(tester);
    expect(displayed(tester), 'b');
    expect(opacity(tester), 1);
    service.show([]);
    await _flushUpdate(tester);
    expect(_content, findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
