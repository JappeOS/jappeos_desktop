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

import 'package:jappeos_services/jappeos_services.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../quick_setting_details_page.dart';
import '../quick_setting_item.dart';
import '../quick_setting_tile.dart';
import 'quick_setting_contributor.dart';
import 'quick_settings_details_controller.dart';

class EthernetQuickSetting extends StatelessWidget
    implements QuickSettingContributor {
  const EthernetQuickSetting({super.key});

  @override
  String get id => 'ethernet';

  @override
  QuickSettingContributorType get type => QuickSettingContributorType.chip;

  @override
  Icon? createIcon(BuildContext context) {
    final network = context.watch<NetworkManagerService>();
    return network.ethernetDevices.any((d) => d.isConnected)
        ? Icon(_icon(network))
        : null;
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
          ? const _EthernetNetworkList()
          : const Text('Ethernet is off'),
    );
  }

  @override
  bool canBuild(BuildContext context) {
    final network = context.watch<NetworkManagerService>();
    return network.ethernetDevices.any((d) => !d.isUnavailable);
  }

  @override
  Widget build(BuildContext context) {
    final network = context.watch<NetworkManagerService>();

    final ethernetDevices = network.ethernetDevices.where((d) => !d.isUnavailable);
    assert(ethernetDevices.isNotEmpty, 'No Ethernet devices available');

    final enabled = _isEnabled(network);
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
      title: _title(network),
      icon: _icon(network),
      isEnabled: enabled,
      subtitle: subtitle,
      hasDetails: hasDetails,
      onToggle: () => _toggle(network),
      onOpenDetails: () => QuickSettingsDetailsController.of(context).open(this),
    );

    return QuickSettingChipTile(item: item);
  }

  String _title(NetworkManagerService p) {
    final availableDevices = p.ethernetDevices.where((d) => !d.isUnavailable).length;
    return availableDevices == 1
          ? 'Ethernet'
          : 'Ethernet ($availableDevices)';
  }

  IconData _icon(NetworkManagerService _) => Icons.cable;

  bool _isEnabled(NetworkManagerService p)
      => p.ethernetDevices.any((d) => d.state == NetworkDeviceState.connected);

  void _toggle(NetworkManagerService p)
      => _isEnabled(p)
          ? p.ethernetDevices.forEach((d) => p.setEnabled(d, false))
          : p.ethernetDevices.forEach((d) => p.setEnabled(d, true));
}

class _EthernetNetworkList extends StatefulWidget {
  const _EthernetNetworkList();

  @override
  State<_EthernetNetworkList> createState() => _EthernetNetworkListState();
}

class _EthernetNetworkListState extends State<_EthernetNetworkList> {
  @override
  Widget build(BuildContext context) {
    final network = context.watch<NetworkManagerService>();
    final devices = network.ethernetDevices.where((d) => !d.isUnavailable);
    if (devices.isEmpty) {
      return const Text('No Ethernet networks available');
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final dev = devices.elementAt(index);
        return GhostButton(
          leading: Icon(Icons.cable),
          trailing: dev.state != NetworkDeviceState.disconnected
                 && dev.state != NetworkDeviceState.connected
          ? const CircularProgressIndicator()
          : Switch(
            value: dev.state != NetworkDeviceState.disconnected,
            onChanged: (value) => network.setEnabled(dev, value),
          ),
          child: Text(
            dev.id,
            textAlign: TextAlign.start,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }
}