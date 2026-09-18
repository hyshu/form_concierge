package com.formconcierge.compose

/**
 * Reply timestamps and whether a newer reply remains unseen.
 */
public data class FormConciergeReplyStatus(
    /**
     * Whether the latest reply is newer than the stored seen time, or no seen time exists yet.
     */
    public val hasNewReplies: Boolean,
    /**
     * The time of the latest administrator reply, if one exists.
     */
    public val latestReplyAt: String?,
    /**
     * The latest reply time previously marked as seen, if available.
     */
    public val lastSeenReplyAt: String?,
)

/**
 * Checks for new administrator replies using host-provided seen state.
 */
public class FormConciergeReplyChecker(
    private val client: FormConciergeApi,
    private val anonymousToken: String,
    private val store: FormConciergeSessionStore,
    private val responseId: Int? = null,
) {
    /**
     * Compares the latest reply time with local seen state. Sets the client's anonymous
     * token before requesting replies.
     */
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

    /**
     * Fetches the latest reply time and marks it seen if a reply exists.
     */
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
