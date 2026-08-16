@file:Suppress("ktlint:standard:function-naming")

package com.formconcierge.compose

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.MailOutline
import androidx.compose.material3.Badge
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import kotlinx.serialization.json.JsonElement
import java.text.DateFormat
import java.util.Date
import java.util.Locale

public data class FormConciergeInquiryConfig(
    public val baseUrl: String,
    public val projectSlug: String,
    public val surveySlug: String? = null,
    public val surveyId: Int? = null,
    public val locale: String? = null,
    public val deviceInfo: DeviceInfo? = null,
    public val metadata: Map<String, JsonElement> = emptyMap(),
    public val captchaTokenProvider: (suspend () -> String?)? = null,
    public val processImage: ProcessSurveyImage? = null,
) {
    internal fun surveyConfig(): FormConciergeSurveyConfig =
        FormConciergeSurveyConfig(
            projectSlug = projectSlug,
            surveySlug = surveySlug,
            surveyId = surveyId,
            locale = locale,
            deviceInfo = deviceInfo,
            metadata = metadata,
            captchaTokenProvider = captchaTokenProvider,
            processImage = processImage,
        )
}

@Composable
public fun FormConciergeInquiryFlow(
    config: FormConciergeInquiryConfig,
    store: FormConciergeSessionStore,
    modifier: Modifier = Modifier,
    onClose: () -> Unit,
    onInquirySubmitted: (InquiryRecord) -> Unit = {},
) {
    val client = remember(config.baseUrl) { FormConciergeClient(config.baseUrl) }
    FormConciergeInquiryFlow(
        config = config,
        client = client,
        store = store,
        modifier = modifier,
        onClose = onClose,
        onInquirySubmitted = onInquirySubmitted,
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
public fun FormConciergeInquiryFlow(
    config: FormConciergeInquiryConfig,
    client: FormConciergeApi,
    store: FormConciergeSessionStore,
    modifier: Modifier = Modifier,
    onClose: () -> Unit,
    onInquirySubmitted: (InquiryRecord) -> Unit = {},
) {
    val locale =
        normalizeFormContentLocale(
            config.locale ?: LocalConfiguration.current.locales[0].toLanguageTag(),
        )
    var destination by remember { mutableStateOf<InquiryDestination>(InquiryDestination.Hub) }
    var anonymousToken by remember { mutableStateOf<String?>(null) }
    var tokenLoaded by remember { mutableStateOf(false) }
    var hasNewReplies by remember { mutableStateOf(false) }

    LaunchedEffect(store) {
        anonymousToken = store.readAnonymousToken()
        anonymousToken?.let(client::setAnonymousToken)
        destination =
            if (store.readInquiries().isEmpty()) {
                InquiryDestination.Form
            } else {
                InquiryDestination.Hub
            }
        tokenLoaded = true
    }
    LaunchedEffect(anonymousToken, destination) {
        val token = anonymousToken
        if (token == null || destination != InquiryDestination.Hub) return@LaunchedEffect
        hasNewReplies =
            runCatching {
                store.readInquiries().any { inquiry ->
                    FormConciergeReplyChecker(
                        client,
                        token,
                        store,
                        inquiry.responseId,
                    ).check().hasNewReplies
                }
            }.getOrDefault(false)
    }

    fun navigateBack() {
        destination =
            when (destination) {
                is InquiryDestination.Detail -> {
                    InquiryDestination.History
                }

                InquiryDestination.Hub -> {
                    onClose()
                    InquiryDestination.Hub
                }

                InquiryDestination.Form,
                InquiryDestination.History,
                -> {
                    InquiryDestination.Hub
                }
            }
    }
    BackHandler { navigateBack() }

    Scaffold(
        modifier = modifier.fillMaxSize(),
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        when (destination) {
                            InquiryDestination.History -> FormConciergeStrings.text(locale, "inquiryList")
                            else -> FormConciergeStrings.text(locale, "contactUs")
                        },
                    )
                },
                navigationIcon = {
                    if (destination == InquiryDestination.Hub) {
                        IconButton(onClick = onClose) {
                            Icon(
                                Icons.Default.Close,
                                contentDescription = FormConciergeStrings.text(locale, "close"),
                            )
                        }
                    } else {
                        IconButton(onClick = ::navigateBack) {
                            Icon(
                                Icons.AutoMirrored.Filled.ArrowBack,
                                contentDescription = FormConciergeStrings.text(locale, "back"),
                            )
                        }
                    }
                },
            )
        },
    ) { innerPadding ->
        if (!tokenLoaded) {
            InquiryLoading(Modifier.padding(innerPadding), locale)
            return@Scaffold
        }
        when (val route = destination) {
            InquiryDestination.Hub -> {
                FormConciergeInquiryHub(
                    locale = locale,
                    hasNewReplies = hasNewReplies,
                    modifier = Modifier.padding(innerPadding),
                    onNewInquiry = { destination = InquiryDestination.Form },
                    onHistory = { destination = InquiryDestination.History },
                )
            }

            InquiryDestination.Form -> {
                FormConciergeSurvey(
                    client = client,
                    config = config.surveyConfig(),
                    anonymousToken = anonymousToken,
                    modifier = Modifier.padding(innerPadding),
                    onAnonymousSession = { session ->
                        store.writeAnonymousToken(session.token)
                        anonymousToken = session.token
                    },
                    onResponseSubmitted = { submission ->
                        val record = InquiryRecord.fromSubmission(submission)
                        store.addInquiry(record)
                        onInquirySubmitted(record)
                    },
                    onFollowUpSubmitted = { response ->
                        store.updateFollowUp(response.id, followUpItemsFromResponse(response))
                    },
                    onDone = { destination = InquiryDestination.Hub },
                )
            }

            InquiryDestination.History -> {
                FormConciergeInquiryList(
                    client = client,
                    store = store,
                    anonymousToken = anonymousToken,
                    locale = locale,
                    modifier = Modifier.padding(innerPadding),
                    onNewInquiry = { destination = InquiryDestination.Form },
                    onInquiry = { destination = InquiryDestination.Detail(it) },
                )
            }

            is InquiryDestination.Detail -> {
                FormConciergeInquiryDetail(
                    inquiry = route.inquiry,
                    client = client,
                    store = store,
                    anonymousToken = anonymousToken,
                    locale = locale,
                    modifier = Modifier.padding(innerPadding),
                    onRepliesObserved = { hasNewReplies = false },
                )
            }
        }
    }
}

@Composable
public fun FormConciergeInquiryHub(
    locale: String,
    hasNewReplies: Boolean,
    modifier: Modifier = Modifier,
    onNewInquiry: () -> Unit,
    onHistory: () -> Unit,
) {
    Column(
        modifier = modifier.fillMaxSize().padding(20.dp),
        verticalArrangement = Arrangement.Center,
    ) {
        InquiryHubCard(
            label = FormConciergeStrings.text(locale, "newInquiry"),
            icon = { Icon(Icons.AutoMirrored.Filled.Send, contentDescription = null) },
            onClick = onNewInquiry,
        )
        Spacer(Modifier.height(16.dp))
        InquiryHubCard(
            label = FormConciergeStrings.text(locale, "pastInquiries"),
            icon = { Icon(Icons.Default.History, contentDescription = null) },
            badge = hasNewReplies,
            onClick = onHistory,
        )
    }
}

@Composable
private fun InquiryHubCard(
    label: String,
    icon: @Composable () -> Unit,
    badge: Boolean = false,
    onClick: () -> Unit,
) {
    Card(
        modifier = Modifier.fillMaxWidth().height(88.dp).clickable(onClick = onClick),
    ) {
        Row(
            modifier = Modifier.fillMaxSize().padding(horizontal = 20.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            icon()
            Spacer(Modifier.width(16.dp))
            Text(label, style = MaterialTheme.typography.titleMedium, modifier = Modifier.weight(1f))
            if (badge) {
                Badge { Text("!") }
                Spacer(Modifier.width(8.dp))
            }
            Icon(Icons.Default.ChevronRight, contentDescription = null)
        }
    }
}

@Composable
public fun FormConciergeInquiryList(
    client: FormConciergeApi,
    store: FormConciergeSessionStore,
    anonymousToken: String?,
    locale: String,
    modifier: Modifier = Modifier,
    onNewInquiry: () -> Unit,
    onInquiry: (InquiryRecord) -> Unit,
) {
    var loading by remember { mutableStateOf(true) }
    var records by remember { mutableStateOf<List<InquiryRecord>>(emptyList()) }
    var newReplyResponseIds by remember { mutableStateOf<Set<Int>>(emptySet()) }
    var error by remember { mutableStateOf<String?>(null) }
    var reload by remember { mutableIntStateOf(0) }

    LaunchedEffect(store, anonymousToken, reload) {
        loading = true
        error = null
        runCatching {
            records = store.readInquiries()
            if (anonymousToken != null) {
                client.setAnonymousToken(anonymousToken)
                newReplyResponseIds =
                    records
                        .filter { inquiry ->
                            runCatching {
                                FormConciergeReplyChecker(
                                    client,
                                    anonymousToken,
                                    store,
                                    inquiry.responseId,
                                ).check().hasNewReplies
                            }.getOrDefault(false)
                        }.mapTo(mutableSetOf(), InquiryRecord::responseId)
            }
        }.onFailure { error = it.message }
        loading = false
    }

    when {
        loading -> {
            InquiryLoading(modifier, locale)
        }

        error != null -> {
            InquiryError(modifier, locale, error) { reload++ }
        }

        records.isEmpty() -> {
            InquiryEmpty(modifier, locale, onNewInquiry)
        }

        else -> {
            LazyColumn(
                modifier = modifier.fillMaxSize(),
                contentPadding = PaddingValues(bottom = 24.dp),
            ) {
                items(records, key = InquiryRecord::responseId) { record ->
                    Row(
                        modifier = Modifier.fillMaxWidth().clickable { onInquiry(record) }.padding(20.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                record.title.ifBlank { FormConciergeStrings.text(locale, "unknownDate") },
                                maxLines = 2,
                                overflow = TextOverflow.Ellipsis,
                                style = MaterialTheme.typography.bodyLarge,
                            )
                            Spacer(Modifier.height(5.dp))
                            Text(
                                formatInquiryDate(record.submittedAtEpochMillis, locale),
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                            )
                        }
                        if (record.responseId in newReplyResponseIds) {
                            Badge { Text(FormConciergeStrings.text(locale, "newReply")) }
                            Spacer(Modifier.width(8.dp))
                        }
                        Icon(Icons.Default.ChevronRight, contentDescription = null)
                    }
                    HorizontalDivider()
                }
                item {
                    Text(
                        FormConciergeStrings.text(locale, "retentionNote"),
                        modifier = Modifier.fillMaxWidth().padding(20.dp),
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        style = MaterialTheme.typography.bodySmall,
                    )
                }
            }
        }
    }
}

@Composable
public fun FormConciergeInquiryDetail(
    inquiry: InquiryRecord,
    client: FormConciergeApi,
    store: FormConciergeSessionStore,
    anonymousToken: String?,
    locale: String,
    modifier: Modifier = Modifier,
    onRepliesObserved: () -> Unit = {},
) {
    var loading by remember { mutableStateOf(true) }
    var replies by remember { mutableStateOf<List<AdminReply>>(emptyList()) }
    var error by remember { mutableStateOf<String?>(null) }
    var reload by remember { mutableIntStateOf(0) }

    LaunchedEffect(inquiry.responseId, anonymousToken, reload) {
        loading = true
        error = null
        runCatching {
            if (anonymousToken != null) {
                client.setAnonymousToken(anonymousToken)
                replies = client.replies(inquiry.responseId)
                if (replies.isNotEmpty()) store.markRepliesSeen(inquiry.responseId)
                FormConciergeReplyChecker(
                    client,
                    anonymousToken,
                    store,
                    inquiry.responseId,
                ).markLatestSeen()
                onRepliesObserved()
            }
        }.onFailure { error = it.message }
        loading = false
    }

    when {
        loading -> {
            InquiryLoading(modifier, locale)
        }

        error != null -> {
            InquiryError(modifier, locale, error) { reload++ }
        }

        else -> {
            LazyColumn(
                modifier = modifier.fillMaxSize(),
                contentPadding = PaddingValues(20.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                item {
                    Text(
                        formatInquiryDate(inquiry.submittedAtEpochMillis, locale),
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold,
                    )
                }
                items(inquiry.items) { item -> InquiryItemCard(item, locale) }
                if (inquiry.followUpItems.isNotEmpty()) {
                    item {
                        Text(
                            FormConciergeStrings.text(locale, "additionalQuestions"),
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold,
                        )
                    }
                    items(inquiry.followUpItems) { item -> InquiryItemCard(item, locale) }
                }
                item {
                    Text(
                        FormConciergeStrings.text(locale, "replyFromSupport"),
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold,
                    )
                }
                if (replies.isEmpty()) {
                    item {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Default.MailOutline, contentDescription = null)
                            Spacer(Modifier.width(10.dp))
                            Text(
                                FormConciergeStrings.text(locale, "noReplyYet"),
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                            )
                        }
                    }
                } else {
                    items(replies, key = AdminReply::id) { reply ->
                        Card(modifier = Modifier.fillMaxWidth()) {
                            Column(Modifier.padding(16.dp)) {
                                Text(
                                    formatApiDate(reply.createdAt, locale),
                                    style = MaterialTheme.typography.labelMedium,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                                )
                                Spacer(Modifier.height(8.dp))
                                Text(reply.body)
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun InquiryItemCard(
    item: InquiryContentItem,
    locale: String,
) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(
                item.question,
                style = MaterialTheme.typography.labelLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            item.answer?.let { Text(it) }
            if (item.hasImages) {
                Text(
                    FormConciergeStrings.text(locale, "attachedImages"),
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    style = MaterialTheme.typography.bodySmall,
                )
            }
        }
    }
}

@Composable
private fun InquiryLoading(
    modifier: Modifier,
    locale: String,
) {
    Column(
        modifier = modifier.fillMaxSize(),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        CircularProgressIndicator()
        Spacer(Modifier.height(12.dp))
        Text(FormConciergeStrings.text(locale, "loading"))
    }
}

@Composable
private fun InquiryError(
    modifier: Modifier,
    locale: String,
    error: String?,
    retry: () -> Unit,
) {
    Column(
        modifier = modifier.fillMaxSize().padding(24.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(error ?: FormConciergeStrings.text(locale, "tryAgainLater"))
        Spacer(Modifier.height(16.dp))
        Button(onClick = retry) { Text(FormConciergeStrings.text(locale, "retry")) }
    }
}

@Composable
private fun InquiryEmpty(
    modifier: Modifier,
    locale: String,
    onNewInquiry: () -> Unit,
) {
    Column(
        modifier = modifier.fillMaxSize().padding(24.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Icon(Icons.Default.History, contentDescription = null, modifier = Modifier.size(36.dp))
        Spacer(Modifier.height(12.dp))
        Text(FormConciergeStrings.text(locale, "noInquiriesYet"))
        Spacer(Modifier.height(18.dp))
        Button(onClick = onNewInquiry) {
            Text(FormConciergeStrings.text(locale, "startInquiry"))
        }
    }
}

private sealed interface InquiryDestination {
    data object Hub : InquiryDestination

    data object Form : InquiryDestination

    data object History : InquiryDestination

    data class Detail(
        val inquiry: InquiryRecord,
    ) : InquiryDestination
}

private fun formatInquiryDate(
    epochMillis: Long,
    locale: String,
): String =
    DateFormat
        .getDateTimeInstance(
            DateFormat.MEDIUM,
            DateFormat.SHORT,
            Locale.forLanguageTag(locale),
        ).format(Date(epochMillis))

private fun formatApiDate(
    timestamp: String,
    locale: String,
): String = parseApiTimestamp(timestamp)?.let { formatInquiryDate(it, locale) } ?: timestamp
