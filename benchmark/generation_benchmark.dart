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

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:kind_uuid/kind_uuid.dart';

void main() {
  UuidBenchmark(
    '1000 x Uuid.random()',
    version: 4,
  ).report();
  UuidBenchmark(
    '1000 x Uuid.random(random: Random.secure())',
    version: 4,
    random: Random.secure(),
  ).report();
  UuidBenchmark(
    '1000 x Uuid.timestampedV7()',
    version: 7,
  ).report();
  UuidBenchmark(
    '1000 x Uuid.timestampedV7(random: Random.secure())',
    version: 7,
    random: Random.secure(),
  ).report();
}

class UuidBenchmark extends BenchmarkBase {
  final int version;
  final Random? random;
  const UuidBenchmark(String name, {required this.version, this.random})
      : super(name);

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      Uuid.withVersion(version, random: random);
    }
  }

  @override
  void setup() {
    Uuid.random(random: random);
  }
}
