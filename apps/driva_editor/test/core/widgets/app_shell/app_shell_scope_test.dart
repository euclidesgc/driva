import 'package:driva_editor/core/widgets/app_shell/app_shell_scope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppShellController.immersive', () {
    test('começa false', () {
      final controller = AppShellController();
      expect(controller.immersive, isFalse);
    });

    test('setImmersive muda o sinal quando o token é o dono', () {
      final token = Object();
      final controller = AppShellController()
        ..publish(token, crumbs: const [], actions: const [])
        ..setImmersive(token, value: true);

      expect(controller.immersive, isTrue);
    });

    test('setImmersive de um token que não é dono é ignorado', () {
      final owner = Object();
      final intruder = Object();
      final controller = AppShellController()
        ..publish(owner, crumbs: const [], actions: const [])
        ..setImmersive(intruder, value: true);

      expect(controller.immersive, isFalse);
    });

    test('clear do dono devolve immersive a false', () {
      final token = Object();
      final controller = AppShellController()
        ..publish(token, crumbs: const [], actions: const [])
        ..setImmersive(token, value: true)
        ..clear(token);

      expect(controller.immersive, isFalse);
    });

    test('clear de quem não é dono não mexe em immersive', () {
      final owner = Object();
      final intruder = Object();
      final controller = AppShellController()
        ..publish(owner, crumbs: const [], actions: const [])
        ..setImmersive(owner, value: true)
        ..clear(intruder);

      expect(controller.immersive, isTrue);
    });

    test('publish de um novo dono reseta immersive do dono anterior', () {
      final first = Object();
      final second = Object();
      final controller = AppShellController()
        ..publish(first, crumbs: const [], actions: const [])
        ..setImmersive(first, value: true)
        ..publish(second, crumbs: const [], actions: const []);

      expect(controller.immersive, isFalse);
    });

    test('republicar com o mesmo dono preserva immersive', () {
      final token = Object();
      final controller = AppShellController()
        ..publish(token, crumbs: const [], actions: const [])
        ..setImmersive(token, value: true)
        ..publish(token, crumbs: const [], actions: const []);

      expect(controller.immersive, isTrue);
    });
  });
}
