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

import 'package:jappeos_services/jappeos_services.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../quick_setting_details_page.dart';
import '../quick_setting_item.dart';
import '../quick_setting_tile.dart';
import 'audio_quick_setting_util.dart';
import 'quick_setting_contributor.dart';
import 'quick_settings_details_controller.dart';

class AudioInputQuickSetting extends StatelessWidget
    implements QuickSettingContributor {
  const AudioInputQuickSetting({super.key});

  @override
  String get id => 'audio_input';

  @override
  QuickSettingContributorType get type => QuickSettingContributorType.slider;

  @override
  Icon? createIcon(BuildContext context) => null;

  @override
  bool get hasDetails => true;

  @override
  Widget buildDetails(BuildContext context) {
    final audio = context.watch<AudioService>();
    return QuickSettingDetailsPage(
      icon: _icon(audio),
      title: _title(),
      child: _AudioSettings(),
    );
  }

  @override
  bool canBuild(BuildContext context) {
    final audio = context.watch<AudioService>();
    return audio.devices.any((d) => d.direction == AudioDirection.input);
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioService>();
    final activeInput = audio.activeInputDevice;

    final item = QuickSettingSliderItem(
      id: id,
      icon: _icon(audio),
      value: activeInput?.volume ?? 0,
      hasDetails: hasDetails,
      onChanged: activeInput == null
          ? null
          : (p0) => audio.setDeviceVolume(activeInput, p0),
      onIconTap: activeInput == null
          ? null
          : () => audio.setDeviceMuted(activeInput, !activeInput.muted),
      onOpenDetails: () => QuickSettingsDetailsController.of(context).open(this),
    );

    return QuickSettingSliderTile(item: item);
  }

  String _title() => "Audio Input";

  IconData _icon(AudioService audio) {
    final device = audio.activeInputDevice;
    if (device == null) {
      return _iconFromMutedState(true);
    }

    return _iconFromMutedState(device.muted);
  }

  static IconData _iconFromMutedState([bool muted = false])
      => muted ? Icons.mic_off : Icons.mic;
}

class _AudioSettings extends StatelessWidget {
  const _AudioSettings();

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioService>();
    final devices = audio.devices.where((d) => d.direction == AudioDirection.input);
    if (devices.isEmpty) {
      return const Text('No audio input devices available');
    }
    return ListView.builder(
      shrinkWrap: true,
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final dev = devices.elementAt(index);
        return _AudioDeviceItem(
          key: ValueKey(dev.path),
          device: dev,
        );
      },
    );
  }
}

class _AudioDeviceItem extends StatelessWidget {
  final AudioDevice device;

  const _AudioDeviceItem({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioService>();
    assert(device.direction == AudioDirection.input);
    return GhostButton(
      onPressed: () => audio.setActiveInputDevice(device),
      leading: Icon(createIcon(device.type)),
      trailing: device == audio.activeInputDevice
          ? Icon(Icons.check)
          : null,
      child: Text(device.name).ellipsis(),
    );
  }
}