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

import '../quick_setting_item.dart';
import '../quick_setting_tile.dart';
import 'quick_setting_contributor.dart';

class EthernetQuickSetting extends StatelessWidget
    implements QuickSettingContributor {
  const EthernetQuickSetting({super.key});

  @override
  String get id => 'ethernet';

  @override
  QuickSettingContributorType get type => QuickSettingContributorType.chip;

  @override
  IconData? createIcon(BuildContext context) {
    final network = context.watch<NetworkManagerService>();
    return network.ethernetDevices.isNotEmpty ? Icons.cable : null;
  }

  @override
  bool canBuild(BuildContext context) {
    final network = context.watch<NetworkManagerService>();
    return network.ethernetDevices.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final network = context.watch<NetworkManagerService>();

    final ethernetDevices = network.ethernetDevices;
    if (ethernetDevices.isEmpty) {
      throw Exception('No Ethernet devices available');
    }

    final enabled = ethernetDevices.any((d) => d.isConnected);
    String subtitle = '';
    if (enabled) {
      int i = 0;
      for (final d in ethernetDevices) {
        subtitle += (i > 0 ? ', ' : '');

        if (d.state == NetworkDeviceState.connecting) {
          subtitle += '...';
        } else if (d.state == NetworkDeviceState.disconnected) {
          subtitle += 'Off';
        } else if (d.state == NetworkDeviceState.connected) {
          subtitle += 'Connected';
        } else {
          subtitle += 'Unknown';
        }

        i++;
      }
    } else {
      subtitle = 'Off';
    }

    final item = QuickSettingChipItem(
      id: id,
      title: ethernetDevices.length == 1
          ? 'Ethernet'
          : 'Ethernet (${ethernetDevices.length})',
      icon: Icons.cable,
      isEnabled: enabled,
      subtitle: subtitle,
      hasDetails: enabled,
      onToggle: () {
        // network.setWifiEnabled(...)
      },
      onOpenDetails: () {
        // open Wi-Fi panel
      },
    );

    return QuickSettingChipTile(item: item);
  }

  @override
  Widget? buildDetails(BuildContext context) => null;
}
