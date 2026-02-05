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

import 'package:collection/collection.dart';
import 'package:jappeos_services/jappeos_services.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../control_center_menu.dart';
import '../quick_setting_tile.dart';
import 'quick_setting_contributor.dart';

class WifiQuickSetting extends StatelessWidget
    implements QuickSettingContributor {
  const WifiQuickSetting({super.key});

  @override
  String get id => 'wifi';

  @override
  QuickSettingContributorType get type => QuickSettingContributorType.chip;

  @override
  IconData? createIcon(BuildContext context) {
    final network = context.watch<NetworkManagerService>();
    final ic = _getIcon(network.wifiDevices);
    return ic.$2 ? ic.$1 : null;
  }

  @override
  bool canBuild(BuildContext context) {
    final network = context.watch<NetworkManagerService>();
    return network.wifiDevices.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final network = context.watch<NetworkManagerService>();

    final wifiDevices = network.wifiDevices;
    if (wifiDevices.isEmpty) {
      throw Exception('No Wi-Fi devices available');
    }

    final connDevices = wifiDevices.where((d) => d.isConnected);
    final enabled = connDevices.isNotEmpty;
    String subtitle = '';
    if (enabled) {
      int i = 0;
      for (final d in connDevices) {
        subtitle += (i > 0 ? ', ' : '');

        if (d.state == NetworkDeviceState.connecting) {
          subtitle += '...';
        } else if (d.state == NetworkDeviceState.disconnected) {
          subtitle += 'Off';
        } else if (d.state == NetworkDeviceState.connected) {
          subtitle += d.accessPoints
                    .firstWhereOrNull((ap) => ap.connected)
                    ?.ssid ??
                'Unknown';
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
      title: wifiDevices.length == 1
          ? 'Wi-Fi'
          : 'Wi-Fi (${wifiDevices.length})',
      icon: _getIcon(wifiDevices).$1,
      isEnabled: enabled,
      subtitle: subtitle,
      hasDetails: true,
      onToggle: () {
        // network.setWifiEnabled(...)
      },
      onOpenDetails: () {
        // open Wi-Fi panel
      },
    );

    return QuickSettingChipTile(item: item);
  }

  (IconData, bool) _getIcon(Iterable<NetworkWifiDevice> devices) {
    if (devices.isEmpty) {
      return (Icons.signal_wifi_off, false);
    }

    int sumSignal = 0;
    int connectedCount = 0;

    bool hasConnecting = false;
    bool hasUnknown = false;

    for (final device in devices) {
      switch (device.state) {
        case NetworkDeviceState.connected:
          final conn = device.activeConnection;
          if (conn == null) {
            hasUnknown = true;
          } else {
            sumSignal += conn.signalStrength;
            connectedCount++;
          }
          break;

        case NetworkDeviceState.connecting:
          hasConnecting = true;
          break;

        case NetworkDeviceState.disconnected:
          // Nothing to track
          break;

        default:
          hasUnknown = true;
          break;
      }
    }

    // 1 One or more connected, average signal strength
    if (connectedCount > 0) {
      final avgSignal = sumSignal ~/ connectedCount;

      if (avgSignal >= 75) {
        return (Icons.signal_wifi_4_bar, true);
      } else if (avgSignal >= 50) {
        return (Icons.network_wifi_3_bar, true);
      } else if (avgSignal >= 25) {
        return (Icons.network_wifi_2_bar, true);
      } else {
        return (Icons.network_wifi_1_bar, true);
      }
    }

    // 2 None connected, but one or more connecting
    if (hasConnecting) {
      return (Icons.signal_wifi_statusbar_null, true);
    }

    // 3 All disconnected except unknown(s)
    if (hasUnknown) {
      return (Icons.signal_wifi_bad, true);
    }

    // 4 All disconnected
    return (Icons.signal_wifi_off, false);
  }

  @override
  Widget? buildDetails(BuildContext context) => null;
}
