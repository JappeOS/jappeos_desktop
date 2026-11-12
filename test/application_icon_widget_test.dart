import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jdwm/jdwm.dart';
import 'package:jappeos_desktop/src/components/application_icon.dart';
import 'package:jappeos_desktop/src/provider/application_icon_service.dart';
import 'package:jappeos_desktop/src/provider/application_resolver.dart';

ResolvedApplication app(int revision,
        {String name = '',
        bool pixels = true,
        int viewId = 1,
        String groupId = 'test'}) =>
    ResolvedApplication(
        groupId: groupId,
        title: 'Test',
        window: ManagedWindowInfo(
            viewId: viewId,
            protocol: ManagedWindowProtocol.xdg,
            title: '',
            appId: '',
            visible: true,
            maximized: false,
            focused: true,
            metadata: ClientWindowMetadata(
                revision: revision,
                iconName: name,
                images: pixels
                    ? [
                        ClientIconImage(
                            width: 1,
                            height: 1,
                            scale: 1,
                            rgba: Uint8List.fromList([255, 0, 0, 255]))
                      ]
                    : [])));
void main() {
  Future<void> waitForPixels(WidgetTester tester) async {
    for (var attempt = 0; attempt < 10; attempt++) {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 25));
      });
      await tester.pump();
      if (tester
          .widgetList<RawImage>(find.byType(RawImage))
          .any((image) => image.image != null)) {
        return;
      }
    }
    fail('Client pixels did not decode');
  }

  testWidgets(
      'focused-window replacement retains the current icon while loading and decoding',
      (tester) async {
    final pending = Completer<File?>();
    final service = ApplicationIconService((_) => pending.future);
    Widget host(ResolvedApplication application) => MaterialApp(
        home: ApplicationIcon(
            application: application, service: service, size: 48));
    await tester.pumpWidget(host(app(1)));
    await waitForPixels(tester);
    final original = tester.widget<RawImage>(find.byType(RawImage)).image;
    await tester.pumpWidget(host(app(2, viewId: 2, name: 'loading')));
    expect(find.byType(Icon), findsNothing);
    expect(
        tester.widget<RawImage>(find.byType(RawImage)).image, same(original));
    await tester.pump();
    expect(
        tester.widget<RawImage>(find.byType(RawImage)).image, same(original));
    pending.complete(null);
    await tester.pump();
    expect(find.byType(Icon), findsNothing);
    expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
    for (var attempt = 0; attempt < 10; attempt++) {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 25));
      });
      await tester.pump();
      expect(find.byType(Icon), findsNothing);
      if (!identical(
          tester.widget<RawImage>(find.byType(RawImage)).image, original)) {
        break;
      }
    }
    expect(tester.widget<RawImage>(find.byType(RawImage)).image,
        isNot(same(original)));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('cached launcher icon has no generic-icon frame when recreated',
      (tester) async {
    final service = ApplicationIconService((_) async => null);
    final application = app(1);
    await service.sources(application, size: 48, dpr: 1);
    Widget host() => MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(devicePixelRatio: 1),
            child: ApplicationIcon(
                application: application, service: service, size: 48)));
    await tester.pumpWidget(host());
    expect(find.byType(Icon), findsNothing);
    expect(find.byType(RawImage), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(host());
    expect(find.byType(Icon), findsNothing);
    expect(find.byType(RawImage), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'launcher item reused for another app never displays the previous app icon',
      (tester) async {
    final pending = Completer<File?>();
    final service = ApplicationIconService((_) => pending.future);
    Widget host(ResolvedApplication application) => MaterialApp(
        home: ApplicationIcon(
            application: application, service: service, size: 48));
    await tester.pumpWidget(host(app(1)));
    await waitForPixels(tester);
    await tester
        .pumpWidget(host(app(1, viewId: 2, groupId: 'other', name: 'pending')));
    expect(find.byType(RawImage), findsNothing);
    expect(find.byType(Icon), findsNothing);
    pending.complete(null);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'client reset ignores stale lookup and refreshes without remounting',
      (tester) async {
    final pending = Completer<File?>();
    final service = ApplicationIconService((_) => pending.future);
    Widget host(ResolvedApplication app) => MaterialApp(
        home: ApplicationIcon(application: app, service: service, size: 48));
    await tester.pumpWidget(host(app(1, name: 'pending')));
    await tester.pumpWidget(host(app(2, pixels: false)));
    await tester.pump();
    expect(find.byType(Icon), findsOneWidget);
    pending.complete(null);
    await tester.pump();
    expect(find.byType(RawImage), findsNothing);
    expect(find.byType(Icon), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'invalid encoded icon falls through to client pixels and disposes on removal',
      (tester) async {
    final dir = Directory.systemTemp.createTempSync('icon-widget-');
    addTearDown(() => dir.deleteSync(recursive: true));
    final broken = File('${dir.path}/bad.png')..writeAsBytesSync([1, 2, 3]);
    final service = ApplicationIconService((_) async => broken);
    await tester.pumpWidget(MaterialApp(
        home: ApplicationIcon(
            application: app(1, name: 'broken'), service: service, size: 48)));
    for (var attempt = 0; attempt < 10; attempt++) {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      if (tester
          .widgetList<RawImage>(find.byType(RawImage))
          .any((image) => image.image?.width == 1)) {
        break;
      }
    }
    final images = tester.widgetList<RawImage>(find.byType(RawImage));
    expect(images.any((image) => image.image?.width == 1), isTrue);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
