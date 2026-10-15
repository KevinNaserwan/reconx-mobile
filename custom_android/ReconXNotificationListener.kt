package com.reconx.agent.reconx_mobile

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

class ReconXNotificationListener : NotificationListenerService() {

    companion object {
        private const val TAG = "ReconXListener"
        var notificationCallback: ((Map<String, Any?>) -> Unit)? = null
        var instance: ReconXNotificationListener? = null
        val processedKeys = mutableSetOf<String>()

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

    override fun onListenerConnected() {
        super.onListenerConnected()
        instance = this
        Log.i(TAG, "ReconXNotificationListener connected successfully.")
        // Scan any pending notifications currently sitting in the status bar
        syncActiveNotifications()
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        instance = null
        Log.w(TAG, "ReconXNotificationListener disconnected.")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        processNotification(sbn)
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        super.onNotificationRemoved(sbn)
    }

    fun syncActiveNotifications(): Int {
        var count = 0
        try {
            val activeList = activeNotifications ?: return 0
            Log.d(TAG, "Scanning ${activeList.size} active notifications in tray...")
            for (sbn in activeList) {
                if (processNotification(sbn)) {
                    count++
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error scanning active notifications: $e")
        }
        return count
    }

    private fun processNotification(sbn: StatusBarNotification?): Boolean {
        if (sbn == null) return false

        val packageName = sbn.packageName?.lowercase() ?: return false
        val notification = sbn.notification ?: return false
        val extras = notification.extras ?: return false

        // Skip persistent ongoing notifications (e.g. background service status, keyboards, players)
        val flags = notification.flags
        if ((flags and Notification.FLAG_ONGOING_EVENT) != 0) {
            return false
        }

        // Deduplication Key: combination of packageName, notification ID, and postTime
        val notifKey = "${packageName}_${sbn.id}_${sbn.postTime}"
        if (processedKeys.contains(notifKey)) {
            // Already processed earlier; skip to guarantee ZERO duplicates
            return false
        }

        // 1. Thoroughly extract all possible text fields
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()?.trim() ?: ""
        val titleBig = extras.getCharSequence("android.title.big")?.toString()?.trim() ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()?.trim() ?: ""
        val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()?.trim() ?: ""
        val subText = extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString()?.trim() ?: ""
        val summaryText = extras.getCharSequence(Notification.EXTRA_SUMMARY_TEXT)?.toString()?.trim() ?: ""
        val infoText = extras.getCharSequence(Notification.EXTRA_INFO_TEXT)?.toString()?.trim() ?: ""
        val ticker = notification.tickerText?.toString()?.trim() ?: ""

        val textLines = extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)
        val joinedLines = textLines?.filterNotNull()?.joinToString(" ") { it.toString().trim() } ?: ""

        val effectiveTitle = if (titleBig.isNotEmpty()) titleBig else title

        // Combine all text segments so no details (e.g. amount or store) are discarded
        val contentPieces = mutableListOf<String>()
        if (text.isNotEmpty()) contentPieces.add(text)
        if (bigText.isNotEmpty() && bigText != text) contentPieces.add(bigText)
        if (joinedLines.isNotEmpty() && joinedLines != text && joinedLines != bigText) contentPieces.add(joinedLines)
        if (subText.isNotEmpty() && !text.contains(subText)) contentPieces.add(subText)
        if (summaryText.isNotEmpty() && summaryText != effectiveTitle) contentPieces.add(summaryText)
        if (infoText.isNotEmpty()) contentPieces.add(infoText)
        if (ticker.isNotEmpty() && !contentPieces.contains(ticker)) contentPieces.add(ticker)

        val effectiveContent = if (contentPieces.isNotEmpty()) {
            contentPieces.joinToString(" ")
        } else {
            effectiveTitle
        }

        val combinedSearch = "$effectiveTitle $effectiveContent $packageName".lowercase()

        // 2. Reject non-financial promotional noise, OTPs, and background services
        val isNonFinancialPromo = combinedSearch.contains("promo") ||
                                  combinedSearch.contains("voucher") ||
                                  combinedSearch.contains("diskon") ||
                                  combinedSearch.contains("cashback s/d") ||
                                  combinedSearch.contains("flash sale") ||
                                  combinedSearch.contains("klaim") ||
                                  combinedSearch.contains("keyboard aktif") ||
                                  combinedSearch.contains("berjalan di latar belakang") ||
                                  combinedSearch.contains("sesi berakhir") ||
                                  combinedSearch.contains("kode otp") ||
                                  combinedSearch.contains("jangan berikan kode") ||
                                  combinedSearch.contains("tips keamanan")
        if (isNonFinancialPromo) {
            return false
        }

        // 3. Target package recognition (both exact and substring matching for Indonesian financial apps)
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

        val hasMonetaryAmount = combinedSearch.contains("rp") ||
                                combinedSearch.contains("idr") ||
                                Regex("""\b\d{1,3}(?:[.,]\d{3})+\b""").containsMatchIn(combinedSearch)

        val hasTransactionAction = combinedSearch.contains("berhasil") ||
                                   combinedSearch.contains("sukses") ||
                                   combinedSearch.contains("qris") ||
                                   combinedSearch.contains("bayar") ||
                                   combinedSearch.contains("transfer") ||
                                   combinedSearch.contains("transaksi") ||
                                   combinedSearch.contains("pembayaran") ||
                                   combinedSearch.contains("debit") ||
                                   combinedSearch.contains("kredit") ||
                                   combinedSearch.contains("saldo") ||
                                   combinedSearch.contains("uang") ||
                                   combinedSearch.contains("top up") ||
                                   combinedSearch.contains("diterima") ||
                                   combinedSearch.contains("dikirim") ||
                                   combinedSearch.contains("keluar") ||
                                   combinedSearch.contains("masuk") ||
                                   combinedSearch.contains("payment")

        val isFinancial = (hasMonetaryAmount && hasTransactionAction) || 
                          (isTargetApp && hasMonetaryAmount) ||
                          (isTargetApp && (combinedSearch.contains("qris") || combinedSearch.contains("berhasil") || combinedSearch.contains("transfer")))

        if (isFinancial) {
            Log.i(TAG, "Financial Notification Processed! pkg=$packageName key=$notifKey title=$effectiveTitle content=$effectiveContent")

            val payload = mapOf(
                "packageName" to packageName,
                "title" to effectiveTitle,
                "content" to effectiveContent,
                "postTime" to sbn.postTime,
                "notificationKey" to notifKey
            )

            if (notificationCallback != null) {
                // Mark key as processed only when actually delivered to Flutter
                processedKeys.add(notifKey)
                if (processedKeys.size > 2000) {
                    val iterator = processedKeys.iterator()
                    for (i in 0 until 500) {
                        if (iterator.hasNext()) {
                            iterator.next()
                            iterator.remove()
                        }
                    }
                }
                notificationCallback?.invoke(payload)
                return true
            } else {
                Log.w(TAG, "Notification listener received data but Flutter callback is not yet set. Will re-sync on startup.")
                return false
            }
        }
        return false
    }
}
