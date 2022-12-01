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

const bool isJs = true;
const _bit16 = 0x10000;
const _bit32 = 0x100000000;
final _epoch1582BigInt = BigInt.from(_epoch1582Milliseconds) * _tenThousand;
final _epoch1582Milliseconds =
    DateTime.utc(1582, 10, 15).millisecondsSinceEpoch.abs();
final _low12Mask = BigInt.from(0xFFF);
final _tenThousand = BigInt.from(10000);

/// Parameter [left] is V1/V6 and [right] is V7.
int compareToV1LikeToV7(Uuid left, Uuid right) {
  // Use BigInt to minimize numerical errors.
  final bigIntLeft = ((BigInt.from(left.timestampRawHigh48) << 12) +
          BigInt.from(left.timestampRawLow12)) -
      _epoch1582BigInt;

  final bigIntRight = (_tenThousand * BigInt.from(left.timestampRawHigh48)) +
      BigInt.from(((left.timestampRawLow12 * 10000) ~/ 0x1000));

  return bigIntLeft.compareTo(bigIntRight);
}

int dateTimeHigh48(DateTime dateTime, int version) {
  var t = dateTime.millisecondsSinceEpoch;
  if (version == 7) {
    if (t.isNegative) {
      throw ArgumentError.value(
        dateTime,
        'dateTime',
        'Must not be before Unix epoch',
      );
    }
    return t;
  } else {
    t += _epoch1582Milliseconds;
    if (t.isNegative) {
      throw ArgumentError.value(
        dateTime,
        'dateTime',
        'Must not be before Gregorian epoch',
      );
    }
    return ((BigInt.from(t) * _tenThousand) >> 12).toInt();
  }
}

int dateTimeLow12(DateTime dateTime, int version) {
  if (version == 7) {
    return 0;
  }
  final t = _epoch1582Milliseconds + dateTime.millisecondsSinceEpoch;
  return (_low12Mask & (BigInt.from(t) * _tenThousand)).toInt();
}

int? microsecondsSinceEpochFromInternalParameters(int p0, int p1) {
  final version = p1 >> 28;
  if (version == 1) {
    final standardHigh12 = 0xFFF & (p1 >> 16);
    final standardMid16 = 0xFFFF & (p0 % _bit16);
    final standardLow32 = 0xFFFFFFFF & (p0 ~/ _bit16);
    // Use BigInt to minimize numerical errors.
    var bigInt = (BigInt.from(standardHigh12) << 48) +
        BigInt.from(_bit32 * standardMid16 + standardLow32);
    bigInt -= _epoch1582BigInt;
    return (bigInt ~/ BigInt.from(10)).toInt();
  } else if (version == 6) {
    // Use BigInt to minimize numerical errors.
    var bigInt = (BigInt.from(p0) << 12) + BigInt.from(0xFFF & (p1 >> 16));
    bigInt -= _epoch1582BigInt;
    return (bigInt ~/ BigInt.from(10)).toInt();
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

    // Use BigInt to minimize numerical errors.
    final bigInt = (BigInt.from(standardHigh12) << 48) +
        BigInt.from(_bit32 * standardMid16 + standardLow32);
    return (bigInt ~/ BigInt.from(10000)).toInt() - _epoch1582Milliseconds;
  } else if (version == 6) {
    // Use BigInt to minimize numerical errors.
    final bigInt = (BigInt.from(p0) << 12) + BigInt.from(0xFFF & (p1 >> 16));
    return (bigInt ~/ BigInt.from(10000)).toInt() - _epoch1582Milliseconds;
  } else if (version == 7) {
    return p0;
  } else {
    return null;
  }
}
