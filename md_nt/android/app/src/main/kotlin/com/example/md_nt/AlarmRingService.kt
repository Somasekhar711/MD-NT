package com.example.md_nt

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.media.ToneGenerator
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import androidx.core.app.NotificationCompat

class AlarmRingService : Service() {
    private val tag = "AlarmRingService"
    private var mediaPlayer: MediaPlayer? = null
    private var toneGenerator: ToneGenerator? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var audioManager: AudioManager? = null
    private var audioFocusRequest: AudioFocusRequest? = null
    private val audioFocusChangeListener = AudioManager.OnAudioFocusChangeListener { }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null) {
            stopSelf()
            return START_NOT_STICKY
        }

        val action = intent?.action
        return when (action) {
            ACTION_DISMISS -> {
                stopAlarm()
                START_NOT_STICKY
            }
            ACTION_SNOOZE_5 -> {
                snooze(intent, 5)
                START_NOT_STICKY
            }
            ACTION_SNOOZE_10 -> {
                snooze(intent, 10)
                START_NOT_STICKY
            }
            ACTION_SNOOZE_15 -> {
                snooze(intent, 15)
                START_NOT_STICKY
            }
            else -> {
                startAlarm(intent)
                START_NOT_STICKY
            }
        }
    }

    override fun onDestroy() {
        stopRingtone()
        releaseWakeLock()
        super.onDestroy()
    }

    private fun startAlarm(intent: Intent?) {
        val alarmId = intent?.getIntExtra(AlarmScheduler.EXTRA_ID, 0) ?: 0
        val storedMedicineName = MedicineReminderStore.findMedicineNameByNotificationId(this, alarmId)
        val medicineName =
            intent?.getStringExtra(AlarmScheduler.EXTRA_MEDICINE_NAME)?.takeIf { it.isNotBlank() }
                ?: storedMedicineName
                ?: "Medicine"
        val title = intent?.getStringExtra(AlarmScheduler.EXTRA_TITLE)?.takeIf { it.isNotBlank() }
            ?: medicineName
        val body = intent?.getStringExtra(AlarmScheduler.EXTRA_BODY)?.takeIf {
            it.isNotBlank() && it != "Time to take your medicine"
        }
            ?: "Time to take $medicineName"
        val notificationId = alarmId.takeIf { it > 0 } ?: DEFAULT_NOTIFICATION_ID

        createNotificationChannel()
        acquireWakeLock()
        startForeground(notificationId, buildNotification(alarmId, medicineName, body))
        playRingtone()
    }

    private fun snooze(intent: Intent?, minutes: Int) {
        val medicineName =
            intent?.getStringExtra(AlarmScheduler.EXTRA_MEDICINE_NAME)?.takeIf { it.isNotBlank() }
                ?: "Medicine"
        val title = intent?.getStringExtra(AlarmScheduler.EXTRA_TITLE)?.takeIf { it.isNotBlank() }
            ?: medicineName
        val body = intent?.getStringExtra(AlarmScheduler.EXTRA_BODY)?.takeIf { it.isNotBlank() }
            ?: "Time to take $medicineName"
        val notificationId = (System.currentTimeMillis() % 2000000000L).toInt()

        AlarmScheduler.scheduleOneTimeAlarm(
            context = applicationContext,
            id = notificationId,
            medicineName = medicineName,
            title = title,
            body = body,
            triggerAt = System.currentTimeMillis() + minutes * 60 * 1000L,
        )

        stopAlarm()
    }

    private fun stopAlarm() {
        stopRingtone()
        releaseWakeLock()
        abandonAudioFocus()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    private fun buildNotification(alarmId: Int, medicineName: String, body: String): Notification {
        val fullScreenIntent = Intent(this, AlarmAlertActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(AlarmScheduler.EXTRA_ID, alarmId)
            putExtra(AlarmScheduler.EXTRA_MEDICINE_NAME, medicineName)
            putExtra(AlarmScheduler.EXTRA_TITLE, medicineName)
            putExtra(AlarmScheduler.EXTRA_BODY, body)
        }

        val fullScreenPendingIntent = PendingIntent.getActivity(
            this,
            alarmId,
            fullScreenIntent,
            pendingIntentFlags(PendingIntent.FLAG_UPDATE_CURRENT),
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(medicineName)
            .setContentText(body)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .setContentIntent(fullScreenPendingIntent)
            .setFullScreenIntent(fullScreenPendingIntent, true)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Medicine Alarm",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Full-screen medicine alarm alerts"
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            setSound(
                null,
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .build(),
            )
        }

        manager.createNotificationChannel(channel)
    }

    private fun playRingtone() {
        if (mediaPlayer?.isPlaying == true) {
            return
        }

        if (!requestAudioFocus()) {
            return
        }

        val candidateUris = listOfNotNull(
            RingtoneManager.getActualDefaultRingtoneUri(this, RingtoneManager.TYPE_ALARM),
            RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM),
            Settings.System.DEFAULT_ALARM_ALERT_URI,
            RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE),
        )

        for (uri in candidateUris) {
            if (tryStartMediaPlayer(uri)) {
                return
            }
        }
        Log.e(tag, "Failed to start alarm audio via MediaPlayer URIs; using tone fallback")
        startToneFallback()
    }

    private fun tryStartMediaPlayer(uri: Uri): Boolean {
        return try {
            mediaPlayer?.release()
            mediaPlayer = MediaPlayer.create(this, uri)?.apply {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_ALARM)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .build(),
                    )
                } else {
                    @Suppress("DEPRECATION")
                    setAudioStreamType(AudioManager.STREAM_ALARM)
                }
                isLooping = true
                setVolume(1.0f, 1.0f)
                start()
            }

            val started = mediaPlayer?.isPlaying == true
            if (!started) {
                Log.w(tag, "MediaPlayer did not start for uri=$uri")
                mediaPlayer?.release()
                mediaPlayer = null
            }
            started
        } catch (e: Exception) {
            Log.e(tag, "MediaPlayer failed for uri=$uri", e)
            mediaPlayer?.release()
            mediaPlayer = null
            false
        }
    }

    private fun stopRingtone() {
        toneGenerator?.let {
            try {
                it.stopTone()
            } catch (_: Exception) {
            }
            it.release()
        }
        toneGenerator = null

        mediaPlayer?.let {
            try {
                if (it.isPlaying) {
                    it.stop()
                }
            } catch (_: Exception) {
            }
            it.release()
        }
        mediaPlayer = null
        abandonAudioFocus()
    }

    private fun startToneFallback() {
        try {
            toneGenerator?.release()
            toneGenerator = ToneGenerator(AudioManager.STREAM_ALARM, 100).apply {
                startTone(ToneGenerator.TONE_CDMA_ALERT_CALL_GUARD, 120_000)
            }
        } catch (e: Exception) {
            Log.e(tag, "Tone fallback failed", e)
        }
    }

    private fun requestAudioFocus(): Boolean {
        val manager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        audioManager = manager

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val request =
                AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE)
                    .setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_ALARM)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .build(),
                    )
                    .setOnAudioFocusChangeListener(audioFocusChangeListener)
                    .build()
            audioFocusRequest = request
            manager.requestAudioFocus(request) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        } else {
            @Suppress("DEPRECATION")
            manager.requestAudioFocus(
                audioFocusChangeListener,
                AudioManager.STREAM_ALARM,
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT,
            ) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        }
    }

    private fun abandonAudioFocus() {
        val manager = audioManager ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val request = audioFocusRequest ?: return
            manager.abandonAudioFocusRequest(request)
            audioFocusRequest = null
        } else {
            @Suppress("DEPRECATION")
            manager.abandonAudioFocus(audioFocusChangeListener)
        }
    }

    private fun acquireWakeLock() {
        if (wakeLock?.isHeld == true) {
            return
        }

        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "md_nt:medicine_alarm",
        ).apply {
            acquire(10 * 60 * 1000L)
        }
    }

    private fun releaseWakeLock() {
        wakeLock?.let {
            if (it.isHeld) {
                it.release()
            }
        }
        wakeLock = null
    }

    private fun pendingIntentFlags(baseFlags: Int): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            baseFlags or PendingIntent.FLAG_IMMUTABLE
        } else {
            baseFlags
        }
    }

    companion object {
        private const val CHANNEL_ID = "medicine_alarm_ring_channel"
        private const val DEFAULT_NOTIFICATION_ID = 8142

        const val ACTION_DISMISS = "com.example.md_nt.action.DISMISS_ALARM"
        const val ACTION_SNOOZE_5 = "com.example.md_nt.action.SNOOZE_5"
        const val ACTION_SNOOZE_10 = "com.example.md_nt.action.SNOOZE_10"
        const val ACTION_SNOOZE_15 = "com.example.md_nt.action.SNOOZE_15"

        fun start(context: Context, alarmIntent: Intent) {
            val serviceIntent = Intent(context, AlarmRingService::class.java).apply {
                putExtras(alarmIntent)
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        }

        fun dismiss(context: Context) {
            val intent = Intent(context, AlarmRingService::class.java).apply {
                action = ACTION_DISMISS
            }
            context.startService(intent)
        }

        fun snooze(context: Context, minutes: Int, title: String, body: String) {
            val action = when (minutes) {
                5 -> ACTION_SNOOZE_5
                10 -> ACTION_SNOOZE_10
                else -> ACTION_SNOOZE_15
            }

            val intent = Intent(context, AlarmRingService::class.java).apply {
                this.action = action
                putExtra(AlarmScheduler.EXTRA_MEDICINE_NAME, title)
                putExtra(AlarmScheduler.EXTRA_TITLE, title)
                putExtra(AlarmScheduler.EXTRA_BODY, body)
            }
            context.startService(intent)
        }
    }
}
