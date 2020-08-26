import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_tinkoff_acquiring/flutter_tinkoff_acquiring.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _flutterTinkoffAcquiring = FlutterTinkoffAcquiring();

  @override
  void initState() {
    super.initState();
    _flutterTinkoffAcquiring.setTinkoffCredentialSettings(
        'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAqBiorLS9OrFPezixO5lSsF+HiZPFQWDO7x8gBJp4m86Wwz7ePNE8ZV4sUAZBqphdqSpXkybM4CJwxdj5R5q9+RHsb1dbMjThTXniwPpJdw4WKqG5/cLDrPGJY9NnPifBhA/MthASzoB+60+jCwkFmf8xEE9rZdoJUc2p9FL4wxKQPOuxCqL2iWOxAO8pxJBAxFojioVu422RWaQvoOMuZzhqUEpxA9T62lN8t3jj9QfHXaL4Ht8kRaa2JlaURtPJB5iBM+4pBDnqObNS5NFcXOxloZX4+M8zXaFh70jqWfiCzjyhaFg3rTPE2ClseOdS7DLwfB2kNP3K0GuPuLzsMwIDAQAB',
        'TestSDK',
        '5l9v23g7hlhqchyb');
    _flutterTinkoffAcquiring.onCancel = () {
      print("the payment form was cancelled");
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: RaisedButton(
            child: Text('TEST'),
            onPressed: () {
              final List<ReceiptItem> items = [
                ReceiptItem(1000, 1000, 1, 'Плюшки с сыром', TaxType.none)
              ];
              final Receipt receipt = Receipt('79641234567', '', items, TaxationType.usn_income);
              final paymentData =
                  PaymentData(1000, 1293894, 'jhasdkjh', 'тестовый платеж', {}, receipt);
              _flutterTinkoffAcquiring.presentPaymentView(paymentData).then((value) {
                print(value);
              });
            },
          ),
        ),
      ),
    );
  }
}
