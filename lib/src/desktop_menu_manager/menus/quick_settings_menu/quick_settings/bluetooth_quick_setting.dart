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

class BluetoothQuickSetting extends StatelessWidget
    implements QuickSettingContributor {
  const BluetoothQuickSetting({super.key});

  @override
  String get id => 'bluetooth';

  @override
  QuickSettingContributorType get type => QuickSettingContributorType.chip;

  @override
  Icon? createIcon(BuildContext context) {
    return _isEnabled() ? Icon(_icon()) : null;
  }

  @override
  bool get hasDetails => true;

  @override
  Widget buildDetails(BuildContext context) {
    final enabled = _isEnabled();
    return QuickSettingDetailsPage(
      icon: _icon(),
      title: _title(),
      value: enabled,
      onToggle: (_) => _toggle(),
      child: enabled
          ? const _BluetoothNetworkList()
          : const Text('Bluetooth is off'),
    );
  }

  @override
  bool canBuild(BuildContext context) {
    /*final network = context.watch<NetworkManagerService>();
    return network.ethernetDevices.any((d) => !d.isUnavailable);*/
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _isEnabled();
    final subtitle = enabled ? 'On' : 'Off';
    final item = QuickSettingChipItem(
      id: id,
      title: _title(),
      icon: _icon(),
      isEnabled: enabled,
      subtitle: subtitle,
      hasDetails: hasDetails,
      onToggle: () => _toggle(),
      onOpenDetails: () => QuickSettingsDetailsController.of(context).open(this),
    );

    return QuickSettingChipTile(item: item);
  }

  String _title() => "Bluetooth";

  IconData _icon() => Icons.bluetooth;

  bool _isEnabled() => false;

  void _toggle() {}
}

class _BluetoothNetworkList extends StatefulWidget {
  const _BluetoothNetworkList();

  @override
  State<_BluetoothNetworkList> createState() => _BluetoothNetworkListState();
}

class _BluetoothNetworkListState extends State<_BluetoothNetworkList> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: 5,
      itemBuilder: (context, index) {
        return GhostButton(
          leading: Icon(Icons.bluetooth),
          trailing: Icon(Icons.check),
          child: Text(
            "Bluetooth Device $index",
            textAlign: TextAlign.start,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }
}