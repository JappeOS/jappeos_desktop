import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:freedesktop_desktop_entry/freedesktop_desktop_entry.dart';
import 'package:jdwm/jdwm.dart';
import 'package:jappeos_desktop/src/provider/application_icon_service.dart';
import 'package:jappeos_desktop/src/provider/application_resolver.dart';

ClientIconImage pixels(int size, {int scale = 1}) => ClientIconImage(
      width: size,
      height: size,
      scale: scale,
      rgba: Uint8List(size * size * 4),
    );
ResolvedApplication resolved({
  int revision = 1,
  String name = 'client',
  List<ClientIconImage>? images,
}) =>
    ResolvedApplication(
      groupId: 'test',
      title: 'Test',
      desktopId: 'test.desktop',
      entry: DesktopEntry.parse('[Desktop Entry]\nName=Test\nIcon=desktop\n'),
      window: ManagedWindowInfo(
        viewId: 1,
        protocol: ManagedWindowProtocol.xdg,
        title: '',
        appId: 'test',
        visible: true,
        maximized: false,
        focused: true,
        metadata: ClientWindowMetadata(
          revision: revision,
          iconName: name,
          images: images ?? [pixels(32)],
        ),
      ),
    );
void main() {
  test(
      'multiple DPI requests stay cached and window removal releases all variants',
      () async {
    final service = ApplicationIconService((_) async => null);
    final application = resolved();
    final normal = service.sources(application, size: 32, dpr: 1);
    final hidpi = service.sources(application, size: 32, dpr: 2);
    await Future.wait([normal, hidpi]);
    expect(identical(normal, service.sources(application, size: 32, dpr: 1)),
        isTrue);
    expect(identical(hidpi, service.sources(application, size: 32, dpr: 2)),
        isTrue);
    service.retainWindows({});
    expect(identical(normal, service.sources(application, size: 32, dpr: 1)),
        isFalse);
  });

  test(
    'client name, client pixels, desktop fallback; fractional scale and caching',
    () async {
      final dir = Directory.systemTemp.createTempSync('desktop-icons-');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/icon.png')..writeAsBytesSync([1, 2, 3]);
      final calls = <IconQuery>[];
      final service = ApplicationIconService((query) async {
        calls.add(query);
        return file;
      });
      final application = resolved();
      final first = service.sources(application, size: 48, dpr: 1.5);
      expect(
        identical(first, service.sources(application, size: 48, dpr: 1.5)),
        isTrue,
      );
      final sources = await first;
      expect(sources.first.bytes, isNotNull);
      expect(sources[1].pixels, isNotNull);
      expect(calls.map((q) => q.name), ['client', 'desktop']);
      expect(calls.first.size, 48);
      expect(calls.first.scale, 2);
      service.invalidate();
      await service.sources(application, size: 48, dpr: 1.5);
      expect(calls.length, 4);
      await service.sources(resolved(revision: 2), size: 48, dpr: 1.5);
      expect(calls.length, 6);
    },
  );
  test(
    'client names cannot read host files and broken theme lookup falls back',
    () async {
      final calls = <String>[];
      final service = ApplicationIconService((q) async {
        calls.add(q.name);
        throw const FileSystemException();
      });
      final sources = await service.sources(
        resolved(name: '/etc/icon.png'),
        size: 32,
        dpr: 1,
      );
      expect(calls, ['desktop']);
      expect(sources.single.pixels, isNotNull);
      expect(
        await service.sources(
          resolved(revision: 2, name: '', images: []),
          size: 32,
          dpr: 1,
        ),
        isEmpty,
      );
    },
  );
  test(
    'raster selection avoids upscaling and respects requested physical size',
    () {
      final images = [pixels(32), pixels(128, scale: 2), pixels(64)];
      expect(
        ApplicationIconService.orderedImages(images, 40, 1.5).first.width,
        64,
      );
      expect(
        ApplicationIconService.orderedImages(images, 40, 2).first.width,
        128,
      );
      expect(
        ApplicationIconService.orderedImages(images, 200, 2).first.width,
        128,
      );
    },
  );
}
