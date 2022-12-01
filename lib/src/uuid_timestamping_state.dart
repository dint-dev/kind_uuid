import 'dart:math';

import 'package:clock/clock.dart';
import 'package:clock/clock.dart' as clock_package;

import '../kind_uuid.dart';

/// State for generating unique timestamps.
///
/// Used by:
///   * [Uuid.timestampedV1]
///   * [Uuid.timestampedV6]
///   * [Uuid.timestampedV7]
abstract class UuidTimestampingState {
  /// Default instance used by timestamp-requiring [Uuid] factories.
  ///
  /// Used by:
  ///   * [Uuid.timestampedV1]
  ///   * [Uuid.timestampedV6]
  ///   * [Uuid.timestampedV7]
  static final UuidTimestampingState instance = UuidTimestampingState();

  /// Constructs a new default implementation of UUID timestamping state.
  ///
  /// Optional parameter [clock] specifies clock used by [now]. Otherwise
  /// zone-local clock ([clock_package.clock]) is used.
  ///
  /// Optional parameter [maxIgnoredClockDrop] is the maximum duration that
  /// the system clock can drop from the previous value without affecting
  /// timestamps. If a drop is ignored, the earlier value from the system clock
  /// will be returned by [now] until the clock has reached a higher value.
  factory UuidTimestampingState({
    Clock? clock,
    Duration maxIgnoredClockDrop = const Duration(seconds: 1),
  }) {
    return _UuidTimestampingState(
      clock: clock,
      maxIgnoredClockDrop: maxIgnoredClockDrop,
    );
  }

  /// Returns the next "clock sequence" (CS) field value.
  ///
  /// Used by:
  ///   * [Uuid.timestampedV1]
  ///   * [Uuid.timestampedV6]
  ///   * [Uuid.timestampedV7]
  ///
  /// The method returns an unsigned integer with N bits for the CS value, where
  /// N depends on the [variant]. The possible values of N are:
  ///   * Variant 0: 15 bits
  ///   * Variant 1: 14 bits
  ///   * Variants 2 and 3: 13 bits
  ///
  /// Caller must increment the UUID timestamp with the bits above the N bits
  /// reserved for the CS:
  /// ```
  /// // Get CS
  /// final cs = timestampingState.nextCs(
  ///   // ...
  /// );
  ///
  /// // Increment timestamp low 12 bits
  /// low12 += cs >> 14
  /// cs &= 0x3FFF;
  ///
  ///
  /// // Increment timestamp high 48 bits
  /// high12 += low12 >> 12
  /// low12 &= 0xFFF;
  /// ```
  int nextCs({
    required int version,
    required int variant,
    required int mac,
    required DateTime dateTime,
    required int high48,
    required int low12,
    required Random random,
  });

  /// Returns the current [DateTime].
  ///
  /// Used by:
  ///   * [Uuid.timestampedV1]
  ///   * [Uuid.timestampedV6]
  ///   * [Uuid.timestampedV7]
  DateTime now();
}

class _UuidTimestampingState implements UuidTimestampingState {
  final Clock? _clock;

  final Duration maxIgnoredClockDrop;
  DateTime? _previousNow;
  DateTime? _previousUuidDateTime;
  int? _previousUuidCounter;
  DateTime? _previousUuidDateTimePlusCounter;

  _UuidTimestampingState({
    required Clock? clock,
    required this.maxIgnoredClockDrop,
  }) : _clock = clock;

  @override
  int nextCs({
    required int version,
    required int variant,
    required int mac,
    required DateTime dateTime,
    required int high48,
    required int low12,
    required Random random,
  }) {
    var bits = 14;

    if (variant != 1) {
      if (variant == 0) {
        bits = 15;
      } else if (variant == 2 || variant == 3) {
        bits = 13;
      } else {
        throw ArgumentError.value(variant, 'variant');
      }
    }

    // Get the previous timestamp `t`.
    final previousDateTime = _previousUuidDateTime;

    // Get timestamp `t + cs(t)`.
    final previousDateTimePlusCounter = _previousUuidDateTimePlusCounter;

    // If the timestamp is in the range,
    // we want to increment CS.
    if (previousDateTimePlusCounter != null &&
        !dateTime.isAfter(previousDateTimePlusCounter) &&
        previousDateTime != null &&
        !dateTime.isBefore(previousDateTime)) {
      // Try to make it hard to analyze how many UUIDs exist between two UUIDs
      // when they have timestamp near each other.
      final step = 1 + random.nextInt((1 << bits) >> 1);
      final counter = (_previousUuidCounter ?? 0) + step;
      _previousUuidCounter = counter;
      final overflow = (counter ~/ (1 << bits)) ~/ 10;
      if (overflow != 0) {
        _previousUuidDateTimePlusCounter = previousDateTime.add(Duration(
          microseconds: overflow,
        ));
      }
      return counter;
    } else {
      // Generate random DateTime.
      //
      // The constant allows 10 UUID per microseconds in v1, v6, and v7.
      // In practice, the fastest hardware will give no more than five UUIDs
      // per microsecond.
      final cs = random.nextInt(1 << bits);
      _previousUuidDateTime = dateTime;
      _previousUuidDateTimePlusCounter = dateTime;
      _previousUuidCounter = cs;
      return cs;
    }
  }

  @override
  DateTime now() {
    final clock = _clock ?? clock_package.clock;
    final now = clock.now();

    // Ignore small clock movements backwards.
    //
    // See README.md for justification.
    final previousNow = _previousNow;
    if (previousNow != null && now.isBefore(previousNow)) {
      if (now.difference(previousNow).abs() < maxIgnoredClockDrop) {
        return previousNow;
      }
    }

    _previousNow = now;
    return now;
  }
}
