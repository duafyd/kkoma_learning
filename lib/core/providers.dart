import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'storage/local_store.dart';

final storeProvider = Provider<LocalStore>(
  (ref) => throw StateError('저장소 초기화 필요'),
);
