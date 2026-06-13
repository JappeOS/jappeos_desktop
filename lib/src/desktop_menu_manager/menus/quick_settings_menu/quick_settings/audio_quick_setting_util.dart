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

import 'package:jappeos_services/jappeos_services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

IconData createIcon(AudioDeviceType type) {
  switch (type) {
    case AudioDeviceType.tv:
      return Icons.tv;
    case AudioDeviceType.webcam:
      return Icons.videocam;
    case AudioDeviceType.speaker:
      return Icons.speaker;
    case AudioDeviceType.headset:
      return Icons.headset;
    case AudioDeviceType.headphone:
      return Icons.headphones;
    case AudioDeviceType.handset:
      return Icons.phone;
    case AudioDeviceType.microphone:
      return Icons.mic;
    case AudioDeviceType.handsFree:
      return Icons.speaker_phone;
    case AudioDeviceType.car:
      return Icons.directions_car;
    case AudioDeviceType.hifi:
      return Icons.high_quality;
    case AudioDeviceType.computer:
      return Icons.computer;
    case AudioDeviceType.portable:
      return Icons.earbuds;
    default:
      return Icons.audiotrack;
  }
}