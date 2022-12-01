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
  // KEY PARAMETERS
  // --------------
  // We don't want to our Github CI to take hours to complete so run long tests
  // only locally.
  const batchN = 1;
  const uuidsPerTest = 1 * _million;

  // Other constants
  final mac = 0x11223345566;

  for (var batch = 1; batch <= batchN; batch++) {
    group('Batch #$batch:', () {
      test(
          'No collisions in ${uuidsPerTest / 1000000} million UUIDs, version = 4',
          () {
        final set = <Uuid>{};
        for (var i = 0; i < uuidsPerTest; i++) {
          // Generate UUID.
          final uuid = Uuid.random();

          // Try to find same UUID.
          final existing = set.lookup(uuid);
          expect(
            existing,
            isNull,
            reason: 'i = $i\n'
                'uuid = $uuid',
          );
          expect(set.add(uuid), isTrue);
        }
      });

      const timestampedVersions = [
        1,
        6,
        7,
      ];

      for (var version in timestampedVersions) {
        test(
            'No collisions in ${uuidsPerTest / 1000000} million UUIDs, version = $version',
            () {
          final set = <Uuid>{};
          for (var i = 0; i < uuidsPerTest; i++) {
            // Generate UUID.
            final uuid = Uuid.withVersion(version, mac: mac);

            // Try to find same UUID.
            final existing = set.lookup(uuid);
            expect(existing, isNull);

            // Check that the MACs are same
            if (i == 0) {
              expect(uuid.mac, mac);
            }
          }
        });
      }
    });
  }
}

const _million = 1000000;
