package com.example.md_nt

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import org.json.JSONArray

class AlarmBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON" -> restoreMedicineReminders(context)
        }
    }

    private fun restoreMedicineReminders(context: Context) {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val savedReminders = prefs.getString("flutter.medicine_reminders_v3", null) ?: return

        runCatching {
            val reminders = JSONArray(savedReminders)
            for (i in 0 until reminders.length()) {
                val reminder = reminders.optJSONObject(i) ?: continue
                val medicineName = reminder.optString("name", "Medicine")
                val times = reminder.optJSONArray("times") ?: continue

                for (j in 0 until times.length()) {
                    val time = times.optJSONObject(j) ?: continue
                    val notificationId = time.optInt("notificationId", -1)
                    val hour = time.optInt("hour", -1)
                    val minute = time.optInt("minute", -1)

                    if (notificationId < 0 || hour < 0 || minute < 0) {
                        continue
                    }

                    val displayHour = if (hour % 12 == 0) 12 else hour % 12
                    val displayMinute = minute.toString().padStart(2, '0')
                    val meridiem = if (hour >= 12) "PM" else "AM"

                    AlarmScheduler.scheduleDailyAlarm(
                        context = context,
                        id = notificationId,
                        medicineName = medicineName,
                        title = medicineName,
                        body = "Time to take $medicineName at $displayHour:$displayMinute $meridiem",
                        hour = hour,
                        minute = minute,
                    )
                }
            }
        }
    }
}
