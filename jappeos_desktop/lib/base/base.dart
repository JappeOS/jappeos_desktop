//  JappeOS-Desktop, The desktop environment for JappeOS.
//  Copyright (C) 2025  Jappe02
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

library jappeos_desktop.base;

import 'dart:async';

import 'package:event/event.dart';
import 'package:flutter/material.dart' show ListTile;
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jappeos_desktop/base/provider/auth_provider.dart';
import 'package:jdwm_flutter/jdwm_flutter.dart';
import 'package:jdwm_flutter/widgets/window_ui.dart';
import 'package:provider/provider.dart';

import 'package:shade_ui/shade_ui.dart';
import 'package:shade_ui/shade_ui.dart' as shui;
import 'package:vector_math/vector_math.dart' hide Colors;
import 'package:intl/intl.dart';
import 'package:widget_and_text_animator/widget_and_text_animator.dart';

import 'desktop_menu_manager/menus/control_center_menu/control_center_menu.dart';

//
// Base
part 'constants.dart';
part 'desktop.dart';
part 'desktop_actions.dart';
//
// Animations
part 'animations/incoming_scale_up_animation.dart';
//
// Components
part 'components/desktop_widgets.dart';
part 'components/login_screen.dart';
//
// Menu Manager
part 'desktop_menu_manager/desktop_menu_controller.dart';
part 'desktop_menu_manager/menus/launcher_menu.dart';
part 'desktop_menu_manager/menus/search_menu.dart';
part 'desktop_menu_manager/menus/open_windows_menu.dart';
part 'desktop_menu_manager/menus/notification_menu.dart';
//part 'desktop_menu_manager/menus/control_center_menu/control_center_menu.dart';
part 'desktop_menu_manager/menus/permissions_menu.dart';
