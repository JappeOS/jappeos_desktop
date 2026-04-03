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
import '../osd_overlay_mixin.dart';
import '../osd_panel.dart';

class AudioOverlay extends StatefulWidget {
  const AudioOverlay({super.key});

  @override
  State<AudioOverlay> createState() => _AudioOverlayState();
}

class _AudioOverlayState extends State<AudioOverlay>
    with OsdOverlayMixin<AudioOverlay> {

  @override
  List<Listenable> get listenables {
    return [context.read<AudioService>()];
  }

  @override
  OsdData? buildOsdData() {
    final audio = context.read<AudioService>();
    final activeDevice = audio.activeOutputDevice;
    if (activeDevice == null) return null;
    final volume = activeDevice.volume;
    final muted = activeDevice.muted;

    final icon = muted || volume <= 0
        ? Icons.volume_off
        : volume < 0.5
            ? Icons.volume_down
            : Icons.volume_up;

    return OsdBarData(
      label: 'Volume',
      icon: icon,
      value: volume,
      text: muted ? 'Muted' : '${(volume * 100).round()}%',
    );
  }

  @override
  Widget build(BuildContext context) => buildOverlay();
}