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

import 'package:kind_uuid/kind_uuid.dart';
import 'package:test/test.dart';

void main() {
  group('Uuid.timestampedV6(...)', () {
    const version = 6;

    test('version', () {
      final uuid = Uuid.timestampedV6();
      expect(uuid.version, version);
    });

    test('version', () {
      final uuid = Uuid.withVersion(version);
      expect(uuid.version, version);
    });

    test('variantNumber', () {
      final uuid = Uuid.withVersion(version);
      expect(uuid.variant, 1);
    });

    test('== / hashCode, dateTime()', () {
      const tenThousand = 10000;
      for (var i = 0; i < tenThousand; i++) {
        final value = Uuid.withVersion(version);

        final clone0 =
            Uuid.fromInternalParameters(value.p0, value.p1, value.mac);
        final clone1 = Uuid.parse(value.toString());
        final clone2 = Uuid.fromBytes(value.toBytes());
        final other0 = Uuid.timestampedV6();

        expect(
          clone0,
          value,
          reason:
              'Uuid.fromInternalParameters(..), value=$value, clone=$clone0',
        );
        expect(
          clone1,
          value,
          reason: 'Uuid.parse(..), value=$value, clone=$clone1',
        );
        expect(
          clone2,
          value,
          reason: 'Uuid.fromBytes(..), value=$value, clone=$clone2',
        );

        expect(
          clone0.hashCode,
          value.hashCode,
          reason:
              'Uuid.fromInternalParameters(..), value=$value, clone=$clone0',
        );
        expect(
          clone1.hashCode,
          value.hashCode,
          reason: 'Uuid.parse(..), value=$value, clone=$clone1',
        );
        expect(
          clone2.hashCode,
          value.hashCode,
          reason: 'Uuid.fromBytes(..), value=$value, clone=$clone2',
        );

        expect(other0.hashCode, isNot(value.hashCode));
      }
    });

    test('dateTime()', () {
      const tenThousand = 10000;
      for (var i = 0; i < tenThousand; i++) {
        final value = Uuid.withVersion(version);

        final now = DateTime.now();
        final dateTime = value.dateTime()!;
        expect(dateTime.year, now.year);
        expect(dateTime.month, now.month);
        expect(dateTime.day, now.day);
        expect(dateTime.hour, now.hour);
        expect(dateTime.minute, now.minute);
      }
    });
  });
}
