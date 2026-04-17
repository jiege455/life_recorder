package com.jienetwork.life_recorder

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class ReminderForegroundService : Service() {
    companion object {
        const val CHANNEL_ID = "reminder_foreground_service"
        const val NOTIFICATION_ID = 2001
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)
        return START_STICKY // 被杀后自动重启
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "推送保活服务",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "保持推送服务运行，防止通知失效"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("AI人生记录器")
            .setContentText("推送服务运行中，每日 ${getReminderTime()} 提醒您")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()
    }

    private fun getReminderTime(): String {
        val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        val timeJson = prefs.getString("flutter.reminder_time", null)
        return if (timeJson != null) {
            try {
                val regex = """\"hour\":(\d+),\"minute\":(\d+)""".toRegex()
                val match = regex.find(timeJson)
                if (match != null) {
                    val hour = match.groupValues[1].toInt()
                    val minute = match.groupValues[2].toInt()
                    String.format("%02d:%02d", hour, minute)
                } else {
                    "20:00"
                }
            } catch (e: Exception) {
                "20:00"
            }
        } else {
            "20:00"
        }
    }
}
