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
import 'quick_setting_contributor.dart';
import 'quick_settings_details_controller.dart';

class AudioQuickSetting extends StatelessWidget
    implements QuickSettingContributor {
  const AudioQuickSetting({super.key});

  @override
  String get id => 'audio';

  @override
  QuickSettingContributorType get type => QuickSettingContributorType.slider;

  @override
  Icon? createIcon(BuildContext context) {
    final audio = context.watch<AudioService>();
    return audio.activeOutputDevice != null ? Icon(_icon(audio)) : null;
  }

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
    return audio.devices.any((d) => d.direction == AudioDirection.output);
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioService>();
    final activeOutput = audio.activeOutputDevice;

    final item = QuickSettingSliderItem(
      id: id,
      icon: _icon(audio),
      value: activeOutput?.volume ?? 0,
      hasDetails: hasDetails,
      onChanged: activeOutput == null
          ? null
          : (p0) => audio.setDeviceVolume(activeOutput, p0),
      onIconTap: activeOutput == null
          ? null
          : () => audio.setDeviceMuted(activeOutput, !activeOutput.muted),
      onOpenDetails: () => QuickSettingsDetailsController.of(context).open(this),
    );

    return QuickSettingSliderTile(item: item);
  }

  String _title() => "Audio Output";

  IconData _icon(AudioService audio) {
    final device = audio.activeOutputDevice;
    if (device == null) {
      return _iconFromVolume(0, true);
    }

    return _iconFromVolume(device.volume, device.muted);
  }

  static IconData _iconFromVolume(double volume, [bool muted = false]) {
    if (muted) return Icons.volume_off;

    if (volume >= 0.5) {
      return Icons.volume_up;
    } else if (volume > 0) {
      return Icons.volume_down;
    } else {
      return Icons.volume_mute;
    }
  }
}

class _AudioSettings extends StatefulWidget {
  const _AudioSettings();

  @override
  State<_AudioSettings> createState() => _AudioSettingsState();
}

class _AudioSettingsState extends State<_AudioSettings> {
  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioService>();
    final devices = audio.devices.where((d) => d.direction == AudioDirection.output);
    if (devices.isEmpty) {
      return const Text('No audio output devices available');
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

class _AudioDeviceItem extends StatefulWidget {
  final AudioDevice device;

  const _AudioDeviceItem({super.key, required this.device});

  @override
  State<_AudioDeviceItem> createState() => _AudioDeviceItemState();
}

class _AudioDeviceItemState extends State<_AudioDeviceItem> {
  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioService>();
    assert(widget.device.direction == AudioDirection.output);
    return GhostButton(
      onPressed: () => audio.setActiveOutputDevice(widget.device),
      leading: Icon(Icons.speaker),
      trailing: widget.device == audio.activeOutputDevice
          ? Icon(Icons.check)
          : null,
      child: Text(widget.device.name).ellipsis(),
    );
  }
}