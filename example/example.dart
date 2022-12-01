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
