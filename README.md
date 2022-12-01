[![Pub Package](https://img.shields.io/pub/v/kind_uuid.svg)](https://pub.dartlang.org/packages/kind_uuid)
[![Github Actions CI](https://github.com/dint-dev/kind_uuid/workflows/Dart%20CI/badge.svg)](https://github.com/dint-dev/kind_uuid/actions?query=workflow%3A%22Dart+CI%22)

# Overview
## Features
  * This package gives you [Uuid](https://pub.dev/documentation/kind_uuid/latest/kind_uuid/Uuid-class.html)
    for generating unique UUIDs and converting them into strings and bytes.
  * Supports UUID versions 1 (timestamped), 4 (random), 6, and 7.
    The last two are IETF [drafts](https://uuid6.github.io/uuid6-ietf-draft/) as of 2022.
  * Works in all platforms, including browsers.
  * Excellent performance.

## Links
  * [API documentation](https://pub.dev/documentation/kind_uuid/latest/)
  * [Github project](https://github.com/dint-dev/kind_uuid)
    * We appreciate feedback, issue reports, and pull requests.

# Getting started
## 1.Add dependency
In _pubspec.yaml_:
```yaml
dependencies:
  kind_uuid: ^1.0.0
```

## 2.Use package
```dart
import 'package:kind_uuid/kind_uuid.dart';

void main() {
  // We recommend you to use the default constructor so you can make
  // application-wide changes with Uuid.setDefaultFactory(...).
  final uuid = Uuid();
  print('UUID: $uuid');
  print('UUID bytes: ${uuid.toBytes()}');

  // Construct an UUID with version 1.
  final timestamped = Uuid.timestampedV1();
  print('Timestamped UUID timestamp: ${timestamped.dateTime()}');

  // Parse a string
  final parsedUuid = Uuid.parse('f81d4fae-7dec-11d0-a765-00a0c91e6bf6');
  print('UUID from string: $parsedUuid');

  // Read bytes
  final uuidFromBytes = Uuid.fromBytes(
    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],
  );
  print('UUID from bytes: $uuidFromBytes');
}
```

# Manual
## Generating UUIDs
We recommend that you use the [Uuid()](https://pub.dev/documentation/kind_uuid/latest/kind_uuid/Uuid/Uuid.html):
```dart
final uuid = Uuid();
```

It can be configured with [Uuid.setDefaultFactory(...)](https://pub.dev/documentation/kind_uuid/latest/kind_uuid/Uuid/setDefaultFactory.html):
```dart
void main() {
  // Set default UUID factory.
  Uuid.setDefaultFactory(Uuid.timestampedV1);
  
  // Construct UUIDs.
  final uuid = Uuid();
  print(uuid);
}
```

All the supported versions are:
  * [Uuid.random](https://pub.dev/documentation/kind_uuid/latest/kind_uuid/Uuid/random.html)
    generates UUIDs with version 4 ([RFC 4122](https://datatracker.ietf.org/doc/html/rfc4122)).
  * [Uuid.timestampedV1](https://pub.dev/documentation/kind_uuid/latest/kind_uuid/Uuid/timestampedV1.html)
    generates UUIDs with version 1 ([RFC 4122](https://datatracker.ietf.org/doc/html/rfc4122)).
  * [Uuid.timestampedV6](https://pub.dev/documentation/kind_uuid/latest/kind_uuid/Uuid/timestampedV6.html)
    generates UUIDs with version 6 ([RFC draft](https://datatracker.ietf.org/doc/html/draft-ietf-uuidrev-rfc4122bis)).
  * [Uuid.timestampedV7](https://pub.dev/documentation/kind_uuid/latest/kind_uuid/Uuid/timestampedV6.html)
    generates UUIDs with version 7 ([RFC draft](https://datatracker.ietf.org/doc/html/draft-ietf-uuidrev-rfc4122bis)).


## Timestamping behavior

If you don't specify _DateTime_ yourself, it is taken from the zone-local [clock](https://pub.dev/documentation/clock/latest/clock/clock.html)
(in [package:clock](https://pub.dev/packages/clock)). In Dart, _DateTime_ has millisecond
precision in browsers and microsecond precision in other platforms.
If the system clock moves backward (because of time synchronization), a small (under 1 second)
change is ignored and the previous clock value will be returned until the system clock is greater
than it. Thus timestamps tend to retain the real chronological order.

The (usually 14 bit) "clock sequence" field has a random value. If timestamp is equal to the
previous timestamp, the previous clock sequence value is incremented by a random amount. Integer
overflow is carried to the timestamp integer.

You can write a custom
[TimestampingState](https://pub.dev/documentation/kind_uuid/latest/kind_uuid/TimestampingState-class.html)
if you want to customize the behavior.

## Random number generator

By default, UUID generation uses [UuidRandom](https://pub.dev/documentation/kind_uuid/latest/kind_uuid/UuidRandom-class.html),
which enables much better performance than _Random.secure()_. Our benchmarks show that _UuidRandom_
can be approximately 500 times faster.

_UuidRandom_ retains good enough security for UUID generation (but NOT other use cases).
_Random.secure()_ is used as entropy source in the beginning and roughly every 100k UUIDs. New
blocks are generated with a modified ChaCha20 that does only 8 rounds. The formula for computing the
next block of random numbers is `chacha20_with_8_rounds(previous_block XOR secret_block)`.

If you are unhappy with the optimization, you can change the random number generator by calling
[Uuid.useSystemRandomByDefault()](https://pub.dev/documentation/kind_uuid/latest/kind_uuid/Uuid/useSystemRandomByDefault.html).
You can also specify a random number generator when you generate UUIDs:
```dart
final uuid = Uuid.timestampedV1(random: yourRandom);
```