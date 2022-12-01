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

import 'dart:math';
import 'dart:typed_data';

import '../kind_uuid.dart';
import '_uuid.dart';

const _bit12 = 0x1000;
const _bit14 = 0x4000;
const _bit16 = 0x10000;
const _bit20 = 0x100000;
const _bit24 = 0x1000000;
const _bit32 = 0x100000000;
const _bit36 = 0x1000000000;
const _bit40 = 0x10000000000;
const _bit48 = 0x1000000000000;
const _bit8 = 0x100;

const _chars = <String>[
  '0',
  '1',
  '2',
  '3',
  '4',
  '5',
  '6',
  '7',
  '8',
  '9',
  'a',
  'b',
  'c',
  'd',
  'e',
  'f'
];

/// UUID is an universally unique 128-bit identifier.
///
/// You can find the specification in [RFC 4122](https://datatracker.ietf.org/doc/html/rfc4122).
///
///
/// # Generating UUIDs
///
/// Choose one of the following constructors:
///   * [Uuid.random]  (UUID version 4)
///   * [Uuid.timestampedV1] (UUID version 1)
///   * [Uuid.timestampedV6] (UUID version 6)
///   * [Uuid.timestampedV7] (UUID version 7)
///
/// # Decoding/encoding strings
///
/// UUIDs have a case-insensitive 36 character string format. For example,
/// "f81d4fae-7dec-11d0-a765-00a0c91e6bf6" is a valid UUID.
///
/// Use [Uuid.parse] or [Uuid.tryParse] to parse UUID in a string.
///
/// Use [toString] to get a lowercase UUID string. The method caches the
/// result.
///
///
/// # Decoding/encoding bytes
///
/// Use [Uuid.fromBytes] to read an UUID from a byte list.
///
/// Use [toBytes] to get the list of 16 bytes. The method caches the
/// result. You should use [writeBytesTo] if you are writing the bytes to
/// another byte list.
///
///
/// # Comparing UUIDS
///   * [Uuid.compareByBytes] compares the bytes.
///   * [Uuid.compareByTimestampCsMac] compares timestamped UUIDs using
///     the timestamp, clock sequence, and MAC address fields before other bits.
///
abstract class Uuid implements Comparable<Uuid> {
  /// UUID "00000000-0000-0000-0000-000000000000".
  static final Uuid zero = _Uuid(0, 0, 0);

  /// All supported UUID version field values.
  static const List<int> supportedVersions = [
    1,
    4,
    6,
    7,
  ];

  /// A pattern for [regExp].
  static const _uuidCharPattern = '[0-9a-fA-F]';

  /// Regular expression pattern.
  static const String pattern = '^$_uuidCharPattern{8}-'
      '$_uuidCharPattern{4}-'
      '$_uuidCharPattern{4}-'
      '$_uuidCharPattern{4}-'
      '$_uuidCharPattern{12}\$';

  /// Default random number generator for generating UUIDs.
  ///
  /// The default value is [UuidRandom.instance], which is much faster than
  /// [Random.secure]. You can make the latter the permanent default by calling
  /// [Uuid.useSystemRandomByDefault].
  static final Random defaultRandom = _defaultRandom;

  static Random _defaultRandom = UuidRandom();

  static const _timestampedVersionNumbers = <int>{
    1,
    6,
    7,
    8,
  };

  /// Factory used by the default constructor.
  static Uuid Function()? _defaultFactory;

  /// Char code for '0'.
  static const _$0 = 0x30;

  /// Char code for '9'.
  static const _$9 = 0x39;

  /// Char code for '-'.
  static const _$dash = 0x2D;

  /// Char code for 'A'.
  static const _$A = 0x41;

  /// Char code for 'F'.
  static const _$F = 0x46;

  /// Char code for 'a'.
  static const _$a = 0x61;

  /// Char code for 'f'.
  static const _$f = 0x66;

  /// Cached result of [toBytes].
  UnmodifiableUint8ListView? _cachedBytes;

  /// Cached result of [toString].
  String? _cachedString;

  /// Returns an UUID using the default factory.
  ///
  /// Default factory can be defined with [Uuid.setDefaultFactory].
  /// If none has been defined, [Uuid.random] will be used.
  factory Uuid() {
    final f = _defaultFactory;
    if (f != null) {
      return f();
    }
    return Uuid.random();
  }

  /// Constructor for subclasses.
  Uuid.constructor();

  /// Constructs UUID from 16 bytes at [offset] in [bytes].
  ///
  /// The argument can have longer length. Data after the first 16 bytes
  /// is ignored.
  ///
  /// ## Example
  /// ```
  /// import 'package:kind_uuid/kind_uuid.dart';
  ///
  /// final uuid = Uuid.fromBytes([0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]);
  /// ```
  factory Uuid.fromBytes(List<int> bytes, {int offset = 0}) {
    if (bytes.length < 16) {
      throw ArgumentError.value(
        bytes,
        'bytes',
        'Length must be at least 16.',
      );
    }
    if (offset < 0 || bytes.length - offset < 16) {
      throw ArgumentError.value(
        offset,
        'offset',
        'Maximum is ${bytes.length - 16}.',
      );
    }
    final v0 = (_bit40 * bytes[offset + 0]) +
        (_bit32 * bytes[offset + 1]) +
        (_bit24 * bytes[offset + 2]) +
        (_bit16 * bytes[offset + 3]) +
        (_bit8 * bytes[offset + 4]) +
        bytes[offset + 5];
    final v1 = (bytes[offset + 6] << 24) |
        (bytes[offset + 7] << 16) |
        (bytes[offset + 8] << 8) |
        bytes[offset + 9];
    final v2 = (_bit40 * bytes[offset + 10]) +
        (_bit32 * bytes[offset + 11]) +
        (_bit24 * bytes[offset + 12]) +
        (_bit16 * bytes[offset + 13]) +
        (_bit8 * bytes[offset + 14]) +
        bytes[offset + 15];
    return Uuid.fromInternalParameters(v0, v1, v2);
  }

  /// Constructs UUID from three integers (48 bit, 32 bit, and 48 bit).
  ///
  /// Returns static instance [Uuid.zero] if all arguments are zero.
  factory Uuid.fromInternalParameters(int v0, int v1, int v2) {
    if (v0 == 0 && v1 == 0 && v2 == 0) {
      return zero;
    }
    return _Uuid(v0, v1, v2);
  }

  /// Constructs UUID from the UUID v1 parameters.
  factory Uuid.fromV1Parameters({
    required int low32,
    required int mid16,
    required int high12,
    required int version,
    required int variant,
    required int cs,
    required int mac,
  }) {
    return Uuid.fromV6Parameters(
      high48: _bit16 * low32 + mid16,
      low12: high12,
      version: version,
      variant: variant,
      cs: cs,
      mac: mac,
    );
  }

  /// Constructs UUID from the UUID version 6
  /// ([2022 draft](https://datatracker.ietf.org/doc/html/draft-ietf-uuidrev-rfc4122bis))
  /// parameters.
  factory Uuid.fromV6Parameters({
    required int high48,
    required int low12,
    required int version,
    required int variant,
    required int cs,
    required int mac,
  }) {
    assert(high48 >= 0);
    assert(high48 < _bit48);
    assert(low12 >= 0);
    assert(low12 < _bit12);
    assert(mac >= 0);
    assert(mac < _bit48);
    var variantAndCq = 0;
    if (variant == 0) {
      assert(cs >= 0 && cs < 0x8000);
      variantAndCq = 0x7FFF & cs;
    } else if (variant == 1) {
      assert(cs >= 0 && cs < 0x4000);
      variantAndCq = 0x8000 | (0x3FFF & cs);
    } else if (variant == 2 || variant == 3) {
      assert(cs >= 0 && cs < 0x2000);
      variantAndCq = 0xC000 | (0x1FFF & cs);
    } else {
      throw ArgumentError.value(variant, 'variant');
    }
    final p = ((0xF & version) << 28) | ((0xFFF & low12) << 16) | variantAndCq;
    return _Uuid(high48, p, mac);
  }

  /// Parses canonical UUID string.
  ///
  /// Throws [FormatException] if parsing fails.
  /// Use [tryParse] if you want `null` instead.
  ///
  /// If optional parameter [kind] is non-null, the parsed UUID will be
  /// validated (by calling [Kind.validate]) and an error will be throw if the
  /// UUID is not a valid instance of the kind.
  ///
  /// ## Example
  /// ```
  /// import 'package:kind_uuid/kind_uuid.dart';
  ///
  /// void main() {
  ///   final uuid = Uuid.parse('f81d4fae-7dec-11d0-a765-00a0c91e6bf6');
  ///   print(uuid);
  /// }
  /// ```
  factory Uuid.parse(String s) {
    final uuid = Uuid.tryParse(s);
    if (uuid == null) {
      throw FormatException('Not a valid UUID.', s);
    }
    return uuid;
  }

  /// Returns a new random UUID version 4 value.
  ///
  /// Optional parameter [random] specifies random number generator. If it's
  /// `null`, [Uuid.defaultRandom] will be used.
  ///
  /// ## Example
  /// ```
  /// import 'package:kind_uuid/kind_uuid.dart';
  ///
  /// void main() {
  ///   for (var i=0; i<10; i++) {
  ///     final uuid = Uuid.random();
  ///     print(uuid);
  ///   }
  /// }
  /// ```
  factory Uuid.random({
    Random? random,
  }) {
    random ??= defaultRandom;

    final r0 = random.nextInt(_bit32);
    final r1 = random.nextInt(_bit32);
    final r2 = random.nextInt(_bit32);
    final r3 = random.nextInt(_bit32);

    final p0 = _bit16 * r0 + (r1 >> 16);
    final p1 = 0x40008000 | (0x0FFF3FFF & r2);
    final mac = _bit32 * (0xFFFF & r1) + r3;
    return _Uuid(p0, p1, mac);
  }

  /// Constructs a new UUID version 1 value.
  ///
  /// Optional parameter [random] specifies random number generator. If it's
  /// `null`, [Uuid.defaultRandom] will be used.
  ///
  /// Optional parameter [timestampingState] (default:
  /// [UuidTimestampingState.instance]) is responsible for constructing an
  /// unique, monotonic timestamp.
  ///
  /// If you want to have a specific timestamp, you can use optional parameter
  /// [dateTime]. If it is null, [timestampingState] chooses the timestamp
  /// ([UuidTimestampingState.now]).
  ///
  /// Optional parameter [cs] is a 14-bit unsigned integer, which is used to
  /// reduce collisions. If value of the parameter is null, [timestampingState]
  /// chooses the value and may also increment the timestamp if necessary
  /// ([UuidTimestampingState.nextCs]).
  ///
  /// Optional parameter [mac] is a 48-bit unsigned integer written in the end
  /// of the UUID. If the value is null, a random value will be chosen.
  ///
  /// ## Example
  /// ```
  /// import 'package:kind_uuid/kind_uuid.dart';
  ///
  /// void main() {
  ///   for (var i=0; i<10; i++) {
  ///     final uuid = Uuid.timestampedV1();
  ///     print(uuid);
  ///     print(uuid.dateTime());
  ///   }
  /// }
  /// ```
  factory Uuid.timestampedV1({
    Random? random,
    UuidTimestampingState? timestampingState,
    DateTime? dateTime,
    int? cs,
    int? mac,
  }) {
    const version = 1;
    timestampingState ??= UuidTimestampingState.instance;

    dateTime ??= timestampingState.now();
    if (dateTime.isBefore(epoch1582)) {
      throw ArgumentError.value(dateTime, 'dateTime');
    }
    var low12 = dateTimeLow12(dateTime, version);
    var high48 = dateTimeHigh48(dateTime, version);
    random ??= defaultRandom;

    // Mac
    mac ??= _bit16 * random.nextInt(_bit32) + random.nextInt(_bit16);

    if (cs == null) {
      final newCs = timestampingState.nextCs(
        version: version,
        variant: 1,
        mac: mac,
        dateTime: dateTime,
        high48: high48,
        low12: low12,
        random: random,
      );
      cs = 0x3FFF & newCs;
      low12 += (newCs ~/ _bit14);
      high48 += (low12 ~/ _bit12);
      low12 &= 0xFFF;
    }

    // Standard UUID V1 integers
    final standardHigh12 = high48 ~/ _bit36;
    final standardMid16 = (high48 ~/ _bit20) % _bit16;
    final standardLow32 = _bit12 * (high48 % _bit20) + low12;

    return Uuid.fromV1Parameters(
      low32: standardLow32,
      mid16: standardMid16,
      high12: standardHigh12,
      cs: cs,
      version: version,
      variant: 1,
      mac: mac,
    );
  }

  /// Constructs an UUID version 6
  /// ([2022 draft](https://datatracker.ietf.org/doc/html/draft-ietf-uuidrev-rfc4122bis))
  /// value.
  ///
  /// Optional parameter [random] specifies random number generator. If it's
  /// `null`, [Uuid.defaultRandom] will be used.
  ///
  /// Optional parameter [timestampingState] (default:
  /// [UuidTimestampingState.instance]) is responsible for constructing an
  /// unique, monotonic timestamp.
  ///
  /// If you want to have a specific timestamp, you can use optional parameter
  /// [dateTime]. If it is null, [timestampingState] chooses the timestamp
  /// ([UuidTimestampingState.now]).
  ///
  /// Optional parameter [cs] is a 14-bit unsigned integer, which is used to
  /// reduce collisions. If value of the parameter is null, [timestampingState]
  /// chooses the value and may also increment the timestamp if necessary
  /// ([UuidTimestampingState.nextCs]).
  ///
  /// Optional parameter [mac] is a 48-bit unsigned integer written in the end
  /// of the UUID. If the value is null, a random value will be chosen.
  ///
  /// ## Example
  /// ```
  /// import 'package:kind_uuid/kind_uuid.dart';
  ///
  /// void main() {
  ///   for (var i=0; i<10; i++) {
  ///     final uuid = Uuid.timestampedV6();
  ///     print(uuid);
  ///     print(uuid.dateTime());
  ///   }
  /// }
  /// ```
  factory Uuid.timestampedV6({
    Random? random,
    UuidTimestampingState? timestampingState,
    DateTime? dateTime,
    int? cs,
    int? mac,
  }) {
    const version = 6;
    timestampingState ??= UuidTimestampingState.instance;

    dateTime ??= timestampingState.now();
    if (dateTime.isBefore(epoch1582)) {
      throw ArgumentError.value(dateTime, 'dateTime');
    }
    var low12 = dateTimeLow12(dateTime, version);
    var high48 = dateTimeHigh48(dateTime, version);
    random ??= defaultRandom;

    // Mac
    mac ??= _bit16 * random.nextInt(_bit32) + random.nextInt(_bit16);

    if (cs == null) {
      final newCs = timestampingState.nextCs(
        version: version,
        variant: 1,
        mac: mac,
        dateTime: dateTime,
        high48: high48,
        low12: low12,
        random: random,
      );
      cs = 0x3FFF & newCs;
      low12 += (newCs ~/ _bit14);
      high48 += (low12 ~/ _bit12);
      low12 &= 0xFFF;
    }

    // Standard UUID V1 integers
    final standardHigh12 = low12;
    final standardMid16 = high48 % _bit16;
    final standardLow32 = high48 ~/ _bit16;

    return Uuid.fromV1Parameters(
      low32: standardLow32,
      mid16: standardMid16,
      high12: standardHigh12,
      cs: cs,
      version: version,
      variant: 1,
      mac: mac,
    );
  }

  /// Constructs a new UUID version 7
  /// ([2022 draft](https://datatracker.ietf.org/doc/html/draft-ietf-uuidrev-rfc4122bis))
  /// value.
  ///
  /// Optional parameter [random] specifies random number generator. If it's
  /// `null`, [Uuid.defaultRandom] will be used.
  ///
  /// Optional parameter [timestampingState] (default:
  /// [UuidTimestampingState.instance]) is responsible for constructing an
  /// unique, monotonic timestamp.
  ///
  /// If you want to have a specific timestamp, you can use optional parameter
  /// [dateTime]. If it is null, [timestampingState] chooses the timestamp
  /// ([UuidTimestampingState.now]).
  ///
  /// Optional parameter [cs] is a 14-bit unsigned integer, which is used to
  /// reduce collisions. If value of the parameter is null, [timestampingState]
  /// chooses the value and may also increment the timestamp if necessary
  /// ([UuidTimestampingState.nextCs]).
  ///
  /// Optional parameter [mac] is a 48-bit unsigned integer written in the end
  /// of the UUID. If the value is null, a random value will be chosen.
  ///
  /// ## Example
  /// ```
  /// import 'package:kind_uuid/kind_uuid.dart';
  ///
  /// void main() {
  ///   for (var i=0; i<10; i++) {
  ///     final uuid = Uuid.timestampedV7();
  ///     print(uuid);
  ///     print(uuid.dateTime());
  ///   }
  /// }
  /// ```
  factory Uuid.timestampedV7({
    Random? random,
    UuidTimestampingState? timestampingState,
    DateTime? dateTime,
    int? cs,
    int? mac,
  }) {
    const version = 7;
    timestampingState ??= UuidTimestampingState.instance;

    dateTime ??= timestampingState.now();
    if (dateTime.isBefore(epochUnix)) {
      throw ArgumentError.value(dateTime, 'dateTime');
    }
    var high48 = dateTimeHigh48(dateTime, version);
    var low12 = dateTimeLow12(dateTime, version);
    random ??= defaultRandom;

    // Mac
    mac ??= _bit16 * random.nextInt(_bit32) + random.nextInt(_bit16);

    if (cs == null) {
      final newCs = timestampingState.nextCs(
        version: version,
        variant: 1,
        mac: mac,
        dateTime: dateTime,
        high48: high48,
        low12: low12,
        random: random,
      );
      cs = 0x3FFF & newCs;
      low12 += (newCs ~/ _bit14);
      high48 += (low12 ~/ _bit12);
      low12 &= 0xFFF;
    }

    return Uuid.fromV6Parameters(
      high48: high48,
      low12: low12,
      cs: cs,
      version: 7,
      variant: 1,
      mac: mac,
    );
  }

  factory Uuid.withVersion(
    int version, {
    Random? random,
    int? mac,
  }) {
    switch (version) {
      case 1:
        return Uuid.timestampedV1(
          random: random,
          mac: mac,
        );
      case 4:
        return Uuid.random(
          random: random,
        );
      case 6:
        return Uuid.timestampedV6(
          random: random,
          mac: mac,
        );
      case 7:
        return Uuid.timestampedV7(
          random: random,
          mac: mac,
        );
      default:
        throw ArgumentError.value(version, 'version');
    }
  }

  /// Returns clock sequence, which is usually 12 bits.
  int get cs {
    final bits = 0xFFFF & p1;
    {
      // Variant 1
      final r = 0x3FFF & bits;
      if (0x8000 | r == bits) {
        return r;
      }
    }
    {
      // Variant 0
      final r = 0x7FFF & bits;
      if (r == bits) {
        return r;
      }
    }
    // Variant 2
    return 0x1FFF & bits;
  }

  /// Tells whether [dateTime] returns a non-null value.
  ///
  /// This is true when [version] is 1, 6, or 7 and [variant] is
  /// 1.
  bool get hasDateTime {
    return _timestampedVersionNumbers.contains(version) && variant == 1;
  }

  @override
  int get hashCode => (p0 ^ p1 ^ mac).hashCode;

  /// Tells whether this is a random UUID (version 4).
  bool get isRandom {
    return version == 4;
  }

  /// Tells whether all bytes are zero.
  bool get isZero => p0 == 0 && p1 == 0 && mac == 0;

  /// The bytes 10..15 as a 48-bit unsigned integer.
  ///
  /// These bytes are also known as the MAC address in version 1
  /// specification.
  ///
  /// When the value is read/written, the byte order is big endian
  /// (most significant bytes are the first).
  int get mac;

  /// Microseconds since Unix epoch.
  int? get microsecondsSinceEpoch {
    return microsecondsSinceEpochFromInternalParameters(
      p0,
      p1,
    );
  }

  /// Milliseconds since Unix epoch.
  int? get millisecondsSinceEpoch {
    return millisecondsSinceEpochFromInternalParameters(
      p0,
      p1,
    );
  }

  /// The bytes 0..5 as a 48-bit unsigned integer.
  ///
  /// This is an internal implementation concept.
  ///
  /// When the value is read/written, the byte order is big endian
  /// (most significant bytes are the first).
  int get p0;

  /// The bytes 6..9 as a 32-bit unsigned integer.
  ///
  /// This is an internal implementation concept.
  ///
  /// When the value is read/written, the byte order is big endian
  /// (most significant bytes are the first).
  int get p1;

  /// A 60-bit unsigned integer for the number of ticks since some epoch.
  ///
  /// In version 1, the epoch is October 15 1582. In version 6, the epoch is
  /// the Unix epoch (1970). In version 7, the high 48 bits is milliseconds
  /// since Unix epoch and the low 12-bits are not defined in terms of time
  /// units.
  ///
  /// To avoid numerical errors in Javascript, use [timestampRawHigh48] and
  /// [timestampRawLow12].
  int get timestampRaw {
    return _bit12 * timestampRawHigh48 + timestampRawLow12;
  }

  /// High 48 bits of the [timestampRaw].
  ///
  /// Splitting 60-bit [timestampRaw] into two values prevents numerical errors
  /// in Javascript.
  int get timestampRawHigh48 {
    final p0 = this.p0;
    final p1 = this.p1;
    final version = p1 >> 28;
    if (version == 1) {
      final standardHigh12 = 0xFFF & (p1 >> 16);
      final standardMid16 = 0xFFFF & (p0 % _bit16);
      final standardLow32 = 0xFFFFFFFF & (p0 ~/ _bit16);
      return _bit36 * standardHigh12 +
          _bit20 * standardMid16 +
          (standardLow32 >> 12);
    } else if (version == 6 || version == 7) {
      return p0;
    } else {
      return -1;
    }
  }

  /// Low 12 bits of the timestamp.
  ///
  /// Splitting 60-bit [timestampRaw] into two values prevents numerical errors
  /// in Javascript.
  int get timestampRawLow12 {
    final p1 = this.p1;
    final version = p1 >> 28;
    if (version == 1) {
      return 0xFFF & (p0 ~/ _bit16);
    } else if (version == 6 || version == 7) {
      return 0xFFF & (p1 >> 16);
    } else {
      return -1;
    }
  }

  /// UUID variant number.
  ///
  /// Valid return values are:
  ///   * 0: Only [Uuid.zero] and legacy UUIDs.
  ///   * 1: Nearly all UUIDs)
  ///   * 2: Legacy Microsoft UUIDs
  ///   * 3: Reserved
  int get variant => Uuid._variantNumberFromByte(0xFF & (p1 >> 8));

  /// UUID version number.
  int get version => 0xF & (p1 >> 28);

  @override
  bool operator ==(Object other) {
    return other is Uuid &&
        p0 == other.p0 &&
        p1 == other.p1 &&
        mac == other.mac;
  }

  /// Uses [Uuid.compareByTimestampCsMac] to compare the UUIDs.
  @override
  int compareTo(Uuid other) {
    return compareByTimestampCsMac(this, other);
  }

  /// Constructs a new [DateTime] from the timestamp when possible.
  ///
  /// Returns `null` otherwise.
  DateTime? dateTime() {
    return dateTimeFromInternalParameters(p0, p1);
  }

  /// Returns 16 bytes of the UUID.
  ///
  /// The method caches the result.
  Uint8List toBytes() {
    final cachedBytes = _cachedBytes;
    if (cachedBytes != null) {
      return cachedBytes;
    }
    final bytes = Uint8List(16);
    writeBytesTo(bytes);
    final result = UnmodifiableUint8ListView(bytes);
    _cachedBytes = result;
    return result;
  }

  /// Returns a debugging-friendly representation of the UUID.
  ///
  /// ## Example
  /// ```
  /// void main() {
  ///   final uuid = Uuid.parse("f81d4fae-7dec-11d0-a765-00a0c91e6bf6");
  ///   print(uuid.toDebugString());
  ///   // --> Uuid.parse("f81d4fae-7dec-11d0-a765-00a0c91e6bf6")
  /// }
  /// ```
  String toDebugString() => 'Uuid.parse("$this")';

  /// Returns a canonical lowercase string such as
  /// "f81d4fae-7dec-11d0-a765-00a0c91e6bf6".
  ///
  /// The method caches the result.
  @override
  @override
  String toString() {
    final cachedString = _cachedString;
    if (cachedString != null) {
      return cachedString;
    }

    final sb = StringBuffer();

    final p0 = this.p0;
    _writeByte(sb, 0xFF & (p0 ~/ _bit40));
    _writeByte(sb, 0xFF & (p0 ~/ _bit32));
    _writeByte(sb, 0xFF & (p0 ~/ _bit24));
    _writeByte(sb, 0xFF & (p0 ~/ _bit16));
    sb.write('-');
    _writeByte(sb, 0xFF & (p0 ~/ _bit8));
    _writeByte(sb, 0xFF & p0);
    sb.write('-');

    final p1 = this.p1;
    _writeByte(sb, 0xFF & (p1 ~/ _bit24));
    _writeByte(sb, 0xFF & (p1 ~/ _bit16));
    sb.write('-');
    _writeByte(sb, 0xFF & (p1 ~/ _bit8));
    _writeByte(sb, 0xFF & p1);
    sb.write('-');

    final mac = this.mac;
    _writeByte(sb, 0xFF & (mac ~/ _bit40));
    _writeByte(sb, 0xFF & (mac ~/ _bit32));
    _writeByte(sb, 0xFF & (mac ~/ _bit24));
    _writeByte(sb, 0xFF & (mac ~/ _bit16));
    _writeByte(sb, 0xFF & (mac ~/ _bit8));
    _writeByte(sb, 0xFF & mac);

    final result = sb.toString();
    _cachedString = result;
    return result;
  }

  /// Writes bytes to the buffer.
  ///
  /// This can be faster than using [toBytes].
  void writeBytesTo(Uint8List buffer, {int offset = 0}) {
    final p0 = this.p0;
    final p1 = this.p1;
    final mac = this.mac;
    // Note that we use `~/` rather than `>>` operator because of bit shifts
    // in Javascript.
    buffer[offset] = 0xFF & (p0 ~/ _bit40);
    buffer[offset + 1] = 0xFF & (p0 ~/ _bit32);
    buffer[offset + 2] = 0xFF & (p0 ~/ _bit24);
    buffer[offset + 3] = 0xFF & (p0 ~/ _bit16);
    buffer[offset + 4] = 0xFF & (p0 ~/ _bit8);
    buffer[offset + 5] = 0xFF & p0;
    buffer[offset + 6] = 0xFF & (p1 ~/ _bit24);
    buffer[offset + 7] = 0xFF & (p1 ~/ _bit16);
    buffer[offset + 8] = 0xFF & (p1 ~/ _bit8);
    buffer[offset + 9] = 0xFF & p1;
    buffer[offset + 10] = 0xFF & (mac ~/ _bit40);
    buffer[offset + 11] = 0xFF & (mac ~/ _bit32);
    buffer[offset + 12] = 0xFF & (mac ~/ _bit24);
    buffer[offset + 13] = 0xFF & (mac ~/ _bit16);
    buffer[offset + 14] = 0xFF & (mac ~/ _bit8);
    buffer[offset + 15] = 0xFF & mac;
  }

  /// Compares two UUIDs by bytes.
  ///
  /// If you want to compare by timestamp,
  /// use [Uuid.compareByTimestampCsMac].
  ///
  /// Returns:
  ///   * -1 if `left < right`
  ///   * 0 if `left == right`
  ///   * 1 if `left > right`
  static int compareByBytes(Uuid left, Uuid right) {
    // Compare v0 (bytes 0..5)
    {
      final r = left.p0.compareTo(right.p0);
      if (r != 0) {
        return r;
      }
    }

    // Compare v1 (bytes 6..9)
    {
      final r = left.p1.compareTo(right.p1);
      if (r != 0) {
        return r;
      }
    }

    // Compare the last 6 bytes
    return left.mac.compareTo(right.mac);
  }

  /// Compares two UUIDs using timestamps.
  ///
  /// If one of the UUIDs does not have a (v1, v6, or v7) timestamp, uses
  /// normal byte-by-byte comparison.
  ///
  /// Returns:
  ///   * -1 if `left < right`
  ///   * 0 if `left == right`
  ///   * 1 if `left > right`
  static int compareByTimestampCsMac(Uuid left, Uuid right) {
    final leftVersion = left.version;
    final rightVersion = right.version;

    if (!_timestampedVersionNumbers.contains(leftVersion)) {
      if (!_timestampedVersionNumbers.contains(rightVersion)) {
        return compareByBytes(left, right);
      }
      return 1;
    }
    if (!_timestampedVersionNumbers.contains(rightVersion)) {
      return -1;
    }

    if (leftVersion == rightVersion ||
        ((leftVersion == 1 || leftVersion == 6) &&
            (rightVersion == 1 || rightVersion == 6))) {
      // Same epoch and time unit.
      // Comparison is easy.

      // High 48 bits
      {
        final r = left.timestampRawHigh48.compareTo(right.timestampRawHigh48);
        if (r != 0) {
          return r;
        }
      }

      // Low 12 bits
      {
        final r = left.timestampRawLow12.compareTo(right.timestampRawLow12);
        if (r != 0) {
          return r;
        }
      }

      // 14 bit CS
      {
        final r = left.cs.compareTo(right.cs);
        if (r != 0) {
          return r;
        }
      }
    } else {
      // Ensure that leftVersion <= rightVersion
      if (leftVersion > rightVersion) {
        return compareByTimestampCsMac(right, left);
      }

      // One side is v1/v6.
      // One side is v7.
      // Numerically accurate comparison is difficult,
      // especially given Javascript integer limitations.
      {
        final r = compareToV1LikeToV7(left, right);
        if (r != 0) {
          return r;
        }
      }

      // 14 bit CS
      {
        final r = left.cs.compareTo(right.cs);
        if (r != 0) {
          return r;
        }
      }

      // Note that it's ensured that the method will NOT
      // return 0 (because versions are different).
    }

    // Compare MAC.
    {
      final r = left.mac.compareTo(right.mac);
      if (r != 0) {
        return r;
      }
    }

    // Compare version.
    {
      final r = left.version.compareTo(right.version);
      if (r != 0) {
        return r;
      }
    }

    // Compare variant.
    return left.variant.compareTo(right.variant);
  }

  /// Returns [DateTime] given 48-bit parameter p0 and 32-bit
  /// parameter p1.
  static DateTime? dateTimeFromInternalParameters(int p0, int p1) {
    if (isJs) {
      // In Javascript, DateTime has millisecond precision.
      final millisecondsSinceEpoch =
          millisecondsSinceEpochFromInternalParameters(
        p0,
        p1,
      );
      if (millisecondsSinceEpoch == null) {
        return null;
      }
      return DateTime.fromMillisecondsSinceEpoch(
        millisecondsSinceEpoch,
      );
    } else {
      final microsecondsSinceEpoch =
          microsecondsSinceEpochFromInternalParameters(
        p0,
        p1,
      );
      if (microsecondsSinceEpoch == null) {
        return null;
      }
      return DateTime.fromMicrosecondsSinceEpoch(
        microsecondsSinceEpoch,
      );
    }
  }

  /// Sets factory used by [Uuid] default constructor.
  ///
  /// If the method is called before, calling it again will throw [StateError].
  ///
  /// ## Example
  /// ```
  /// import 'package:kind_uuid/kind_uuid.dart';
  ///
  /// void main() {
  ///   // Set default factory.
  ///   Uuid.setDefaultFactory(Uuid.timestampedV7);
  ///
  ///   // Call default factory.
  ///   final uuid = Uuid();
  ///   print(uuid.version);
  /// }
  /// ```
  static void setDefaultFactory(Uuid Function() f) {
    if (_defaultFactory != null) {
      throw StateError('Default factory has already been set.');
    }
    _defaultFactory = f;
  }

  /// Parses canonical UUID string.
  ///
  /// Returns `null` if parsing fails.
  ///
  /// ## Example
  /// ```
  ///
  /// void main() {
  ///   final uuid = Uuid.tryParse('f81d4fae-7dec-11d0-a765-00a0c91e6bf6');
  ///   print(uuid);
  /// }
  /// ```
  static Uuid? tryParse(String s) {
    if (s.length != 36) {
      return null;
    }
    if (s.codeUnitAt(8) != _$dash ||
        s.codeUnitAt(13) != _$dash ||
        s.codeUnitAt(18) != _$dash ||
        s.codeUnitAt(23) != _$dash) {
      return null;
    }
    final v0 = _parseIntFromHex(s, 0, 8);
    final v1 = _parseIntFromHex(s, 9, 4);
    final v2 = _parseIntFromHex(s, 14, 4);
    final v3 = _parseIntFromHex(s, 19, 4);
    final mac = _parseIntFromHex(s, 24, 12);
    if (v0 < 0 || v1 < 0 || v2 < 0 || v3 < 0 || mac < 0) {
      return null;
    }
    final p0 = _bit16 * v0 + v1;
    final p1 = _bit16 * v2 + v3;
    final result = Uuid.fromInternalParameters(p0, p1, mac);

    // We don't want to fill _cachedString of Uuid.zero
    if (identical(result, zero)) {
      return result;
    }

    // Cache only lower-case string to be consistent
    // with strings constructed by toString().
    var isLowerCase = true;
    for (var i = 0; i < s.length; i++) {
      final c = s.codeUnitAt(i);
      if (c >= _$A && c <= _$F) {
        isLowerCase = false;
        break;
      }
    }
    if (isLowerCase) {
      result._cachedString = s;
    }

    return result;
  }

  /// If you are not happy with [defaultRandom] being [UuidRandom.instance],
  /// this changes it to [Random.secure] permanently.
  static void useSystemRandomByDefault() {
    _defaultRandom = Random.secure();
  }

  static int _parseIntFromHex(String s, int i, int length) {
    var result = 0;
    while (length > 0) {
      final c = s.codeUnitAt(i);
      result *= 16;
      if (c >= _$0 && c <= _$9) {
        result += c - _$0;
      } else if (c >= _$a && c <= _$f) {
        result += c - (_$a - 10);
      } else if (c >= _$A && c <= _$F) {
        result += c - (_$A - 10);
      } else {
        return -1;
      }
      length--;
      i++;
    }
    return result;
  }

  static int _variantNumberFromByte(int bits) {
    if ((bits >> 7) == 0) {
      return 0;
    }
    if ((bits >> 6) == 0x2) {
      return 1;
    }
    if ((bits >> 5) == 0x6) {
      return 2;
    }
    if ((bits >> 5) == 0x7) {
      return 3;
    }
    return -1;
  }

  static void _writeByte(StringBuffer sb, int byte) {
    sb.write(_chars[0xF & (byte >> 4)]);
    sb.write(_chars[0xF & byte]);
  }
}

class _Uuid extends Uuid {
  @override
  final int p0;

  @override
  final int p1;

  @override
  final int mac;

  _Uuid(this.p0, this.p1, this.mac) : super.constructor() {
    assert(p0 >= 0 && p0 < _bit48);
    assert(p1 >= 0 && p1 < _bit32);
    assert(mac >= 0 && mac < _bit48);
  }
}
