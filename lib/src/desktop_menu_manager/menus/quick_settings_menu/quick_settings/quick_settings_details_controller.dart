import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'quick_setting_contributor.dart';

class QuickSettingsDetailsController extends ChangeNotifier {
  QuickSettingContributor? _active;

  QuickSettingContributor? get active => _active;
  bool get isOpen => _active != null;

  void open(QuickSettingContributor contributor) {
    _active = contributor;
    notifyListeners();
  }

  void close() {
    _active = null;
    notifyListeners();
  }

  static QuickSettingsDetailsController of(BuildContext context) {
    return context.read<QuickSettingsDetailsController>();
  }
}
