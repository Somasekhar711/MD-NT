package com.example.md_nt

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra(AlarmScheduler.EXTRA_ID, 0)
        val storedMedicineName = MedicineReminderStore.findMedicineNameByNotificationId(context, id)
        val medicineName =
            intent.getStringExtra(AlarmScheduler.EXTRA_MEDICINE_NAME)?.takeIf { it.isNotBlank() }
                ?: storedMedicineName
                ?: "Medicine"
        val title =
            intent.getStringExtra(AlarmScheduler.EXTRA_TITLE)?.takeIf { it.isNotBlank() }
                ?: medicineName
        val body =
            intent.getStringExtra(AlarmScheduler.EXTRA_BODY)?.takeIf {
                it.isNotBlank() && it != "Time to take your medicine"
            } ?: "Time to take $medicineName"
        val repeatDaily = intent.getBooleanExtra(AlarmScheduler.EXTRA_REPEAT_DAILY, false)
        val hour = intent.getIntExtra(AlarmScheduler.EXTRA_HOUR, -1)
        val minute = intent.getIntExtra(AlarmScheduler.EXTRA_MINUTE, -1)

        if (repeatDaily && hour >= 0 && minute >= 0) {
            AlarmScheduler.scheduleDailyAlarm(context, id, medicineName, title, body, hour, minute)
        }

        AlarmRingService.start(
            context,
            Intent().apply {
                putExtra(AlarmScheduler.EXTRA_ID, id)
                putExtra(AlarmScheduler.EXTRA_MEDICINE_NAME, medicineName)
                putExtra(AlarmScheduler.EXTRA_TITLE, title)
                putExtra(AlarmScheduler.EXTRA_BODY, body)
            },
        )
    }
}
