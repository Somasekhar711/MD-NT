package com.example.md_nt

import android.content.Context
import org.json.JSONArray

object MedicineReminderStore {
    fun findMedicineNameByNotificationId(context: Context, notificationId: Int): String? {
        if (notificationId <= 0) {
            return null
        }

        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val savedReminders = prefs.getString("flutter.medicine_reminders_v3", null) ?: return null

        return runCatching {
            val reminders = JSONArray(savedReminders)
            for (i in 0 until reminders.length()) {
                val reminder = reminders.optJSONObject(i) ?: continue
                val medicineName = reminder.optString("name", "").trim()
                if (medicineName.isBlank()) {
                    continue
                }

                val times = reminder.optJSONArray("times") ?: continue
                for (j in 0 until times.length()) {
                    val time = times.optJSONObject(j) ?: continue
                    if (time.optInt("notificationId", -1) == notificationId) {
                        return@runCatching medicineName
                    }
                }
            }

            null
        }.getOrNull()
    }
}
