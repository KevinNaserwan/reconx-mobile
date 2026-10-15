package com.reconx.agent.reconx_mobile

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

class ReconXNotificationListener : NotificationListenerService() {

    companion object {
        private const val TAG = "ReconXListener"
        var notificationCallback: ((Map<String, Any?>) -> Unit)? = null

        val TARGET_PACKAGES = setOf(
            "com.bcadigital.blu",
            "id.co.bcadigital.blu",
            "com.bca",
            "com.bca.mybca.omni.android",
            "id.co.bankmandiri.livin",
            "id.co.bri.brimo",
            "id.bni.wondr",
            "id.co.bni.newmobile",
            "com.searpm.bank",
            "id.superbank.app",
            "com.superbank.android",
            "com.shopee.id",
            "com.tokopedia.tkpd",
            "ovo.id",
            "id.dana",
            "com.gojek.app",
            "com.gojek.gopay",
            "com.btpn.dc",
            "com.bankjago.digital",
            "com.bnc.finance",
            "com.aladinbank.app",
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

        val packageName = sbn.packageName?.lowercase() ?: return
        val notification = sbn.notification ?: return
        val extras = notification.extras ?: return

        // 1. Thoroughly extract all possible text fields
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()?.trim() ?: ""
        val titleBig = extras.getCharSequence("android.title.big")?.toString()?.trim() ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()?.trim() ?: ""
        val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()?.trim() ?: ""
        val subText = extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString()?.trim() ?: ""
        val summaryText = extras.getCharSequence(Notification.EXTRA_SUMMARY_TEXT)?.toString()?.trim() ?: ""
        val infoText = extras.getCharSequence(Notification.EXTRA_INFO_TEXT)?.toString()?.trim() ?: ""

        val textLines = extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)
        val joinedLines = textLines?.filterNotNull()?.joinToString(" ") { it.toString().trim() } ?: ""

        val effectiveTitle = if (titleBig.isNotEmpty()) titleBig else title

        // Prioritize bigText if available, or build combined content
        val effectiveContent = when {
            bigText.isNotEmpty() -> bigText
            joinedLines.isNotEmpty() -> joinedLines
            text.isNotEmpty() && subText.isNotEmpty() -> "$text ($subText)"
            text.isNotEmpty() -> text
            summaryText.isNotEmpty() -> summaryText
            infoText.isNotEmpty() -> infoText
            else -> effectiveTitle
        }

        val combinedSearch = "$effectiveTitle $effectiveContent $packageName".lowercase()

        // 2. Target package recognition (both exact and substring matching for Indonesian financial apps)
        val isTargetApp = TARGET_PACKAGES.any { packageName.contains(it) } ||
                          packageName.contains("bcadigital") ||
                          packageName.contains("blu") ||
                          packageName.contains("bca") ||
                          packageName.contains("mandiri") ||
                          packageName.contains("livin") ||
                          packageName.contains("brimo") ||
                          packageName.contains("bri") ||
                          packageName.contains("bni") ||
                          packageName.contains("seabank") ||
                          packageName.contains("superbank") ||
                          packageName.contains("gopay") ||
                          packageName.contains("gojek") ||
                          packageName.contains("dana") ||
                          packageName.contains("ovo") ||
                          packageName.contains("shopee") ||
                          packageName.contains("jenius") ||
                          packageName.contains("jago")

        val hasFinancialKeywords = combinedSearch.contains("rp") ||
                                   combinedSearch.contains("idr") ||
                                   combinedSearch.contains("berhasil") ||
                                   combinedSearch.contains("sukses") ||
                                   combinedSearch.contains("qris") ||
                                   combinedSearch.contains("bayar") ||
                                   combinedSearch.contains("transfer") ||
                                   combinedSearch.contains("transaksi") ||
                                   combinedSearch.contains("pembayaran") ||
                                   combinedSearch.contains("debit") ||
                                   combinedSearch.contains("kredit")

        if (isTargetApp || hasFinancialKeywords) {
            Log.i(TAG, "Financial Notification Intercepted! pkg=$packageName title=$effectiveTitle content=$effectiveContent")

            val payload = mapOf(
                "packageName" to packageName,
                "title" to effectiveTitle,
                "content" to effectiveContent,
                "postTime" to sbn.postTime
            )

            // Stream directly into Flutter Dart runtime
            notificationCallback?.invoke(payload)
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        super.onNotificationRemoved(sbn)
    }
}
