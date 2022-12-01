// Copyright 2021 Gohilla Ltd.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import '../kind_uuid.dart';

const bool isJs = false;
const _bit12 = 0x1000;

const _bit16 = 0x10000;

const _bit32 = 0x100000000;

const _bit48 = 0x1000000000000;

final _epoch1582Microseconds =
    DateTime.utc(1582, 10, 15).microsecondsSinceEpoch.abs();

/// Parameter [left] is V1/V6 and [right] is V7.
int compareToV1LikeToV7(Uuid left, Uuid right) {
  final leftValue = ((left.timestampRawHigh48 << 12) + left.timestampRawLow12) -
      _epoch1582Microseconds;

  final rightValue = (10000 * left.timestampRawHigh48) +
      ((left.timestampRawLow12 * 10000) ~/ 0x1000);

  return leftValue.compareTo(rightValue);
}

int dateTimeHigh48(DateTime dateTime, int version) {
  if (version == 7) {
    final t = dateTime.millisecondsSinceEpoch;
    if (t.isNegative) {
      throw ArgumentError.value(
        dateTime,
        'dateTime',
        'Must not be before Unix epoch',
      );
    }
    return t;
  } else {
    final t = _epoch1582Microseconds + dateTime.microsecondsSinceEpoch;
    if (t.isNegative) {
      throw ArgumentError.value(
        dateTime,
        'dateTime',
        'Must not be before Gregorian epoch',
      );
    }
    return (10 * t) ~/ 0x1000;
  }
}

int dateTimeLow12(DateTime dateTime, int version) {
  var t = dateTime.microsecondsSinceEpoch;
  if (version == 7) {
    return t % 1000;
  } else {
    t += _epoch1582Microseconds;
    return (10 * t) % 0x1000;
  }
}

int? microsecondsSinceEpochFromInternalParameters(int p0, int p1) {
  final version = p1 >> 28;
  if (version == 1) {
    final standardHigh12 = 0xFFF & (p1 >> 16);
    final standardMid16 = 0xFFFF & (p0 % _bit16);
    final standardLow32 = 0xFFFFFFFF & (p0 ~/ _bit16);
    final ticks =
        _bit48 * standardHigh12 + _bit32 * standardMid16 + standardLow32;
    return (ticks ~/ 10) - _epoch1582Microseconds;
  } else if (version == 6) {
    final ticks = _bit12 * p0 + (0xFFF & (p1 >> 16));
    return (ticks ~/ 10) - _epoch1582Microseconds;
  } else if (version == 7) {
    final millisecondsSinceEpoch = p0;
    final otherTicks = 0xFFF & (p1 >> 16);
    return 1000 * millisecondsSinceEpoch + otherTicks.clamp(0, 999);
  } else {
    return null;
  }
}

int? millisecondsSinceEpochFromInternalParameters(int p0, int p1) {
  final version = p1 >> 28;
  if (version == 1) {
    final standardHigh12 = 0xFFF & (p1 >> 16);
    final standardMid16 = 0xFFFF & (p0 % _bit16);
    final standardLow32 = 0xFFFFFFFF & (p0 ~/ _bit16);
    final ticks = _bit48 * standardHigh12 +
        _bit32 * standardMid16 +
        standardLow32 -
        _epoch1582Microseconds;
    return (ticks ~/ 10000);
  } else if (version == 6) {
    final ticks = _bit12 * p0 + (0xFFF & (p1 >> 16)) - _epoch1582Microseconds;
    return (ticks ~/ 10000);
  } else if (version == 7) {
    return p0;
  } else {
    return null;
  }
}
