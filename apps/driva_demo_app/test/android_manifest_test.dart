import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('manifest de main declara a permissão de internet', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml');
    expect(
      manifest.existsSync(),
      isTrue,
      reason: 'manifest não encontrado em ${manifest.absolute.path}',
    );

    final declarations = manifest.readAsStringSync().replaceAll(
      RegExp('<!--.*?-->', dotAll: true),
      '',
    );
    final permission = RegExp(
      r'<uses-permission\s+android:name="android\.permission\.INTERNET"\s*/>',
    ).firstMatch(declarations);

    expect(
      permission,
      isNotNull,
      reason:
          'o template do Flutter só injeta INTERNET nos manifests de debug e '
          'profile — sem a declaração aqui, todo build release sai sem rede',
    );
    expect(
      permission!.start,
      lessThan(declarations.indexOf('<application')),
      reason: 'a permissão é filha de <manifest>, não de <application>',
    );
  });
}
