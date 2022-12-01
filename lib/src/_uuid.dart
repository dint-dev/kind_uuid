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

export '_uuid_impl_vm.dart' if (dart.library.html) '_uuid_impl_js.dart';

/// Year 1582 epoch used by UUID timestamps.
final DateTime epoch1582 = DateTime.utc(1582, 10, 15);

/// Unix epoch
final DateTime epochUnix = DateTime.fromMillisecondsSinceEpoch(0);
