import Flutter
import UIKit
import TinkoffASDKCore
import TinkoffASDKUI

protocol IDelegate {
    func setTinkoffCredentialSettings(arguments: NSDictionary?, result: @escaping FlutterResult)
    func handlePresentPaymentView(arguments: NSDictionary?, result: @escaping FlutterResult)
    func handlePresentApplePaymentView(arguments: NSDictionary?, result: @escaping FlutterResult)
}

public class SwiftFlutterTinkoffAcquiringPlugin: NSObject, FlutterPlugin {

    let delegate: IDelegate

    init(registrar: FlutterPluginRegistrar, viewController: UIViewController, channel: FlutterMethodChannel) {
        delegate = TinkoffPaymentDelegate(registrar: registrar, viewController: viewController, channel: channel)

    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_tinkoff_acquiring", binaryMessenger: registrar.messenger())
        let flutterViewController = UIApplication.shared.delegate?.window?!.rootViewController as! FlutterViewController
        let instance = SwiftFlutterTinkoffAcquiringPlugin(registrar: registrar, viewController: flutterViewController, channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? NSDictionary
        if (call.method == "setTinkoffCredentialSettings") {
            delegate.setTinkoffCredentialSettings(arguments: arguments, result: result)
        } else if (call.method == "presentPaymentView") {
            delegate.handlePresentPaymentView(arguments: arguments, result: result)
        } else if (call.method == "presentApplePaymentView") {
            delegate.handlePresentApplePaymentView(arguments: arguments, result: result)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
}

public class TinkoffPaymentDelegate : NSObject, IDelegate {
    
    var flutterResult: FlutterResult?
    var flutterRegistrar: FlutterPluginRegistrar
    var flutterViewController: UIViewController
    var isPresentingApplePay: Bool = false
    var tinkoffSDK: AcquiringUISDK?
    let channel: FlutterMethodChannel
    lazy var paymentApplePayConfiguration = AcquiringUISDK.ApplePayConfiguration()
    
    init(registrar: FlutterPluginRegistrar, viewController: UIViewController, channel: FlutterMethodChannel) {
        self.flutterRegistrar = registrar
        self.flutterViewController = viewController
        self.channel = channel
    }
    
    func setTinkoffCredentialSettings(arguments: NSDictionary?, result: @escaping FlutterResult) {
        guard let terminalKey = arguments?["terminalKey"] as? String else {return}
        guard let password = arguments?["password"] as? String else {return}
        guard let publicKey = arguments?["publicKey"] as? String else {return}
        let credentials = AcquiringSdkCredential(terminalKey: terminalKey, password: password, publicKey: publicKey)
        let production = arguments?["production"] as? Bool ?? false
        let server = production == true ? AcquiringSdkEnvironment.prod : AcquiringSdkEnvironment.test
        let sdkConfiguration = AcquiringSdkConfiguration(credential: credentials, server: server)
        sdkConfiguration.logger = AcquiringLoggerDefault()
        guard let sdk = try? AcquiringUISDK.init(configuration: sdkConfiguration) else { return }
        tinkoffSDK = sdk
    }
    
    func handlePresentPaymentView(arguments: NSDictionary?, result: @escaping FlutterResult) {
        guard let paymentDataArg = arguments?["paymentData"] as? NSDictionary else {return}
        guard let amount = paymentDataArg["amount"] as? Int, let orderId = paymentDataArg["orderId"] as? Int, let customerKey = paymentDataArg["customerId"] as? String, let receipt = paymentDataArg["receipt"] as? NSDictionary, let paymentFormData = paymentDataArg["paymentFormData"] else { return }
        
        var paymentData = PaymentInitData.init(amount: NSDecimalNumber.init(value: amount/100), orderId: Int64(orderId), customerKey: customerKey)
        paymentData.description = paymentDataArg["description"] as? String
        var receiptItems: [Item] = []
        guard let products = receipt["items"] as? NSArray else {
            return
        }
        products.forEach { (product) in
            if let product = product as? NSDictionary {
                guard let amount = product["amount"] as? Int, let price = product["price"] as? Int, let name = product["name"] as? String, let tax = product["tax"] as? String  else {
                    return
                }
                let item = Item.init(amount: NSDecimalNumber.init(value: amount/100), price: NSDecimalNumber.init(value: price/100), name: name, tax: Tax(rawValue: tax)
                )
                receiptItems.append(item)
            }
            
        }
//
        paymentData.receipt = Receipt.init(shopCode: nil,
                                           email: receipt["email"] as? String,
                                           taxation: Taxation(rawValue: receipt["taxation"] as! String),
                                           phone: receipt["phone"] as? String,
                                           items: receiptItems,
                                           agentData: nil,
                                           supplierInfo: nil,
                                           customer: customerKey,
                                           customerInn: nil)

        if let sdk = tinkoffSDK {
            let viewConfiguration = acquiringViewConfiguration(paymentData: paymentDataArg)
            sdk.presentPaymentView(on: self.flutterViewController,
                                   paymentData: paymentData,
                                   configuration: viewConfiguration) { (_ response: Result<PaymentStatusResponse, Error>) in
                                    var paymentResponse: [String : Any]
                                    switch response {
                                    case .success(let result):
                                        switch result.status {
                                        case .cancelled:
                                            paymentResponse = ["status": "canceled", "message" : result.errorMessage ?? "", "code": result.errorCode]
                                        case .completed:
                                            paymentResponse = ["status": "completed", "message" : "Покупка успешно завершена", "code": result.errorCode]
                                        default:
                                            paymentResponse = ["status": "failed", "message" : "Покупка не завершена", "code": result.errorCode]
                                        }
                                        
                                    case .failure(let error):
                                        paymentResponse = ["status": "failed", "message" : error.localizedDescription, "code": error.localizedDescription]
                                    }
                                    result(paymentResponse)
            }
        }
        
    }
    
    func handlePresentApplePaymentView(arguments: NSDictionary?, result: @escaping FlutterResult) {
            guard let paymentDataArg = arguments?["paymentData"] as? NSDictionary else {return}
            guard let amount = paymentDataArg["amount"] as? Int, let orderId = paymentDataArg["orderId"] as? Int, let customerKey = paymentDataArg["customerId"] as? String, let receipt = paymentDataArg["receipt"] as? NSDictionary, let paymentFormData = paymentDataArg["paymentFormData"] else { return }
            
            var paymentData = PaymentInitData.init(amount: NSDecimalNumber.init(value: amount/100), orderId: Int64(orderId), customerKey: customerKey)
            paymentData.description = paymentDataArg["description"] as? String
            var receiptItems: [Item] = []
            guard let products = receipt["items"] as? NSArray else {
                return
            }
            products.forEach { (product) in
                if let product = product as? NSDictionary {
                    guard let amount = product["amount"] as? Int, let price = product["price"] as? Int, let name = product["name"] as? String, let tax = product["tax"] as? String  else {
                        return
                    }
                    let item = Item.init(amount: NSDecimalNumber.init(value: amount/100), price: NSDecimalNumber.init(value: price/100), name: name, tax: Tax(rawValue: tax)
                    )
                    receiptItems.append(item)
                }
                
            }
    //
            paymentData.receipt = Receipt.init(shopCode: nil,
                                               email: receipt["email"] as? String,
                                               taxation: Taxation(rawValue: receipt["taxation"] as! String),
                                               phone: receipt["phone"] as? String,
                                               items: receiptItems,
                                               agentData: nil,
                                               supplierInfo: nil,
                                               customer: customerKey,
                                               customerInn: nil)

            if let sdk = tinkoffSDK {
                let viewConfiguration = acquiringViewConfiguration(paymentData: paymentDataArg)
    
                sdk.presentPaymentApplePay(on: self.flutterViewController, paymentData: paymentData, viewConfiguration: AcquiringViewConfiguration.init(), paymentConfiguration: paymentApplePayConfiguration) { (_ response: Result<PaymentStatusResponse, Error>) in
                    var paymentResponse: [String : Any]
                    switch response {
                    case .success(let result):
                        switch result.status {
                        case .cancelled:
                            paymentResponse = ["status": "canceled", "message" : result.errorMessage ?? "", "code": result.errorCode]
                        case .completed:
                            paymentResponse = ["status": "completed", "message" : "Покупка успешно завершена", "code": result.errorCode]
                        default:
                            paymentResponse = ["status": "failed", "message" : "Покупка не завершена", "code": result.errorCode]
                        }
                        
                    case .failure(let error):
                        paymentResponse = ["status": "failed", "message" : error.localizedDescription, "code": error.localizedDescription]
                    }
                    result(paymentResponse)
                }
            }
        }
    
    private func acquiringViewConfiguration(paymentData: NSDictionary) -> AcquiringViewConfiguration {
        let viewConfigration = AcquiringViewConfiguration.init()
        guard let amount = paymentData["amount"] as? Int, let receipt = paymentData["receipt"] as? NSDictionary, let description = paymentData["description"] as? String else { return viewConfigration }
        
        viewConfigration.fields = []
        // InfoFields.amount
        let title = NSAttributedString.init(string: "Оплата", attributes: [.font: UIFont.boldSystemFont(ofSize: 22)])
        let amountString = Utils.formatAmount(NSDecimalNumber.init(value: amount/100))
        let amountTitle = NSAttributedString.init(string: "на сумму \(amountString)", attributes: [.font : UIFont.systemFont(ofSize: 17)])
        // fields.append
        viewConfigration.fields.append(AcquiringViewConfiguration.InfoFields.amount(title: title, amount: amountTitle))
        
        // InfoFields.detail
        let productsDetatils = NSMutableAttributedString.init()
        productsDetatils.append(NSAttributedString.init(string: "\(description)\n", attributes: [.font : UIFont.systemFont(ofSize: 17)]))
        
        if let products = receipt["items"] as? NSArray {
            let productsDetails = products.map { (product) -> String in
                if let product = product as? NSDictionary {
                    return (product["name"] as? String)!
                } else {
                    return ""
                }
            }.joined(separator: ", ")
            
            productsDetatils.append(NSAttributedString.init(string: productsDetails, attributes: [.font : UIFont.systemFont(ofSize: 13), .foregroundColor: UIColor(red: 0.573, green: 0.6, blue: 0.635, alpha: 1)]))
            // fields.append
            viewConfigration.fields.append(AcquiringViewConfiguration.InfoFields.detail(title: productsDetatils))
        }
        
        viewConfigration.fields.append(AcquiringViewConfiguration.InfoFields.email(value: nil, placeholder: "Отправить квитанцию по адресу"))
        

        viewConfigration.viewTitle = "Оплата"
//        viewConfigration.localizableInfo = AcquiringViewConfiguration.LocalizableInfo.init(lang: AppSetting.shared.languageId)
        
        return viewConfigration
    }
}

class Utils {
    
    private static let amountFormatter = NumberFormatter()
    
    static func formatAmount(_ value: NSDecimalNumber, fractionDigits: Int = 2, currency: String = "₽") -> String {
        amountFormatter.usesGroupingSeparator = true
        amountFormatter.groupingSize = 3
        amountFormatter.groupingSeparator = " "
        amountFormatter.alwaysShowsDecimalSeparator = false
        amountFormatter.decimalSeparator = ","
        amountFormatter.minimumFractionDigits = 0
        amountFormatter.maximumFractionDigits = fractionDigits
        
        return "\(amountFormatter.string(from: value) ?? "\(value)") \(currency)"
    }

}
