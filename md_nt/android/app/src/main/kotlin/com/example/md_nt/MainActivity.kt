package com.example.md_nt

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val alarmChannel = "md_nt/alarm"
    private val notificationPermissionRequestCode = 4101

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestNotificationPermissionIfNeeded()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, alarmChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scheduleDailyAlarm" -> {
                        val id = call.argument<Int>("id")
                        val medicineName = call.argument<String>("medicineName")
                        val title = call.argument<String>("title")
                        val body = call.argument<String>("body")
                        val hour = call.argument<Int>("hour")
                        val minute = call.argument<Int>("minute")

                        if (id == null || medicineName == null || title == null || body == null || hour == null || minute == null) {
                            result.error("INVALID_ARGS", "Missing alarm arguments", null)
                            return@setMethodCallHandler
                        }

                        AlarmScheduler.scheduleDailyAlarm(applicationContext, id, medicineName, title, body, hour, minute)
                        result.success(null)
                    }
                    "scheduleOneTimeAlarm" -> {
                        val id = call.argument<Int>("id")
                        val medicineName = call.argument<String>("medicineName")
                        val title = call.argument<String>("title")
                        val body = call.argument<String>("body")
                        val timestamp = call.argument<Long>("timestamp")

                        if (id == null || medicineName == null || title == null || body == null || timestamp == null) {
                            result.error("INVALID_ARGS", "Missing one-time alarm arguments", null)
                            return@setMethodCallHandler
                        }

                        AlarmScheduler.scheduleOneTimeAlarm(applicationContext, id, medicineName, title, body, timestamp)
                        result.success(null)
                    }
                    "cancelAlarm" -> {
                        val id = call.argument<Int>("id")
                        if (id == null) {
                            result.error("INVALID_ARGS", "Missing alarm id", null)
                            return@setMethodCallHandler
                        }

                        AlarmScheduler.cancelAlarm(applicationContext, id)
                        result.success(null)
                    }
                    "cancelManyAlarms" -> {
                        val ids = call.argument<List<Int>>("ids") ?: emptyList()
                        ids.forEach { AlarmScheduler.cancelAlarm(applicationContext, it) }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun requestNotificationPermissionIfNeeded() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return
        }

        val permissionState = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.POST_NOTIFICATIONS,
        )

        if (permissionState == PackageManager.PERMISSION_GRANTED) {
            return
        }

        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            notificationPermissionRequestCode,
        )
    }
}
