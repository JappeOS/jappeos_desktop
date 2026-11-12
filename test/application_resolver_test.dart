import 'package:flutter_test/flutter_test.dart';
import 'package:freedesktop_desktop_entry/freedesktop_desktop_entry.dart';
import 'package:jdwm/jdwm.dart';
import 'package:jappeos_desktop/src/provider/application_resolver.dart';

DesktopEntry app(String name, {String? wmClass}) => DesktopEntry.parse(
      '[Desktop Entry]\nType=Application\nName=$name\nIcon=$name\n${wmClass == null ? '' : 'StartupWMClass=$wmClass\n'}',
    );
ManagedWindowInfo window({
  ManagedWindowProtocol protocol = ManagedWindowProtocol.xdg,
  String id = '',
  String cls = '',
  String instance = '',
  int view = 1,
}) =>
    ManagedWindowInfo(
      viewId: view,
      protocol: protocol,
      title: 'Document',
      appId: id,
      visible: true,
      maximized: false,
      focused: false,
      metadata: ClientWindowMetadata(wmClass: cls, wmInstance: instance),
    );

void main() {
  test('Wayland IDs, suffix and case fallback share the launcher identity', () {
    final resolver = ApplicationResolver({
      'org.example.Editor.desktop': app('Editor'),
    });
    for (final id in [
      'org.example.Editor',
      'org.example.Editor.desktop',
      'ORG.EXAMPLE.EDITOR',
    ]) {
      final result = resolver.forWindow(window(id: id));
      expect(result.desktopId, 'org.example.Editor.desktop');
      expect(result.groupId, resolver.forEntry(id).groupId);
    }
    expect(resolver.forWindow(window(id: 'Document')).entry, isNull);
  });
  test('StartupWMClass matches class before instance and desktop IDs', () {
    final resolver = ApplicationResolver({
      'wine-editor.desktop': app('Wine Editor', wmClass: 'editor.exe'),
      'editor.exe.desktop': app('Other'),
      'instance.desktop': app('Instance', wmClass: 'instance'),
    });
    expect(
      resolver
          .forWindow(
            window(
              protocol: ManagedWindowProtocol.xwayland,
              cls: 'editor.exe',
              instance: 'instance',
            ),
          )
          .desktopId,
      'wine-editor.desktop',
    );
    expect(
      resolver
          .forWindow(window(protocol: ManagedWindowProtocol.xwayland, instance: 'EDITOR.EXE'))
          .desktopId,
      'wine-editor.desktop',
    );
    expect(
      resolver
          .forWindow(window(protocol: ManagedWindowProtocol.xwayland, cls: 'instance'))
          .desktopId,
      'instance.desktop',
    );
  });
  test('ambiguous strong matches do not fall through to guesses', () {
    final resolver = ApplicationResolver({
      'a.desktop': app('A', wmClass: 'shared'),
      'b.desktop': app('B', wmClass: 'shared'),
      'shared.desktop': app('Guess'),
    });
    expect(
      resolver.forWindow(window(protocol: ManagedWindowProtocol.xwayland, cls: 'shared')).entry,
      isNull,
    );
    final collision = ApplicationResolver({
      'Foo.desktop': app('A'),
      'foo.desktop': app('B'),
    });
    expect(collision.forEntry('FOO').entry, isNull);
    expect(collision.forEntry('Foo').title, 'A');
  });
  test(
    'unknown windows retain labels and stable grouping without title matching',
    () {
      final resolver = ApplicationResolver({});
      expect(resolver.forWindow(window()).groupId, 'window:1');
      expect(resolver.forWindow(window(view: 2)).groupId, 'window:2');
      expect(
        resolver.forWindow(window(protocol: ManagedWindowProtocol.xwayland, cls: 'Wine')).groupId,
        'xwayland:Wine',
      );
      expect(resolver.forWindow(window()).title, 'Document');
    },
  );
}
