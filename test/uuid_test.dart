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

import 'dart:typed_data';

import 'package:kind_uuid/kind_uuid.dart';
import 'package:test/test.dart';

void main() {
  group('Uuid', () {
    test('implements Comparable', () {
      expect(Uuid.zero, isA<Comparable<Uuid>>());
      while (true) {
        final uuid0 = Uuid.random();
        final uuid1 = Uuid.random();
        final byte0 = uuid0.toBytes().first;
        final byte1 = uuid1.toBytes().first;
        if (byte0 == byte1) {
          continue;
        }
        expect(uuid0.compareTo(uuid1), byte0.compareTo(byte1));
        break;
      }
    });

    test('Uuid()', () {
      {
        final uuid = Uuid();
        expect(uuid.version, 4);
      }
      {
        final uuid = Uuid();
        expect(uuid.version, 4);
      }
    });

    test('Uuid.setDefaultFactory()', () {
      Uuid.setDefaultFactory(() => Uuid.timestampedV7());
      {
        final uuid0 = Uuid();
        expect(uuid0.version, 7);
        final uuid1 = Uuid();
        expect(uuid1.version, 7);
        expect(uuid0, isNot(uuid1));
      }
      expect(
        () => Uuid.setDefaultFactory(() => Uuid.random()),
        throwsStateError,
      );
      {
        final uuid = Uuid();
        expect(uuid.version, 7);
      }
    });

    group('Uuid.parse()', () {
      const example = 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6';
      const exampleBytes = [
        0xf8,
        0x1d,
        0x4f,
        0xae,
        // -
        0x7d,
        0xec,
        // -
        0x11,
        0xd0,
        // -
        0xa7,
        0x65,
        // -
        0x00,
        0xa0,
        0xc9,
        0x1e,
        0x6b,
        0xf6,
      ];

      test('"" throws FormatException', () {
        expect(
          () => Uuid.parse(''),
          throwsFormatException,
        );
      });

      test('too short throws FormatException', () {
        expect(
          () => Uuid.parse(example.substring(1)),
          throwsFormatException,
        );
        expect(
          () => Uuid.parse(example.substring(0, 35)),
          throwsFormatException,
        );
      });

      test('too long throws FormatException', () {
        expect(
          () => Uuid.parse('${example}8'),
          throwsFormatException,
        );
        expect(
          () => Uuid.parse('8$example'),
          throwsFormatException,
        );
      });

      test('minus as first character throws FormatException', () {
        expect(
          () => Uuid.parse('-${example.substring(1)}'),
          throwsFormatException,
        );
      });

      test('lower-case UUID is parsed', () {
        final uuid = Uuid.parse(example.toLowerCase());
        expect(uuid.toBytes(), exampleBytes);
        expect(uuid.toString(), example.toLowerCase());
      });

      test('lower-case UUID does not affect output of toString', () {
        final uuid = Uuid.parse(example.toLowerCase());
        expect(uuid.toString(), example.toLowerCase());
      });

      test('upper-case UUID is parsed', () {
        final uuid = Uuid.parse(example.toUpperCase());
        expect(uuid.toBytes(), exampleBytes);
      });

      test('upper-case UUID does not affect output of toString', () {
        final uuid = Uuid.parse(example.toUpperCase());
        expect(uuid.toString(), example.toLowerCase());
      });

      test('all-zeroes UUID, returns Uuid.zero', () {
        expect(Uuid.parse(Uuid.zero.toString()), same(Uuid.zero));
      });

      for (var version in Uuid.supportedVersions) {
        test('parse 1000 UUIDs, version $version', () {
          for (var i = 0; i < 1000; i++) {
            final uuid = Uuid.withVersion(version);
            final parsedUuid = Uuid.parse(uuid.toString());
            expect(parsedUuid, uuid);
            expect(uuid, parsedUuid);
          }
        });
      }
    });

    group('Uuid.tryParse()', () {
      test('missing "-"', () {
        expect(Uuid.tryParse('f81d4fae7dec-11d0-a765-00a0c91e6bf6'), isNull);
        expect(Uuid.tryParse('f81d4fae-7dec11d0-a765-00a0c91e6bf6'), isNull);
        expect(Uuid.tryParse('f81d4fae-7dec-11d0a765-00a0c91e6bf6'), isNull);
        expect(Uuid.tryParse('f81d4fae-7dec-11d0-a76500a0c91e6bf6'), isNull);
      });
      test('too short', () {
        expect(Uuid.tryParse('81d4fae-7dec-11d0-a765-00a0c91e6bf6'), isNull);
        expect(Uuid.tryParse('f81d4fae-7dec-11d0-a765-00a0c91e6bf'), isNull);
      });
      test('too long', () {
        expect(Uuid.tryParse('-f81d4fae-7dec-11d0-a765-00a0c91e6bf6'), isNull);
        expect(Uuid.tryParse('f81d4fae-7dec-11d0-a765-00a0c91e6bf6-'), isNull);
        expect(Uuid.tryParse('0f81d4fae-7dec-11d0-a765-00a0c91e6bf6'), isNull);
        expect(Uuid.tryParse('f81d4fae-7dec-11d0-a765-00a0c91e6bf60'), isNull);
      });
      test('invalid characters in dashes', () {
        expect(Uuid.tryParse('f81d4fae_7dec-11d0-a765-00a0c91e6bf6'), isNull);
        expect(Uuid.tryParse('f81d4fae-7dec_11d0-a765-00a0c91e6bf6'), isNull);
        expect(Uuid.tryParse('f81d4fae-7dec-11d0_a765-00a0c91e6bf6'), isNull);
        expect(Uuid.tryParse('f81d4fae-7dec-11d0-a765_00a0c91e6bf6'), isNull);
      });
      test('invalid characters in 1st group', () {
        expect(Uuid.tryParse('f81d4ggg-7dec-11d0-a765-00a0c91e6bf6'), isNull);
        expect(Uuid.tryParse('f81d4GGG-7dec-11d0-a765-00a0c91e6bf6'), isNull);
      });
      test('invalid characters in 2nd group', () {
        expect(Uuid.tryParse('f81d4fae-gggg-11d0-a765-00a0c91e6bf6'), isNull);
        expect(Uuid.tryParse('f81d4fae-GGGG-11d0-a765-00a0c91e6bf6'), isNull);
      });
      test('invalid characters in 3rd group', () {
        expect(Uuid.tryParse('f81d4fae-7dec-gggg-a765-00a0c91e6bf6'), isNull);
        expect(Uuid.tryParse('f81d4fae-7dec-GGGG-a765-00a0c91e6bf6'), isNull);
      });
      test('invalid characters in 4th group', () {
        expect(Uuid.tryParse('f81d4fae-7dec-11d0-gg65-00a0c91e6bf6'), isNull);
        expect(Uuid.tryParse('f81d4fae-7dec-11d0-GG65-00a0c91e6bf6'), isNull);
      });
      test('invalid characters in 5th group', () {
        expect(Uuid.tryParse('f81d4fae-7dec-11d0-a765-00a0c91egggg'), isNull);
        expect(Uuid.tryParse('f81d4fae-7dec-11d0-a765-00a0c91eGGGG'), isNull);
      });
      test('valid', () {
        final uuid = Uuid.tryParse('f81d4fae-7dec-11d0-a765-00a0c91e6bf6');
        expect(uuid, isNotNull);
      });
      test('Parsing Uuid.zero return the same instance', () {
        expect(Uuid.parse(Uuid.zero.toString()), Uuid.zero);
      });
    });

    group('Uuid.fromBytes()', () {
      test('16 bytes', () {
        final bytes = Uint8List(16);
        for (var i = 0; i < bytes.length; i++) {
          bytes[i] = i;
        }
        final uuid = Uuid.fromBytes(bytes);
        expect(uuid.toBytes(), hasLength(16));
        expect(uuid.toBytes(), equals(bytes));
        expect(uuid.toBytes(), isNot(same(bytes)));
      });

      test('offset, 1, length = 18', () {
        final bytes = Uint8List(18);
        for (var i = 0; i < bytes.length; i++) {
          bytes[i] = i;
        }
        final uuid = Uuid.fromBytes(bytes, offset: 1);
        expect(uuid.toBytes(), hasLength(16));
        expect(uuid.toBytes(), equals(bytes.sublist(1, 17)));
      });

      test('all zeroes', () {
        final bytes = Uint8List(16);
        final uuid = Uuid.fromBytes(bytes);
        expect(uuid, same(Uuid.zero));
      });
    });

    test('== / hashCode', () {
      final value = Uuid.parse('f81d4fae-7dec-11d0-a765-00a0c91e6bf6');

      final clone0 = Uuid.parse('f81d4fae-7dec-11d0-a765-00a0c91e6bf6');
      final clone1 = Uuid.fromBytes(value.toBytes());
      final other0 = Uuid.parse('f81d4fae-7dec-11d0-0000-00a0c91e6bf6');
      final other1 = Uuid.fromBytes(other0.toBytes());

      expect(clone0, value);
      expect(clone1, value);
      expect(other0, isNot(value));
      expect(other1, isNot(value));

      expect(value, clone0);
      expect(value, clone1);
      expect(value, isNot(other0));
      expect(value, isNot(other1));

      expect(value.hashCode, clone0.hashCode);
      expect(value.hashCode, clone1.hashCode);
      expect(value.hashCode, isNot(other0.hashCode));
      expect(value.hashCode, isNot(other1.hashCode));
    });

    group('ticksLow12 / ticksHigh48', () {
      List<int> exampleBytes({required int version}) {
        return [
          // "low" bits in the standard
          0x01,
          0x23,
          0x45,
          0x67,

          // "mid" bits in the standard
          0x89,
          0xab,

          // "highAndVersion" bits in the standard
          0x0d | (version << 4),
          0xef,

          // Clock sequence
          0x80, // Variant = 1
          0x00,

          // Mac
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
        ];
      }

      test('when v1', () {
        final bytes = exampleBytes(version: 1);
        final uuid = Uuid.fromBytes(bytes);
        expect(
          _hex(uuid.p0),
          '123456789ab',
        );
        expect(
          _hex(uuid.p1),
          '1def8000',
        );
        expect(
          _hex(uuid.timestampRawLow12),
          '567',
        );
        expect(
          _hex(uuid.timestampRawHigh48),
          'def 89ab 01234'.replaceAll(' ', ''),
        );
      });

      test('when v6', () {
        final bytes = exampleBytes(version: 6);
        final uuid = Uuid.fromBytes(bytes);
        expect(
          _hex(uuid.p0),
          '123456789ab',
        );
        expect(
          _hex(uuid.p1),
          '6def8000',
        );
        expect(
          _hex(uuid.timestampRawLow12),
          'def',
        );
        expect(
          _hex(uuid.timestampRawHigh48),
          '123456789ab',
        );
      });
      test('when v7', () {
        final bytes = exampleBytes(version: 7);
        final uuid = Uuid.fromBytes(bytes);
        expect(
          _hex(uuid.p0),
          '123456789ab',
        );
        expect(
          _hex(uuid.p1),
          '7def8000',
        );
        expect(
          _hex(uuid.timestampRawLow12),
          'def',
        );
        expect(
          _hex(uuid.timestampRawHigh48),
          '123456789ab',
        );
      });
    });

    test('compareTo()', () {
      final f = Uuid.fromInternalParameters;
      {
        final a = f(0, 0, 2);
        expect(a.compareTo(f(0, 0, 3)), -1);
        expect(a.compareTo(f(0, 0, 2)), 0);
        expect(a.compareTo(f(0, 0, 1)), 1);
      }
      {
        final a = f(0, 2, 9);
        expect(a.compareTo(f(0, 3, 0)), -1);
        expect(a.compareTo(f(0, 2, 9)), 0);
        expect(a.compareTo(f(0, 1, 0)), 1);
      }
      {
        final a = f(2, 9, 9);
        expect(a.compareTo(f(3, 0, 0)), -1);
        expect(a.compareTo(f(2, 9, 9)), 0);
        expect(a.compareTo(f(1, 0, 0)), 1);
      }
    });
    test('Uuid.compareByBytes', () {
      final f = Uuid.fromInternalParameters;
      final c = Uuid.compareByBytes;
      {
        final a = f(0, 0, 2);
        expect(c(a, f(0, 0, 3)), -1);
        expect(c(a, f(0, 0, 2)), 0);
        expect(c(a, f(0, 0, 1)), 1);
      }
      {
        final a = f(0, 2, 9);
        expect(c(a, f(0, 3, 0)), -1);
        expect(c(a, f(0, 2, 9)), 0);
        expect(c(a, f(0, 1, 0)), 1);
      }
      {
        final a = f(2, 9, 9);
        expect(c(a, f(3, 0, 0)), -1);
        expect(c(a, f(2, 9, 9)), 0);
        expect(c(a, f(1, 0, 0)), 1);
      }
    });
    group('Uuid.compareByTimestampCsMac()', () {
      const n = 100000;

      DateTime? maybeRandomDateTime(int i) {
        if (i % 10 == 0) {
          return UuidTimestampingState.instance.now().add(
                [
                  Duration(microseconds: 1),
                  Duration(microseconds: 10),
                  Duration(microseconds: 100),
                  Duration(microseconds: 900),
                  Duration(milliseconds: 1),
                  Duration(milliseconds: 10),
                  Duration(milliseconds: 100),
                  Duration(milliseconds: 900),
                  Duration(seconds: 59),
                  Duration(days: 1),
                  Duration(days: 10000),
                ][Uuid.defaultRandom.nextInt(4)],
              );
        }
        return null;
      }

      String reason(Uuid first, Uuid second, {int? index}) {
        return 'index: $index\n'
            '\n'
            'A: $first\n'
            'B: $second\n'
            '\n'
            'raw timestamp (epoch/unit not normalized):\n'
            'high48 A: ${_hex(first.timestampRawHigh48, 12)}\n'
            'high48 B: ${_hex(second.timestampRawHigh48, 12)}\n'
            'low12 A: ${_hex(first.timestampRawLow12, 3)}\n'
            'low12 B: ${_hex(second.timestampRawLow12, 3)}\n'
            '\n'
            'microseconds:\n'
            'A: ${_hex(first.microsecondsSinceEpoch!, 12)}\n'
            'B: ${_hex(second.microsecondsSinceEpoch!, 12)}\n'
            '\n'
            'dateTime:\n'
            'A: ${first.dateTime()}\n'
            'B: ${second.dateTime()}\n'
            '\n'
            'cs:\n'
            'A: ${_hex(first.cs, 14)}\n'
            'B: ${_hex(second.cs, 14)}\n';
      }

      test('v1 < v1 ($n times)', () {
        for (var i = 0; i < n; i++) {
          final first = Uuid.timestampedV1();
          final second = Uuid.timestampedV1(
            dateTime: maybeRandomDateTime(i),
          );
          expect(
            Uuid.compareByTimestampCsMac(first, second),
            lessThan(0),
            reason: reason(first, second, index: i),
          );
        }
      });

      test('v1 < v6 ($n times)', () {
        for (var i = 0; i < n; i++) {
          final first = Uuid.timestampedV1();
          final second = Uuid.timestampedV6(
            dateTime: maybeRandomDateTime(i),
          );
          expect(
            Uuid.compareByTimestampCsMac(first, second),
            lessThan(0),
            reason: reason(first, second, index: i),
          );
        }
      });

      test('v1 < v7 ($n times)', () {
        for (var i = 0; i < n; i++) {
          final first = Uuid.timestampedV1();
          final second = Uuid.timestampedV7(
            dateTime: maybeRandomDateTime(i),
          );
          expect(
            Uuid.compareByTimestampCsMac(first, second),
            lessThan(0),
            reason: reason(first, second, index: i),
          );
        }
      });

      test('v6 < v1 ($n times)', () {
        for (var i = 0; i < n; i++) {
          final first = Uuid.timestampedV6();
          final second = Uuid.timestampedV1(
            dateTime: maybeRandomDateTime(i),
          );
          expect(
            Uuid.compareByTimestampCsMac(first, second),
            lessThan(0),
            reason: reason(first, second, index: i),
          );
        }
      });

      test('v6 < v6 ($n times)', () {
        for (var i = 0; i < n; i++) {
          final first = Uuid.timestampedV6();
          final second = Uuid.timestampedV6(
            dateTime: maybeRandomDateTime(i),
          );
          expect(
            Uuid.compareByTimestampCsMac(first, second),
            lessThan(0),
            reason: reason(first, second, index: i),
          );
        }
      });

      test('v6 < v7 ($n times)', () {
        for (var i = 0; i < n; i++) {
          final first = Uuid.timestampedV6();
          final second = Uuid.timestampedV7(
            dateTime: maybeRandomDateTime(i),
          );
          expect(
            Uuid.compareByTimestampCsMac(first, second),
            lessThan(0),
            reason: reason(first, second, index: i),
          );
        }
      });

      test('v7 < v1 ($n times)', () {
        for (var i = 0; i < n; i++) {
          final first = Uuid.timestampedV7();
          final second = Uuid.timestampedV1(
            dateTime: maybeRandomDateTime(i),
          );
          expect(
            Uuid.compareByTimestampCsMac(first, second),
            lessThan(0),
            reason: reason(first, second, index: i),
          );
        }
      });

      test('v7 < v6 ($n times)', () {
        for (var i = 0; i < n; i++) {
          final first = Uuid.timestampedV7();
          final second = Uuid.timestampedV6(
            dateTime: maybeRandomDateTime(i),
          );
          expect(
            Uuid.compareByTimestampCsMac(first, second),
            lessThan(0),
            reason: reason(first, second, index: i),
          );
        }
      });

      test('v7 < v7 ($n times)', () {
        for (var i = 0; i < n; i++) {
          final first = Uuid.timestampedV7();
          final second = Uuid.timestampedV7(
            dateTime: maybeRandomDateTime(i),
          );
          expect(
            Uuid.compareByTimestampCsMac(first, second),
            lessThan(0),
            reason: reason(first, second, index: i),
          );
        }
      });
    });
  });
}

String _hex(int v, [int length = 0]) =>
    v.toRadixString(16).padLeft(length, '0');
