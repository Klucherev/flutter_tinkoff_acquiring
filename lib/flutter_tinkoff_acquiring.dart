import 'dart:async';

import 'package:flutter/services.dart';

class FlutterTinkoffAcquiring {
  static const MethodChannel _channel = const MethodChannel('flutter_tinkoff_acquiring');

  FlutterTinkoffAcquiring() {
    _setupOutputCallbacks();
  }

  ///Called when user cancels
  void Function() onCancel;

  //Listen for Errors
  Function(int errorCode, [String errorMessage]) onError;

  Future<void> setTinkoffCredentialSettings(String publicKey, String terminalKey, String password,
      [bool production = false]) async {
    assert(publicKey != null);
    assert(terminalKey != null);
    assert(password != null);
    final Map<String, Object> args = <String, dynamic>{
      "publicKey": publicKey,
      "terminalKey": terminalKey,
      "password": password,
      "production": production,
    };

    await _channel.invokeMethod('setTinkoffCredentialSettings', args);
  }

  ///Use to process immediate payments
  Future<PaymentResponse> presentPaymentView(
    PaymentData paymentData,
  ) async {
    assert(paymentData != null);
    final Map<String, Object> args = <String, dynamic>{
      "paymentData": paymentData.toJson(),
    };
    var response = await _channel.invokeMethod('presentPaymentView', args);
    var paymentResponse = PaymentResponse.fromJson(response);
    return paymentResponse;
  }

  Future<PaymentResponse> presentApplePaymentView(
    PaymentData paymentData,
  ) async {
    assert(paymentData != null);
    final Map<String, Object> args = <String, dynamic>{
      "paymentData": paymentData.toJson(),
    };
    var response = await _channel.invokeMethod('presentApplePaymentView', args);
    var paymentResponse = PaymentResponse.fromJson(response);
    return paymentResponse;
  }

  dispose() => _channel.setMethodCallHandler(null);

  /// Sets up the bridge to the native iOS and Android implementations.
  _setupOutputCallbacks() {
    Future<void> platformCallHandler(MethodCall call) async {
      // print('Output Callback: ${call.method}');
      switch (call.method) {
        case 'onCancel':
          onCancel?.call();
          break;
        case 'onError':
          final Map error = call.arguments;
          final int code = error['code'];
          final String message = error['message'];
          onError?.call(code, message);
          break;
        default:
          print('Unknown method ${call.method}');
      }
    }

    _channel.setMethodCallHandler(platformCallHandler);
  }
}

enum PaymentResponseStatus { succeeded, failed, canceled }

class PaymentData {
  final int amount;
  final int orderId;
  final String customerId;
  final String description;
  final Map<String, String> paymentFormData;
  final Receipt receipt;

  PaymentData(
    this.amount,
    this.orderId,
    this.customerId,
    this.description,
    this.paymentFormData,
    this.receipt,
  );

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'orderId': orderId,
      'customerId': customerId,
      'description': description,
      'paymentFormData': paymentFormData,
      'receipt': receipt.toJson(),
    };
  }
}

class Receipt {
  final String phone;
  final String email;
  final List<ReceiptItem> items;
  final TaxationType taxation;

  Receipt(
    this.phone,
    this.email,
    this.items,
    this.taxation,
  );

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'email': email,
      'taxation': taxation.toString().split('.').last,
      'items': items.map((e) => e.toJson()).toList()
    };
  }
}

class ReceiptItem {
  final int amount;
  final int price;
  final int quantity;
  final String name;
  final TaxType tax;

  ReceiptItem(
    this.amount,
    this.price,
    this.quantity,
    this.name,
    this.tax,
  );

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'price': price,
      'quantity': quantity,
      'name': name,
      'tax': tax.toString().split('.').last
    };
  }
}

class PaymentResponse {
  PaymentResponseStatus status;
  String errorMessage;

  PaymentResponse.fromJson(Map json) {
    this.errorMessage = json["message"] as String;
    this.status = _$enumDecodeNullable(_$PaymentResponseStatusEnumMap, json['status']);
  }

  T _$enumDecodeNullable<T>(Map<T, dynamic> enumValues, dynamic source) {
    if (source == null) {
      return null;
    }
    return _$enumDecode<T>(enumValues, source);
  }

  T _$enumDecode<T>(Map<T, dynamic> enumValues, dynamic source) {
    if (source == null) {
      throw ArgumentError('A value must be provided. Supported values: '
          '${enumValues.values.join(', ')}');
    }
    return enumValues.entries
        .singleWhere((e) => e.value == source,
            orElse: () => throw ArgumentError('`$source` is not one of the supported values: '
                '${enumValues.values.join(', ')}'))
        .key;
  }

  final _$PaymentResponseStatusEnumMap = <PaymentResponseStatus, dynamic>{
    PaymentResponseStatus.succeeded: 'succeeded',
    PaymentResponseStatus.failed: 'failed',
    PaymentResponseStatus.canceled: 'canceled'
  };
}

enum TaxationType { osn, usn_income, usn_income_outcome, envd, esn, patent }
enum TaxType {
  none,
  vat0,
  vat10,
  vat110,
  vat18,
  vat118,
  vat20,
  vat120,
}
