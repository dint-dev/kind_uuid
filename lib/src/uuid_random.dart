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

/// A random number number generator for generating UUIDs that can be 100-1000
/// times faster than [Random.secure].
///
/// The algorithm is based on the widely used ChaCha20 cipher. We use only 8
/// rounds by default. It's important to note that, while the 8 round version
/// is good enough for UUID generation, this MUST NOT be used for other
/// purposes.
///
/// In the beginning and every N blocks (default: 65k, which is >100k UUIDs),
/// both the state block and the secret block are mixed (XOR) with
/// blocks from [Random.secure].
class UuidRandom implements Random {
  static const int _bit32 = 0x100000000;

  /// Default number of ChaCha20 rounds done for each block.
  static const int defaultChaChaRounds = 8;

  /// Default count of blocks generated before all states are mixed with
  /// values from [Random.secure].
  static const int defaultBlocksBeforeSystemCall = 1 << 14;

  /// Number of 32-bit unsigned integers in a block.
  static const int _blockLength = 16;

  static const _mask32 = 0xFFFFFFFF;

  /// Random number generator.
  final Random _random;

  /// States.
  final _state = Uint32List(1 * _blockLength);

  final _secret = Uint32List(_blockLength);

  /// Next index.
  int _nextIndex = 0;

  /// Minimum number of Chacha20 rounds?
  final int _rounds;

  /// How often we should call [Random.secure]?
  final int _blocksBeforeSystemCall;

  /// Constructs a new UUID random number generator.
  ///
  /// The number of ChaCha20 rounds done for each block (20 in ChaCha20, but
  /// UUIDs can do with fewer) is determined by [chaChaRounds] (default: 8).
  ///
  /// Optional parameter [blocksBeforeSystemCall] (default: around 65k blocks)
  /// specifies how many blocks is generated before the state block and the
  /// secret block are mixed (XOR) with blocks from [random].
  UuidRandom({
    int chaChaRounds = defaultChaChaRounds,
    int blocksBeforeSystemCall = defaultBlocksBeforeSystemCall,
    Random? random,
  })  : _blocksBeforeSystemCall = blocksBeforeSystemCall,
        _rounds = chaChaRounds,
        _random = random ?? Random.secure() {
    // Don't allow round value lower than 4.
    if (chaChaRounds < 4) {
      throw ArgumentError.value(chaChaRounds, 'rounds');
    }
  }

  @override
  bool nextBool() => _random.nextBool();

  @override
  double nextDouble() => _random.nextDouble();

  @override
  int nextInt(int max) {
    if (max > (1 << 32)) {
      return _random.nextInt(max);
    }
    final state = _state;
    final index = _nextIndex;
    _nextIndex = index + 1;
    final indexInState = index % state.length;
    if (index == 0 || index >= _blockLength * _blocksBeforeSystemCall) {
      _nextIndex = 1;

      // XOR state block with a block from Random.secure.
      final random = _random;
      for (var i = 0; i < state.length; i++) {
        state[i] ^= random.nextInt(_bit32);
      }

      // XOR secret block with a block from Random.secure.
      final secret = _secret;
      for (var i = 0; i < secret.length; i++) {
        secret[i] ^= random.nextInt(_bit32);
      }
    } else if (indexInState == 0) {
      // XOR state block with the secret block.
      final secret = _secret;
      for (var i = 0; i < _blockLength; i++) {
        state[i] ^= secret[i];
      }

      // Apply ChaCha to the state block.
      _chaCha(state, _rounds);
    }
    return state[indexInState] % max;
  }

  static void _chaCha(Uint32List state, int rounds) {
    while (true) {
      // Round
      _quarterRound(state, 0, 4, 8, 12);
      _quarterRound(state, 1, 5, 9, 13);
      _quarterRound(state, 2, 6, 10, 14);
      _quarterRound(state, 3, 7, 11, 15);
      rounds--;
      if (rounds == 0) {
        break;
      }

      // Round
      _quarterRound(state, 0, 5, 10, 15);
      _quarterRound(state, 1, 6, 11, 12);
      _quarterRound(state, 2, 7, 8, 13);
      _quarterRound(state, 3, 4, 9, 14);
      rounds--;
      if (rounds == 0) {
        break;
      }
    }
  }

  /// ChaCha20 quarterRound function.
  static void _quarterRound(Uint32List state, int ai, int bi, int ci, int di) {
    var a = state[ai];
    var b = state[bi];
    var c = state[ci];
    var d = state[di];
    a = _mask32 & (a + b);
    d ^= a;
    d = (_mask32 & (d << 16)) ^ (d >> 16);
    c = _mask32 & (c + d);
    b ^= c;
    b = (_mask32 & (b << 12)) ^ (b >> 20);
    a = _mask32 & (a + b);
    d ^= a;
    d = (_mask32 & (d << 8)) ^ (d >> 24);
    c = _mask32 & (c + d);
    b ^= c;
    b = (_mask32 & (b << 7)) ^ (b >> 25);
    state[ai] = a;
    state[bi] = b;
    state[ci] = c;
    state[di] = d;
  }
}
