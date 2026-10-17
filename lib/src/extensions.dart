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

// Source - https://stackoverflow.com/a/79403862
// Posted by Dmitry Sikorsky
// Retrieved 2026-10-16, License - CC BY-SA 4.0

extension DateTimeExtension on DateTime {
  DateTime addMonths(int count) {
    int baseMonth = year * 12 + (month - 1);
    int newMonth = baseMonth + count;
    int newYear = newMonth ~/ 12;

    newMonth = newMonth % 12 + 1;

    int oldDay = day;
    int daysInNewMonth = DateTime(newYear, newMonth + 1, 0).day;
    int newDay = oldDay <= daysInNewMonth ? oldDay : daysInNewMonth;

    return DateTime(newYear, newMonth, newDay);
  }
}
