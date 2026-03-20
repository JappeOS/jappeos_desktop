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

// ignore_for_file: avoid_function_literals_in_foreach_calls

import 'package:collection/collection.dart';
import 'package:jappeos_services/jappeos_services.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../quick_setting_details_page.dart';
import '../quick_setting_item.dart';
import '../quick_setting_tile.dart';
import 'quick_setting_contributor.dart';
import 'quick_settings_details_controller.dart';

class WifiQuickSetting extends StatelessWidget
    implements QuickSettingContributor {
  const WifiQuickSetting({super.key});

  @override
  String get id => 'wifi';

  @override
  QuickSettingContributorType get type => QuickSettingContributorType.chip;

  @override
  Icon? createIcon(BuildContext context) {
    final network = context.watch<NetworkManagerService>();
    final ic = _getIcon(network.wifiDevices);
    return ic.$2 ? Icon(ic.$1) : null;
  }

  @override
  bool get hasDetails => true;

  @override
  Widget buildDetails(BuildContext context) {
    final network = context.watch<NetworkManagerService>();
    final enabled = _isEnabled(network);
    return QuickSettingDetailsPage(
      icon: _icon(network),
      title: _title(network),
      value: enabled,
      onToggle: (_) => _toggle(network),
      child: enabled
          ? const _WifiNetworkList()
          : const Text('Wi-Fi is off'),
    );
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

    final enabledDevices = wifiDevices.where((d) => d.enabled);
    final enabled = _isEnabled(network);
    String subtitle = '';
    if (enabled) {
      int i = 0;
      for (final d in enabledDevices) {
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
      title: _title(network),
      icon: _icon(network),
      isEnabled: enabled,
      subtitle: subtitle,
      hasDetails: true,
      onToggle: () => _toggle(network),
      onOpenDetails: () => QuickSettingsDetailsController.of(context).open(this),
    );

    return QuickSettingChipTile(item: item);
  }

  String _title(NetworkManagerService p) => p.wifiDevices.length == 1
          ? 'Wi-Fi'
          : 'Wi-Fi (${p.wifiDevices.length})';

  IconData _icon(NetworkManagerService p) => _getIcon(p.wifiDevices).$1;

  bool _isEnabled(NetworkManagerService p)
      => p.wifiDevices.any((d) => d.enabled);

  void _toggle(NetworkManagerService p)
      => _isEnabled(p)
          ? p.wifiDevices.forEach((d) => p.setEnabled(d, false))
          : p.setEnabled(p.wifiDevices.first, true);

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
}

class _WifiNetworkList extends StatefulWidget {
  const _WifiNetworkList({super.key});

  @override
  State<_WifiNetworkList> createState() => _WifiNetworkListState();
}

class _WifiNetworkListState extends State<_WifiNetworkList> {
  @override
  void initState() {
    super.initState();
    final network = context.read<NetworkManagerService>();
    for (final device in network.wifiDevices) {
      network.scanWifi(device);
    }
  }

  @override
  Widget build(BuildContext context) {
    final network = context.watch<NetworkManagerService>();

    final wifiAps = network.wifiDevices.expand((d) => d.accessPoints).toList();
    if (wifiAps.isEmpty) {
      return const Text('No Wi-Fi networks available');
    }

    return ListView.builder(itemBuilder: (context, index) {
      final ap = wifiAps.elementAt(index);
      return GhostButton(
        leading: Icon(Icons.wifi),
        trailing: ap.connected ? const Icon(Icons.check) : null,
        child: Text(
          ap.ssid,
          textAlign: TextAlign.start,
          overflow: TextOverflow.ellipsis,
        ),
      );
    });
  }
}