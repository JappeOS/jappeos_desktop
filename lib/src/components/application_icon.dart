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

import 'package:flutter/widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' show Icons;

import '../provider/application_icon_service.dart';
import '../provider/application_resolver.dart';
import 'icon_request_view.dart';

class ApplicationIcon extends StatelessWidget {
  final ResolvedApplication application;
  final ApplicationIconService service;
  final double size;

  const ApplicationIcon({
    super.key,
    required this.application,
    required this.service,
    required this.size,
  });

  @override
  Widget build(BuildContext context) => IconRequestView(
    request: service.request(
      application,
      size: size,
      dpr: MediaQuery.devicePixelRatioOf(context)
    ),
    identity: (service, application.groupId),
    size: size,
    fallback: Icon(Icons.settings_applications, size: size),
  );
}
