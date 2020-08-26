package ru.bizapp.flutter_tinkoff_acquiring

import android.app.Activity
import android.content.Intent
import android.util.Log
import androidx.annotation.NonNull
import androidx.fragment.app.FragmentActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import ru.tinkoff.acquiring.sdk.AcquiringSdk
import ru.tinkoff.acquiring.sdk.TinkoffAcquiring
import ru.tinkoff.acquiring.sdk.localization.AsdkSource
import ru.tinkoff.acquiring.sdk.localization.Language
import ru.tinkoff.acquiring.sdk.models.DarkThemeMode
import ru.tinkoff.acquiring.sdk.models.Item
import ru.tinkoff.acquiring.sdk.models.Receipt
import ru.tinkoff.acquiring.sdk.models.enums.CheckType
import ru.tinkoff.acquiring.sdk.models.enums.Tax
import ru.tinkoff.acquiring.sdk.models.enums.Taxation
import ru.tinkoff.acquiring.sdk.models.options.screen.PaymentOptions
import ru.tinkoff.acquiring.sdk.utils.Money


public class FlutterTinkoffAcquiringPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private lateinit var sdk: TinkoffAcquiring
    private var activityPluginBinding: ActivityPluginBinding? = null
    private var result: Result? = null

    /**
     * Use this constructor when adding this plugin to an app with v2 embedding.
     */
    constructor() {}

    private constructor(activity: Activity) {
        this.activity = activity;
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        this.result = result
        val activity = activityPluginBinding?.activity ?: return
        var arguments = call.arguments as? Map<String, Any>
        if (activity?.application == null) {
            val error = "Fail to resolve Application on registration"
            Log.e(call.method, error)
            result.error(call.method, error, Exception(error))
            return
        }
        if (activity !is FragmentActivity) {
            val error = "Got attached to activity which is not a FragmentActivity: $activity"
            result.error(call.method, error, Exception(error))
            return
        }
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "setTinkoffCredentialSettings" -> {
                var publicKey = arguments?.get("publicKey") as? String
                var terminalKey = arguments?.get("terminalKey") as? String
                var password = arguments?.get("password") as? String
                var production = arguments?.get("production") as? Boolean

                AcquiringSdk.isDeveloperMode = production != true // используется тестовый URL, деньги с карт не списываются
                AcquiringSdk.isDebug = production != true

                sdk = TinkoffAcquiring(terminalKey!!, password!!, publicKey!!)
                result.success(true)
            }
            "presentPaymentView" -> {
                var paymentData = arguments?.get("paymentData") as? Map<String, Any>
                var am = paymentData?.get("amount") as? Int
                var oId = paymentData?.get("orderId") as? Int
                var customerId = paymentData?.get("customerId") as? String
                var descr = paymentData?.get("description") as? String
                var receiptMap = paymentData?.get("receipt") as? Map<String, Any>
                var phone = receiptMap?.get("phone") as? String
                var tax = receiptMap?.get("taxation") as? String
                var items = receiptMap?.get("items") as? List<Map<String, Any>>

                var receiptItems = mutableListOf<Item>()

                for (i in items!!) {
                    var name = i["name"] as String
                    var price = i["price"] as Int
                    var quantity = i["quantity"] as Int
                    var amount = i["amount"] as Int
                    val tax = when (i["tax"] as String) {
                        "none" -> Tax.NONE
                        "vat0" -> Tax.VAT_0
                        "vat10" -> Tax.VAT_10
                        "vat110" -> Tax.VAT_110
                        "vat18" -> Tax.VAT_18
                        "vat118" -> Tax.VAT_118
                        "vat20" -> Tax.VAT_20
                        "vat120" -> Tax.VAT_120
                        else ->
                            Tax.NONE

                    }
                    var item = Item(name, price.toLong(), quantity.toDouble(), amount.toLong(), tax)
                    receiptItems.add(item)
                }
                var paymentDescr = receiptItems.map { x -> x.name }.joinToString(",")
                val taxation = when (tax) {
                    "osn" -> Taxation.OSN
                    "usn_income" -> Taxation.USN_INCOME
                    "esn" -> Taxation.ESN
                    "envd" -> Taxation.ENVD
                    "usn_income_outcome" -> Taxation.USN_INCOME_OUTCOME
                    "patent" -> Taxation.PATENT
                    else ->
                        Taxation.OSN

                }
                var sdkReceipt = Receipt(ArrayList(receiptItems), "", taxation)
                sdkReceipt.phone = phone

                var paymentOptions = PaymentOptions().setOptions {
                    orderOptions { // данные заказа
                        orderId = oId.toString()
                        amount = Money.ofCoins(am!!.toLong())
                        title = descr
                        description = paymentDescr
                        recurrentPayment = false
                        receipt = sdkReceipt
                    }
                    customerOptions { // данные покупателя
                        customerKey = customerId!!
                        checkType = CheckType.NO.toString()
                    }
                    featuresOptions { // настройки визуального отображения и функций экрана оплаты
                        useSecureKeyboard = true
                        localizationSource = AsdkSource(Language.RU)
                        handleCardListErrorInSdk = true
                        darkThemeMode = DarkThemeMode.AUTO
//                        theme = R.style.MyCustomTheme
                    }

                }
                sdk.openPaymentScreen(
                        activity as FragmentActivity, paymentOptions, 99)
            }

            else ->
                result.notImplemented()
        }
    }

    override fun onActivityResult(
            requestCode: Int,
            resultCode: Int,
            data: Intent?
    ): Boolean {
        // React to activity result and if request code == ResultActivity.REQUEST_CODE
        return when (resultCode) {
            Activity.RESULT_OK -> {
                var payId = "123"
                var paymentResponse = mapOf("status" to "succeeded", "paymentIntentId" to (payId ?: "") )
                result?.success(paymentResponse) // pass your result data
                true
            }
            else -> {
                var paymentResponse = mapOf("status" to "canceled" )
                result?.success(paymentResponse) // pass your result data
                false
            }
        }
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_tinkoff_acquiring")
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        channel.setMethodCallHandler(this)
        activityPluginBinding = binding
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityPluginBinding = binding
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
        channel.setMethodCallHandler(null)
        activityPluginBinding?.removeActivityResultListener(this)
        activityPluginBinding = null
    }

    companion object {
        @JvmStatic
        fun registerWith(registrar: PluginRegistry.Registrar) {
            val channel = MethodChannel(registrar.messenger(), "flutter_tinkoff_acquiring")
            val instance = FlutterTinkoffAcquiringPlugin()
            registrar.addActivityResultListener(instance);
            channel.setMethodCallHandler(FlutterTinkoffAcquiringPlugin(registrar.activity()))
        }
    }
}

