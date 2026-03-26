package com.example.md_nt

import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity

class AlarmAlertActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setShowOverLockScreen()
        setContentView(R.layout.activity_alarm_alert)

        val alarmId = intent.getIntExtra(AlarmScheduler.EXTRA_ID, 0)
        val storedMedicineName = MedicineReminderStore.findMedicineNameByNotificationId(this, alarmId)
        val medicineName =
            intent.getStringExtra(AlarmScheduler.EXTRA_MEDICINE_NAME)?.takeIf { it.isNotBlank() }
                ?: storedMedicineName
                ?: intent.getStringExtra(AlarmScheduler.EXTRA_TITLE)
                ?: "Medicine"
        val body =
            intent.getStringExtra(AlarmScheduler.EXTRA_BODY)?.takeIf {
                it.isNotBlank() && it != "Time to take your medicine"
            }
                ?: "Time to take $medicineName"

        findViewById<TextView>(R.id.alarmTitle).text = medicineName
        findViewById<TextView>(R.id.alarmBody).text = body

        findViewById<Button>(R.id.dismissButton).setOnClickListener {
            AlarmRingService.dismiss(this)
            finish()
        }
        findViewById<Button>(R.id.snooze5Button).setOnClickListener {
            AlarmRingService.snooze(this, 5, medicineName, body)
            finish()
        }
        findViewById<Button>(R.id.snooze10Button).setOnClickListener {
            AlarmRingService.snooze(this, 10, medicineName, body)
            finish()
        }
        findViewById<Button>(R.id.snooze15Button).setOnClickListener {
            AlarmRingService.snooze(this, 15, medicineName, body)
            finish()
        }
    }

    override fun onBackPressed() {
        AlarmRingService.dismiss(this)
        super.onBackPressed()
    }

    private fun setShowOverLockScreen() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD,
            )
        }
    }
}
