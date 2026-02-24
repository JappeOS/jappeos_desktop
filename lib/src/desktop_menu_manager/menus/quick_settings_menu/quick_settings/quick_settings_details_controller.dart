import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'quick_setting_contributor.dart';

enum QuickSettingsPageDirection { forward, backward }

class QuickSettingsDetailsController extends ChangeNotifier {
  QuickSettingContributor? _active;
  QuickSettingsPageDirection _direction = QuickSettingsPageDirection.forward;

  QuickSettingContributor? get active => _active;
  bool get isOpen => _active != null;
  QuickSettingsPageDirection get direction => _direction;

  void open(QuickSettingContributor contributor) {
    _direction = QuickSettingsPageDirection.forward;
    _active = contributor;
    notifyListeners();
  }

  void close() {
    _direction = QuickSettingsPageDirection.backward;
    _active = null;
    notifyListeners();
  }

  static QuickSettingsDetailsController of(BuildContext context) {
    return context.read<QuickSettingsDetailsController>();
  }
}
