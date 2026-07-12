import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mobile_full/main.dart';

void main() {
  test('ExampleStrings localizes and interpolates values', () {
    const english = ExampleStrings(Locale('en'));
    const japanese = ExampleStrings(Locale('ja'));

    expect(english.text('title'), 'Flutter Mobile Full');
    expect(japanese.text('title'), 'モバイル全部入りサンプル');
    expect(english.format('last_response', {'id': 42}), 'Last response ID: 42');
  });
}
