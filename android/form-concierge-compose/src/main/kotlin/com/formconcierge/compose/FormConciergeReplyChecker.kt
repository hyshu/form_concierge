package com.formconcierge.compose

public data class FormConciergeReplyStatus(
    public val hasNewReplies: Boolean,
    public val latestReplyAt: String?,
    public val lastSeenReplyAt: String?,
)

public class FormConciergeReplyChecker(
    private val client: FormConciergeApi,
    private val anonymousToken: String,
    private val store: FormConciergeSessionStore,
    private val responseId: Int? = null,
) {
    public suspend fun check(): FormConciergeReplyStatus {
        client.setAnonymousToken(anonymousToken)
        val latest = client.latestReplyAt(responseId)
        val seen = store.readLastSeenReplyAt(responseId)
        return FormConciergeReplyStatus(
            hasNewReplies = latest != null && isAfter(latest, seen),
            latestReplyAt = latest,
            lastSeenReplyAt = seen,
        )
    }

    public suspend fun markLatestSeen() {
        val latest = check().latestReplyAt ?: return
        store.writeLastSeenReplyAt(responseId, latest)
    }

    private fun isAfter(
        candidate: String,
        reference: String?,
    ): Boolean {
        if (reference == null) return true
        val candidateMillis = parseApiTimestamp(candidate)
        val referenceMillis = parseApiTimestamp(reference)
        return if (candidateMillis != null && referenceMillis != null) {
            candidateMillis > referenceMillis
        } else {
            candidate > reference
        }
    }
}
