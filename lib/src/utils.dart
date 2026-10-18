import 'dart:io';

int countGraphicsCards() {
  final drmDirectory = Directory('/sys/class/drm/');
  final cardNumbers = <int>{};

  if (!drmDirectory.existsSync()) {
    return 0;
  }

  for (final entity in drmDirectory.listSync()) {
    final name = entity.uri.pathSegments.last;

    final match = RegExp(r'^card(\d+)').firstMatch(name);
    if (match != null) {
      cardNumbers.add(int.parse(match.group(1)!));
    }
  }

  return cardNumbers.length;
}

bool hasDiscreteGpu() => countGraphicsCards() > 1 && _hasDiscreteNvidiaGpu();

bool _hasDiscreteNvidiaGpu() {
  final drmDirectory = Directory('/sys/class/drm/');

  if (!drmDirectory.existsSync()) {
    return false;
  }

  for (final entity in drmDirectory.listSync()) {
    final name = entity.uri.pathSegments.last;

    if (!RegExp(r'^card\d+$').hasMatch(name)) {
      continue;
    }

    final vendorFile = File('${entity.path}/device/vendor');

    if (!vendorFile.existsSync()) {
      continue;
    }

    try {
      final vendor = vendorFile.readAsStringSync().trim().toLowerCase();

      if (vendor == '0x10de') {
        return true;
      }
    } catch (_) {
      continue;
    }
  }

  return false;
}

Map<String, String> getGraphicsEnvironmentVariables(bool useDiscreteGpu) {
  final envVars = <String, String>{};

  if (useDiscreteGpu && hasDiscreteGpu()) {
    envVars.addAll({
      'DRI_PRIME': '1',
      '__NV_PRIME_RENDER_OFFLOAD': '1',
      '__GLX_VENDOR_LIBRARY_NAME': 'nvidia',
      '__VK_LAYER_NV_optimus': 'NVIDIA_only',
    });
  }

  return envVars;
}