package com.edgepulse.scanner

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.lang.reflect.Proxy

/**
 * Bridges Flutter (Dart) to the native Go scanning engine (edgepulse_core.aar).
 * Uses safe class-loading so the app compiles and falls back cleanly to Dart if
 * edgepulse_core.aar has not yet been compiled with gomobile bind.
 */
class MainActivity : FlutterActivity(), EventChannel.StreamHandler {
    private val methodChannelName = "com.edgepulse.scanner/methods"
    private val eventChannelName = "com.edgepulse.scanner/events"
    private val mainHandler = Handler(Looper.getMainLooper())

    private var eventSink: EventChannel.EventSink? = null
    private var goEngine: Any? = null
    private var goCallbackInterface: Class<*>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        initGoEngine()

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName)
            .setStreamHandler(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName)
            .setMethodCallHandler { call, result ->
                handleMethodCall(call, result)
            }
    }

    private fun initGoEngine() {
        try {
            val pkgClass = Class.forName("edgepulse.Edgepulse")
            val newEngineMethod = pkgClass.getMethod("newEngine")
            goEngine = newEngineMethod.invoke(null)
            goCallbackInterface = Class.forName("edgepulse.MobileCallback")
        } catch (_: Throwable) {
            goEngine = null
            goCallbackInterface = null
        }
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getEngineInfo" -> {
                val engine = goEngine
                if (engine != null) {
                    val version = try {
                        engine.javaClass.getMethod("version").invoke(engine) as? String ?: "GoCore"
                    } catch (_: Throwable) {
                        "GoCore"
                    }
                    result.success(mapOf("available" to true, "version" to version))
                } else {
                    result.success(mapOf("available" to false, "version" to "DartFallback"))
                }
            }

            "startScan" -> {
                val engine = goEngine
                val cbIface = goCallbackInterface
                if (engine == null || cbIface == null) {
                    result.error("NO_GO_AAR", "Native Go AAR not loaded", null)
                    return
                }
                val targetsJson = call.argument<String>("targetsJson") ?: "[]"
                val configJson = call.argument<String>("configJson") ?: "{}"

                try {
                    val proxyCb = Proxy.newProxyInstance(
                        cbIface.classLoader,
                        arrayOf(cbIface)
                    ) { _, method, args ->
                        val payload = args?.firstOrNull()?.toString() ?: ""
                        val eventType = when (method.name) {
                            "onProgress" -> "progress"
                            "onResult" -> "result"
                            "onComplete" -> "complete"
                            "onError" -> "error"
                            else -> null
                        }
                        if (eventType != null) {
                            mainHandler.post {
                                eventSink?.success(mapOf("type" to eventType, "data" to payload))
                            }
                        }
                        null
                    }

                    val startMethod = engine.javaClass.getMethod(
                        "startScan",
                        String::class.java,
                        String::class.java,
                        cbIface
                    )
                    startMethod.invoke(engine, targetsJson, configJson, proxyCb)
                    result.success(true)
                } catch (e: Throwable) {
                    result.error("START_FAILED", e.cause?.message ?: e.message, null)
                }
            }

            "pauseScan" -> {
                invokeNoArg("pauseScan")
                result.success(true)
            }

            "resumeScan" -> {
                invokeNoArg("resumeScan")
                result.success(true)
            }

            "stopScan" -> {
                invokeNoArg("stopScan")
                result.success(true)
            }

            "parseTargets" -> {
                val engine = goEngine
                if (engine == null) {
                    result.error("NO_GO_AAR", "Native Go AAR not loaded", null)
                    return
                }
                val raw = call.argument<String>("raw") ?: ""
                val country = call.argument<String>("country") ?: "XX"
                val port = call.argument<Int>("port") ?: 443
                val maxPerCidr = call.argument<Int>("maxPerCidr") ?: 256
                try {
                    val pkgClass = Class.forName("edgepulse.Edgepulse")
                    val parseMethod = pkgClass.getMethod(
                        "parseTargets",
                        String::class.java,
                        String::class.java,
                        Long::class.javaPrimitiveType,
                        Long::class.javaPrimitiveType
                    )
                    val parsed = parseMethod.invoke(
                        null,
                        raw,
                        country,
                        port.toLong(),
                        maxPerCidr.toLong()
                    ) as? String ?: "[]"
                    result.success(parsed)
                } catch (e: Throwable) {
                    result.error("PARSE_FAILED", e.cause?.message ?: e.message, null)
                }
            }

            else -> result.notImplemented()
        }
    }

    private fun invokeNoArg(name: String) {
        val engine = goEngine ?: return
        try {
            engine.javaClass.getMethod(name).invoke(engine)
        } catch (_: Throwable) {
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
}
