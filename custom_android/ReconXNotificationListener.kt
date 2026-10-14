package com.reconx.agent.reconx_mobile

import android.app.Notification
import android.content.Intent
import android.os.Bundle
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

class ReconXNotificationListener : NotificationListenerService() {

    companion object {
        private const val TAG = "ReconXListener"
        var notificationCallback: ((Map<String, Any?>) -> Unit)? = null

        val TARGET_PACKAGES = setOf(
            "id.co.bcadigital.blu",
            "com.searpm.bank",
            "id.superbank.app",
            "com.shopee.id",
            "com.tokopedia.tkpd",
            "ovo.id",
            "id.dana",
            "com.bca",
            "com.bibit.id",
            "com.ajaib.android",
            "id.stockbit.android",
            "com.pluang.android",
            "com.bareksa.app"
        )
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        if (sbn == null) return

        val packageName = sbn.packageName ?: return
        val extras = sbn.notification.extras ?: return

        val title = extras.getString(Notification.EXTRA_TITLE) ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
        val subText = extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString() ?: ""

        val combinedContent = if (subText.isNotEmpty()) "$text ($subText)" else text

        // Filter: only capture financial/target apps or keywords
        val isTargetApp = TARGET_PACKAGES.contains(packageName)
        val hasFinancialKeywords = combinedContent.contains("Rp", ignoreCase = true) || 
                                   combinedContent.contains("IDR", ignoreCase = true) ||
                                   combinedContent.contains("berhasil", ignoreCase = true) ||
                                   combinedContent.contains("sukses", ignoreCase = true)

        if (isTargetApp || hasFinancialKeywords) {
            Log.d(TAG, "Financial Notification Intercepted from $packageName: $title -> $combinedContent")

            val payload = mapOf(
                "packageName" to packageName,
                "title" to title,
                "content" to combinedContent,
                "postTime" to sbn.postTime
            )

            // Notify Flutter runtime
            notificationCallback?.invoke(payload)
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        super.onNotificationRemoved(sbn)
    }
}
