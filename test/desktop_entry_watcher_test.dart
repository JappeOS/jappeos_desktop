import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freedesktop_desktop_entry/freedesktop_desktop_entry.dart';
import 'package:jappeos_desktop/src/provider/desktop_entry_provider.dart';

void main() {
  test('watches new directories, file changes, and directory replacement',
      () async {
    final root = await Directory.systemTemp.createTemp('desktop-watcher-');
    final applications = Directory('${root.path}/local/share/applications');
    Map<String, DesktopEntry> entries = {};
    final errors = <Object>[];
    var notifications = 0;
    final watcher = InstalledDesktopFilesWatcher(
      applicationDirectories: [applications.path],
      debounceDuration: const Duration(milliseconds: 10),
      loadEntries: () async {
        final result = <String, DesktopEntry>{};
        if (await applications.exists()) {
          await for (final file in applications.list()) {
            if (file is File && file.path.endsWith('.desktop')) {
              result[file.uri.pathSegments.last] =
                  DesktopEntry.parse(await file.readAsString());
            }
          }
        }
        return result;
      },
      onChanged: (value) {
        entries = value;
        notifications++;
      },
      onError: (error, _) => errors.add(error),
    );
    addTearDown(() async {
      await watcher.stopListening();
      await root.delete(recursive: true);
    });
    Future<void> waitFor(bool Function() condition) async {
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (!condition()) {
        if (DateTime.now().isAfter(deadline)) {
          fail(
              'Watcher did not update; entries: ${entries.keys}, errors: $errors');
        }
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    }

    await watcher.start();
    expect(entries, isEmpty);
    await applications.create(recursive: true);
    final app = File('${applications.path}/app.desktop');
    await app.writeAsString(
        '[Desktop Entry]\nType=Application\nName=First\nExec=true\n');
    await waitFor(() => entries.containsKey('app.desktop'));

    await app.writeAsString(
        '[Desktop Entry]\nType=Application\nName=Updated\nExec=true\n');
    await waitFor(
        () => entries['app.desktop']?.entries['Name']?.value == 'Updated');

    final temporary = File('${applications.path}/install.tmp');
    await temporary.writeAsString('[Desktop Entry]\nName=Second\nExec=true\n');
    await temporary.rename('${applications.path}/second.desktop');
    await waitFor(() => entries.length == 2);

    await app.delete();
    await waitFor(() => !entries.containsKey('app.desktop'));
    await applications.delete(recursive: true);
    await waitFor(() => entries.isEmpty);
    await applications.create();
    await app.writeAsString('[Desktop Entry]\nName=Reinstalled\nExec=true\n');
    await waitFor(() => entries.containsKey('app.desktop'));

    await watcher.stopListening();
    final countAtStop = notifications;
    await app.delete();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(notifications, countAtStop);
    expect(errors, isEmpty);
  });
}
