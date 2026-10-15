import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/features/math/presentation/counting_page.dart';

void main() {
  test(
    'counting accepts each object once and supports one more and one less',
    () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final sub = c.listen(countingProvider(5), (_, _) {});
      addTearDown(sub.close);
      final vm = c.read(countingProvider(5).notifier);
      vm.collect(0);
      vm.collect(0);
      vm.collect(-1);
      vm.collect(20);
      expect(c.read(countingProvider(5)).basket.length, 1);
      vm.add();
      expect(c.read(countingProvider(5)).basket.length, 2);
      vm.remove();
      expect(c.read(countingProvider(5)).basket.length, 1);
      vm.reset();
      expect(c.read(countingProvider(5)).basket, isEmpty);
    },
  );
  test('younger counting is bounded and has no arithmetic tools', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final sub = c.listen(countingProvider(2), (_, _) {});
    addTearDown(sub.close);
    expect(c.read(countingProvider(2)).available, 3);
    final vm = c.read(countingProvider(2).notifier);
    vm.add();
    expect(c.read(countingProvider(2)).basket, isEmpty);
    vm.collect(2);
    vm.remove();
    expect(c.read(countingProvider(2)).basket, {2});
  });
}
