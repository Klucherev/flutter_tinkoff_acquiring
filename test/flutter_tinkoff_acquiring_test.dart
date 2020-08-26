import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tinkoff_acquiring/flutter_tinkoff_acquiring.dart';

void main() {
  const MethodChannel channel = MethodChannel('flutter_tinkoff_acquiring');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await FlutterTinkoffAcquiring.platformVersion, '42');
  });
}
