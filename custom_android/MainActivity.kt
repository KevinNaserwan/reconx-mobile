package com.reconx.agent.reconx_mobile

import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val METHOD_CHANNEL = "com.reconx.agent/methods"
    private val EVENT_CHANNEL = "com.reconx.agent/events"

    private var eventSink: EventChannel.EventSink? = null

    override fun onResume() {
        super.onResume()
        tryRebindListener()
    }

    private fun tryRebindListener() {
        try {
            val componentName = ComponentName(this, ReconXNotificationListener::class.java)
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
                ReconXNotificationListener.requestRebind(componentName)
            }
        } catch (e: Exception) {
            try {
                val componentName = ComponentName(this, ReconXNotificationListener::class.java)
                val pm = packageManager
                pm.setComponentEnabledSetting(componentName, PackageManager.COMPONENT_ENABLED_STATE_DISABLED, PackageManager.DONT_KILL_APP)
                pm.setComponentEnabledSetting(componentName, PackageManager.COMPONENT_ENABLED_STATE_ENABLED, PackageManager.DONT_KILL_APP)
            } catch (e2: Exception) {}
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Ensure notification listener binder is bound
        tryRebindListener()

        // MethodChannel: Check, request Notification Access, and sync active notifications
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isPermissionGranted" -> {
                    val enabledListeners = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
                    val isGranted = enabledListeners != null && enabledListeners.contains(packageName)
                    result.success(isGranted)
                }
                "openNotificationSettings" -> {
                    val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                    startActivity(intent)
                    result.success(true)
                }
                "syncActiveNotifications" -> {
                    if (ReconXNotificationListener.instance == null) {
                        tryRebindListener()
                    }
                    val count = ReconXNotificationListener.instance?.syncActiveNotifications() ?: 0
                    result.success(count)
                }
                "rebindListenerService" -> {
                    tryRebindListener()
                    val count = ReconXNotificationListener.instance?.syncActiveNotifications() ?: 0
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // EventChannel: Stream notifications into Flutter
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    ReconXNotificationListener.notificationCallback = { payload ->
                        runOnUiThread {
                            eventSink?.success(payload)
                        }
                    }
                    // Proactively scan active tray notifications when listener channel opens
                    ReconXNotificationListener.instance?.syncActiveNotifications()
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    ReconXNotificationListener.notificationCallback = null
                }
            }
        )
    }
}
