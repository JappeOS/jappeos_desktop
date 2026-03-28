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
import 'package:material_symbols_icons/symbols.dart';
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

    final enabled = _isEnabled(network);
    String subtitle = '';
    if (enabled) {
      int i = 0;
      for (final d in wifiDevices) {
        subtitle += (i > 0 ? ', ' : '');

        if (d.state == NetworkDeviceState.connecting) {
          subtitle += '...';
        } else if (d.state == NetworkDeviceState.disconnected) {
          subtitle += 'Online';
        } else if (d.state == NetworkDeviceState.unavailable) {
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
      => p.wifiDevices.any((d) => !d.isUnavailable);

  void _toggle(NetworkManagerService p)
      => _isEnabled(p)
          ? p.wifiDevices.forEach((d) => p.setEnabled(d, false))
          : p.setEnabled(p.wifiDevices.first, true);

  (IconData i, bool show) _getIcon(Iterable<NetworkWifiDevice> devices) {
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

        case NetworkDeviceState.unavailable:
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

      return (_iconFromSignalStrenth(avgSignal), true);
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

  static IconData _iconFromSignalStrenth(int strength, [bool lock = false]) {
    if (strength >= 75) {
      return lock ? Icons.signal_wifi_4_bar_lock : Icons.signal_wifi_4_bar;
    } else if (strength >= 50) {
      return lock ? Symbols.network_wifi_3_bar_locked : Symbols.network_wifi_3_bar;
    } else if (strength >= 25) {
      return lock ? Symbols.network_wifi_2_bar_locked : Symbols.network_wifi_2_bar;
    } else {
      return lock ? Symbols.network_wifi_1_bar_locked : Symbols.network_wifi_1_bar;
    }
  }
}

class _WifiNetworkList extends StatefulWidget {
  const _WifiNetworkList();

  @override
  State<_WifiNetworkList> createState() => _WifiNetworkListState();
}

class _WifiNetworkListState extends State<_WifiNetworkList> {
  final List<Object> _shownDetails = [];
  final Set<Object> _scannedDevices = {};

  @override
  Widget build(BuildContext context) {
    final network = _shownDetails.isEmpty
        ? context.watch<NetworkManagerService>()
        : context.read<NetworkManagerService>();

    final devices = network.wifiDevices.where((d) => !d.isUnavailable);

    for (final device in devices) {
      if (!_scannedDevices.contains(device.path)) {
        _scannedDevices.add(device.path);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          network.scanWifi(device);
        });
      }
    }

    final wifiAps = _cleanAndOrderAccessPoints(
      devices.expand((d) => d.accessPoints).toList(),
    );

    if (wifiAps.isEmpty) {
      return const Text('No Wi-Fi networks available');
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: wifiAps.length,
      itemBuilder: (context, index) {
        final ap = wifiAps.elementAt(index);
        return _WifiNetworkItem(
          key: ValueKey(ap.path),
          ap: ap,
          onShowDetailsChanged: (show) {
            setState(() {
              if (show) {
                _shownDetails.add(ap.path);
              } else {
                _shownDetails.remove(ap.path);
              }
            });
          },
        );
      },
    );
  }

  List<WifiAccessPoint> _cleanAndOrderAccessPoints(List<WifiAccessPoint> accessPoints) {
    bool isBetter(WifiAccessPoint a, WifiAccessPoint b) {
      if (a.connected != b.connected) return a.connected; // connected first
      if (a.strength != b.strength) return a.strength > b.strength; // stronger first
      if (a.frequency != b.frequency) return a.frequency > b.frequency; // higher freq first
      return a.path.toString().compareTo(b.path.toString()) < 0; // stable fallback
    }

    // 1) Deduplicate exact same AP object path (defensive).
    final byPath = <String, WifiAccessPoint>{};
    for (final ap in accessPoints) {
      final pathKey = ap.path.toString();
      final existing = byPath[pathKey];
      if (existing == null || isBetter(ap, existing)) {
        byPath[pathKey] = ap;
      }
    }

    // 2) Collapse duplicates by SSID+security (same network name from multiple BSSIDs/radios).
    final byNetwork = <String, WifiAccessPoint>{};
    for (final ap in byPath.values) {
      final ssid = ap.ssid.trim();
      if (ssid.isEmpty) continue;
      final networkKey = '${ssid.toLowerCase()}|${ap.security.toLowerCase()}';
      final existing = byNetwork[networkKey];
      if (existing == null || isBetter(ap, existing)) {
        byNetwork[networkKey] = ap;
      }
    }

    // 3) Final deterministic ordering.
    final result = byNetwork.values.toList()
      ..sort((a, b) {
        if (a.connected != b.connected) return (b.connected ? 1 : 0) - (a.connected ? 1 : 0);
        final strengthCmp = b.strength.compareTo(a.strength);
        if (strengthCmp != 0) return strengthCmp;
        final freqCmp = b.frequency.compareTo(a.frequency);
        if (freqCmp != 0) return freqCmp;
        final ssidCmp = a.ssid.toLowerCase().compareTo(b.ssid.toLowerCase());
        if (ssidCmp != 0) return ssidCmp;
        return a.path.toString().compareTo(b.path.toString());
      });

    return List<WifiAccessPoint>.unmodifiable(result);
  }
}

class _WifiNetworkItem extends StatefulWidget {
  final WifiAccessPoint ap;
  final void Function(bool)? onShowDetailsChanged;

  const _WifiNetworkItem({super.key, required this.ap, this.onShowDetailsChanged});

  @override
  State<_WifiNetworkItem> createState() => _WifiNetworkItemState();
}

class _WifiNetworkItemState extends State<_WifiNetworkItem> {
  bool _hovered = false;
  bool _showDetails = false;
  bool _connecting = false;
  String _password = '';
  String _passwordError = '';

  bool get _hasSecurity => widget.ap.security.isNotEmpty;
  bool get _isConnected => widget.ap.connected;

  @override
  void dispose() {
    if (_showDetails) {
      widget.onShowDetailsChanged?.call(false);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _buildBase(
      onPressed: () async {
        if (_connecting) return;
        if (!_showDetails && _isConnected) {
          await _disconnect();
          return;
        }
        if (!_showDetails && !await _tryConnect() && mounted) {
          setState(() {
            _passwordError = '';
            _showDetails = true;
            widget.onShowDetailsChanged?.call(true);
          });
        }
      },
      onTapOutside: () => setState(() {
        _showDetails = false;
        widget.onShowDetailsChanged?.call(false);
      }),
      onHover: (v) => setState(() => _hovered = v),
      hasHover: _hovered,
      theme: theme,
      child: _buildContent(theme),
    );
  }

  Widget _buildBase({
    required Widget child,
    required ThemeData theme,
    VoidCallback? onTapOutside,
    VoidCallback? onPressed,
    void Function(bool)? onHover,
    bool hasHover = false,
  }) => TapRegion(
    onTapOutside: (_) => onTapOutside?.call(),
    onTapInside: _showDetails ? (_) => onPressed?.call() : null,
    behavior: HitTestBehavior.translucent,
    child: MouseRegion(
      onEnter: (_) => onHover?.call(true),
      onExit: (_) => onHover?.call(false),
      opaque: false,
      hitTestBehavior: HitTestBehavior.translucent,
      child: _showDetails
      ? Padding(
        padding: EdgeInsets.symmetric(vertical: 4 * theme.scaling),
        child: Card(
          filled: true,
          fillColor: hasHover
              ? theme.colorScheme.secondary
              : theme.colorScheme.card,
          child: child,
        ),
      )
      : GhostButton(
        onPressed: onPressed,
        child: child,
      ),
    ),
  );

  Widget _buildContent(ThemeData theme) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 8 * theme.scaling,
    children: [
      Row(
        spacing: 8 * theme.scaling,
        children: [
          Icon(WifiQuickSetting._iconFromSignalStrenth(
            widget.ap.strength,
            _hasSecurity)),
          Expanded(
            child: Text(
              widget.ap.ssid,
              textAlign: TextAlign.start,
              overflow: TextOverflow.ellipsis,
              style: ButtonStyle.ghost().textStyle.call(context, {WidgetState.selected}),
            ),
          ),
          if (_connecting)
            const CircularProgressIndicator()
          else if (_isConnected)
            (_hovered
                ? const Text("Disconnect")
                : const Icon(Icons.check))
          else if (_hovered && !_showDetails)
            const Text("Connect"),
        ],
      ),
      if (_showDetails)
        _buildDetails(theme),
      if (_passwordError.isNotEmpty)
        Text(
          _passwordError,
          style: TextStyle(color: Colors.red),
        ).small(),
    ],
  );

  Widget _buildDetails(ThemeData theme) {
    void connect() async {
      if (await _tryConnect(_password) && mounted) {
        setState(() {
          _showDetails = false;
          widget.onShowDetailsChanged?.call(false);
        });
      }
    }

    return Row(
      spacing: 8 * theme.scaling,
      children: [
        Icon(Icons.lock),
        Expanded(
          child: TextField(
            features: [
              InputFeature.passwordToggle(
                visibility: InputFeatureVisibility.textNotEmpty,
                mode: PasswordPeekMode.hold,
              ),
            ],
            hintText: "Password",
            placeholder: const Text("Password"),
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            autofocus: true,
            filled: true,
            enabled: !_connecting,
            onChanged: (v) => _password = v,
            onSubmitted: (v) => connect(),
          ),
        ),
        PrimaryButton(
          onPressed: _connecting ? null : () => connect(),
          child: _connecting
              ? const CircularProgressIndicator()
              : const Text("Connect"),
        ),
      ],
    );
  }

  Future<void> _disconnect() async {
    if (_connecting) return;
    final network = context.read<NetworkManagerService>();
    final device = network.wifiDevices.firstWhere((d) => d.accessPoints.contains(widget.ap));
    try {
      setState(() => _connecting = true);
      await network.disconnectWifi(device);
    } finally {
      if (mounted) {
        setState(() => _connecting = false);
      }
    }
  }

  Future<bool> _tryConnect([String password = '']) async {
    if (_connecting) return false;
    final network = context.read<NetworkManagerService>();
    final device = network.wifiDevices.firstWhere((d) => d.accessPoints.contains(widget.ap));
    try {
      setState(() => _connecting = true);
      await network.connectWifi(device, widget.ap, password);
    } on Exception {
      if (mounted) {
        setState(() => _passwordError = 'Invalid password'); // TODO: Better error handling
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => _connecting = false);
      }
    }
    return true;
  }
}