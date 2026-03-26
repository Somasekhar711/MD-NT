package com.example.md_nt

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

object AlarmScheduler {
    const val EXTRA_ID = "alarm_id"
    const val EXTRA_MEDICINE_NAME = "alarm_medicine_name"
    const val EXTRA_TITLE = "alarm_title"
    const val EXTRA_BODY = "alarm_body"
    const val EXTRA_HOUR = "alarm_hour"
    const val EXTRA_MINUTE = "alarm_minute"
    const val EXTRA_REPEAT_DAILY = "alarm_repeat_daily"
    const val EXTRA_TRIGGER_AT = "alarm_trigger_at"

    fun scheduleDailyAlarm(
        context: Context,
        id: Int,
        medicineName: String,
        title: String,
        body: String,
        hour: Int,
        minute: Int,
    ) {
        val triggerAt = AlarmTimeUtils.nextTriggerAtMillis(hour, minute)
        scheduleAlarm(
            context = context,
            id = id,
            medicineName = medicineName,
            title = title,
            body = body,
            triggerAt = triggerAt,
            hour = hour,
            minute = minute,
            repeatDaily = true,
        )
    }

    fun scheduleOneTimeAlarm(
        context: Context,
        id: Int,
        medicineName: String,
        title: String,
        body: String,
        triggerAt: Long,
    ) {
        scheduleAlarm(
            context = context,
            id = id,
            medicineName = medicineName,
            title = title,
            body = body,
            triggerAt = triggerAt,
            hour = -1,
            minute = -1,
            repeatDaily = false,
        )
    }

    fun cancelAlarm(context: Context, id: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(buildPendingIntent(context, id, PendingIntent.FLAG_UPDATE_CURRENT))
    }

    private fun scheduleAlarm(
        context: Context,
        id: Int,
        medicineName: String,
        title: String,
        body: String,
        triggerAt: Long,
        hour: Int,
        minute: Int,
        repeatDaily: Boolean,
    ) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        val intent = Intent(context, AlarmReceiver::class.java).apply {
            putExtra(EXTRA_ID, id)
            putExtra(EXTRA_MEDICINE_NAME, medicineName)
            putExtra(EXTRA_TITLE, title)
            putExtra(EXTRA_BODY, body)
            putExtra(EXTRA_HOUR, hour)
            putExtra(EXTRA_MINUTE, minute)
            putExtra(EXTRA_REPEAT_DAILY, repeatDaily)
            putExtra(EXTRA_TRIGGER_AT, triggerAt)
        }

        val alarmIntent = PendingIntent.getBroadcast(
            context,
            id,
            intent,
            pendingIntentFlags(PendingIntent.FLAG_UPDATE_CURRENT),
        )

        val showIntent = PendingIntent.getActivity(
            context,
            id,
            Intent(context, MainActivity::class.java),
            pendingIntentFlags(PendingIntent.FLAG_UPDATE_CURRENT),
        )

        val alarmClockInfo = AlarmManager.AlarmClockInfo(triggerAt, showIntent)
        alarmManager.setAlarmClock(alarmClockInfo, alarmIntent)
    }

    fun buildPendingIntent(
        context: Context,
        id: Int,
        flags: Int,
    ): PendingIntent {
        val intent = Intent(context, AlarmReceiver::class.java)
        return PendingIntent.getBroadcast(
            context,
            id,
            intent,
            pendingIntentFlags(flags),
        )
    }

    private fun pendingIntentFlags(baseFlags: Int): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            baseFlags or PendingIntent.FLAG_IMMUTABLE
        } else {
            baseFlags
        }
    }
}
