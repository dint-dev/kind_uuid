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
  group('Uuid.random(...)', () {
    const version = 4;

    test('version', () {
      final uuid = Uuid.random();
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

    test('== / hashCode', () {
      const tenThousand = 10000;
      for (var i = 0; i < tenThousand; i++) {
        final value = Uuid.random();

        final clone0 =
            Uuid.fromInternalParameters(value.p0, value.p1, value.mac);
        final clone1 = Uuid.parse(value.toString());
        final clone2 = Uuid.fromBytes(value.toBytes());
        final other0 = Uuid.random();

        expect(clone0.dateTime(), isNull);
        expect(clone1.dateTime(), isNull);
        expect(clone2.dateTime(), isNull);

        expect(clone0.timestampRaw, value.timestampRaw);
        expect(clone1.timestampRaw, value.timestampRaw);
        expect(clone2.timestampRaw, value.timestampRaw);

        expect(clone0.cs, value.cs);
        expect(clone1.cs, value.cs);
        expect(clone2.cs, value.cs);

        expect(clone0, value);
        expect(clone1, value);
        expect(clone2, value);

        expect(other0, isNot(value));

        expect(clone0.hashCode, value.hashCode);
        expect(clone1.hashCode, value.hashCode);
        expect(clone2.hashCode, value.hashCode);

        expect(other0.hashCode, isNot(value.hashCode));
      }
    });

    test('version', () {
      final uuid = Uuid.random();
      expect(uuid.version, version);
    });

    test('version', () {
      final uuid = Uuid.random();
      expect(uuid.version, version);
    });

    test('variantNumber', () {
      final uuid = Uuid.random();
      expect(uuid.variant, 1);
    });
  });
}
