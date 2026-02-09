import 'package:jappeos_desktop/src/desktop_menu_manager/menus/quick_settings_menu/quick_setting_item.dart';
import 'package:jappeos_services/jappeos_services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../quick_setting_tile.dart';
import 'quick_setting_contributor.dart';

class BatteryQuickSetting extends StatelessWidget
    implements QuickSettingContributor {
  const BatteryQuickSetting({super.key});

  @override
  String get id => 'battery';

  @override
  QuickSettingContributorType get type => QuickSettingContributorType.power;

  @override
  Icon? createIcon(BuildContext context) {
    final power = context.watch<PowerManagerService>();
    final devices = power.devices.where((d) =>
        d.type == BatteryDeviceType.battery && d.isPowerSupply);
    if (devices.isEmpty) {
      return const Icon(Symbols.power_settings_new);
    }

    final device = devices.first;
    return _getIcon(device);
  }

  @override
  bool get hasDetails => false;

  @override
  Widget buildDetails(BuildContext context) => throw UnimplementedError();

  @override
  bool canBuild(BuildContext context) {
    final power = context.watch<PowerManagerService>();
    return power.devices.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final power = context.watch<PowerManagerService>();

    final powerDevices = power.devices;
    if (powerDevices.isEmpty) {
      throw Exception('No battery devices available');
    }

    List<QuickSettingPowerItem> items = [];
    for (final d in powerDevices) {
      if (d.type == BatteryDeviceType.battery && d.isPowerSupply) {
        bool isCharging = d.state == BatteryDeviceState.charging;
        final item = QuickSettingPowerItem(
          id: d.id,
          icon: _getIcon(d),
          label: "${d.chargePercentage.round()}%",
          tooltip: "${d.chargePercentage.round()}% • ${d.state.name} • ${!isCharging ? "${d.timeToEmpty.inMinutes} min to empty" : "${d.timeToFull.inMinutes} min to full"}",
        );
        items.add(item);
      }
    }

    return QuickSettingPowerTile(items: items);
  }

  Icon _getIcon(BatteryDevice device) {
    switch (device.state) {
      case BatteryDeviceState.charging:
        return _getIconCharging(device);
      case BatteryDeviceState.unknown:
        return const Icon(Symbols.battery_unknown);
      default:
        return _getIconDefault(device);
    }
  }

  Icon _getIconCharging(BatteryDevice device) {
    final batteryPercent = device.chargePercentage;
    if (batteryPercent <= 0) {
      return const Icon(Symbols.battery_charging_full, fill: 0.0);
    } else if (batteryPercent <= 14) {
      return const Icon(Symbols.battery_charging_20);
    } else if (batteryPercent <= 28) {
      return const Icon(Symbols.battery_charging_30);
    } else if (batteryPercent <= 42) {
      return const Icon(Symbols.battery_charging_50);
    } else if (batteryPercent <= 57) {
      return const Icon(Symbols.battery_charging_60);
    } else if (batteryPercent <= 71) {
      return const Icon(Symbols.battery_charging_80);
    } else if (batteryPercent <= 85) {
      return const Icon(Symbols.battery_charging_90);
    } else {
      return const Icon(Symbols.battery_charging_full, fill: 1.0);
    }
  }

  Icon _getIconDefault(BatteryDevice device) {
    final batteryPercent = device.chargePercentage;
    if (batteryPercent <= 0) {
      return const Icon(Symbols.battery_0_bar);
    } else if (batteryPercent <= 14) {
      return const Icon(Symbols.battery_1_bar);
    } else if (batteryPercent <= 28) {
      return const Icon(Symbols.battery_2_bar);
    } else if (batteryPercent <= 42) {
      return const Icon(Symbols.battery_3_bar);
    } else if (batteryPercent <= 57) {
      return const Icon(Symbols.battery_4_bar);
    } else if (batteryPercent <= 71) {
      return const Icon(Symbols.battery_5_bar);
    } else if (batteryPercent <= 85) {
      return const Icon(Symbols.battery_6_bar);
    } else {
      return const Icon(Symbols.battery_full);
    }
  }
}