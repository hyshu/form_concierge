/**
 * Generated bindings that remain optional for compatibility with existing deployments.
 */
type OptionalWorkerEnvBinding =
  | 'LEGACY_GEMINI_API_KEY'
  | 'LEGACY_OPENAI_API_KEY'
  | 'LEGACY_CLAUDE_API_KEY'
  | 'LEGACY_GROQ_API_KEY'
  | 'LEGACY_CEREBRAS_API_KEY'
  | 'LEGACY_SMTP_PASSWORD'
  | 'LEGACY_TURNSTILE_SITE_KEY'
  | 'LEGACY_TURNSTILE_SECRET_KEY'
  | 'PUBLIC_WRITE_RATE_LIMITER'
  | 'QUOTA_RESPONSES_PER_ACCOUNT_DAY'
  | 'QUOTA_RESPONSES_PER_IP_DAY'
  | 'QUOTA_RESPONSES_PER_SURVEY_DAY'
  | 'QUOTA_UPLOAD_BYTES_PER_ACCOUNT_DAY'
  | 'QUOTA_STORED_BYTES_PER_ACCOUNT'
  | 'QUOTA_AI_GENERATIONS_PER_ACCOUNT_DAY'
  | 'QUOTA_AI_GENERATIONS_PER_SURVEY_DAY'
  | 'QUOTA_EMAILS_PER_SURVEY_DAY';

/**
 * Generated Worker bindings with compatibility bindings and application-specific secrets.
 */
export type Env = Omit<WorkerEnv, OptionalWorkerEnvBinding> & {
  /**
   * The API token used to manage deployment secrets through Cloudflare's API.
   */
  CF_API_TOKEN: string;
  /**
   * An optional compatibility binding for the GEMINI API KEY secret.
   */
  LEGACY_GEMINI_API_KEY?: SecretsStoreSecret;
  /**
   * An optional compatibility binding for the OPENAI API KEY secret.
   */
  LEGACY_OPENAI_API_KEY?: SecretsStoreSecret;
  /**
   * An optional compatibility binding for the CLAUDE API KEY secret.
   */
  LEGACY_CLAUDE_API_KEY?: SecretsStoreSecret;
  /**
   * An optional compatibility binding for the GROQ API KEY secret.
   */
  LEGACY_GROQ_API_KEY?: SecretsStoreSecret;
  /**
   * An optional compatibility binding for the CEREBRAS API KEY secret.
   */
  LEGACY_CEREBRAS_API_KEY?: SecretsStoreSecret;
  /**
   * An optional compatibility binding for the SMTP PASSWORD secret.
   */
  LEGACY_SMTP_PASSWORD?: SecretsStoreSecret;
  /**
   * An optional compatibility binding for the TURNSTILE SITE KEY secret.
   */
  LEGACY_TURNSTILE_SITE_KEY?: SecretsStoreSecret;
  /**
   * An optional compatibility binding for the TURNSTILE SECRET KEY secret.
   */
  LEGACY_TURNSTILE_SECRET_KEY?: SecretsStoreSecret;
  /**
   * An optional Cloudflare rate limit binding for public write operations.
   */
  PUBLIC_WRITE_RATE_LIMITER?: RateLimit;
  /**
   * An optional positive integer override for responses per account day.
   */
  QUOTA_RESPONSES_PER_ACCOUNT_DAY?: string;
  /**
   * An optional positive integer override for responses per ip day.
   */
  QUOTA_RESPONSES_PER_IP_DAY?: string;
  /**
   * An optional positive integer override for responses per survey day.
   */
  QUOTA_RESPONSES_PER_SURVEY_DAY?: string;
  /**
   * An optional positive integer override for upload bytes per account day.
   */
  QUOTA_UPLOAD_BYTES_PER_ACCOUNT_DAY?: string;
  /**
   * An optional positive integer override for stored bytes per account.
   */
  QUOTA_STORED_BYTES_PER_ACCOUNT?: string;
  /**
   * An optional positive integer override for ai generations per account day.
   */
  QUOTA_AI_GENERATIONS_PER_ACCOUNT_DAY?: string;
  /**
   * An optional positive integer override for ai generations per survey day.
   */
  QUOTA_AI_GENERATIONS_PER_SURVEY_DAY?: string;
  /**
   * An optional positive integer override for emails per survey day.
   */
  QUOTA_EMAILS_PER_SURVEY_DAY?: string;
};

/**
 * The authenticated administrator identity and granted permission scopes.
 */
export type AdminContext = {
  /**
   * The identifier of this admin context.
   */
  id: string;
  /**
   * The administrator's email address, when available.
   */
  email: string;
  /**
   * Permission scopes granted to the administrator.
   */
  scopeNames: string[];
  /**
   * When the administrator account was created.
   */
  created: string;
};

/**
 * The authenticated anonymous respondent identity.
 */
export type AnonymousContext = {
  /**
   * The identifier of this anonymous context.
   */
  id: string;
  /**
   * The optional display name attached to the anonymous account.
   */
  displayName: string | null;
  /**
   * When this record was created.
   */
  createdAt: string;
  /**
   * When the anonymous account was last active.
   */
  lastSeenAt: string;
};

/**
 * A project record stored in the D1 database.
 */
export type ProjectRow = {
  /**
   * The identifier of this project.
   */
  id: number;
  /**
   * The URL-friendly name used to look up this resource.
   */
  slug: string;
  /**
   * The custom host name assigned to the project, if any.
   */
  custom_domain: string | null;
  /**
   * The locale used when the respondent's preferred language is unavailable.
   */
  default_locale: string;
  /**
   * Supported locale codes encoded as a JSON array.
   */
  supported_locales: string;
  /**
   * The project's display name.
   */
  name: string;
  /**
   * The identifier of the administrator who created this record.
   */
  created_by_admin_id: string | null;
  /**
   * When this record was created.
   */
  created_at: string;
  /**
   * When this record was last updated.
   */
  updated_at: string;
};

/**
 * A survey record stored in the D1 database.
 */
export type SurveyRow = {
  /**
   * The identifier of this survey.
   */
  id: number;
  /**
   * The identifier of the project containing the survey.
   */
  project_id: number;
  /**
   * The URL-friendly name used to look up this resource.
   */
  slug: string;
  /**
   * Survey titles encoded as a locale-to-text JSON object.
   */
  title_translations: string;
  /**
   * Survey descriptions encoded as a locale-to-text JSON object.
   */
  description_translations: string;
  /**
   * The survey's publication status.
   */
  status: string;
  /**
   * One when the survey is available on the public web and zero otherwise.
   */
  web_enabled: number;
  /**
   * One when adaptive follow-up is enabled and zero otherwise.
   */
  follow_up_enabled: number;
  /** Admin-authored AI follow-up generation instructions (nullable). */
  follow_up_prompt: string | null;
  /**
   * One when CAPTCHA is enabled for the survey and zero otherwise.
   */
  captcha_enabled: number;
  /**
   * The stored authentication requirement for survey submission.
   */
  auth_requirement: string;
  /**
   * The identifier of the administrator who created this record.
   */
  created_by_admin_id: string | null;
  /**
   * When this record was created.
   */
  created_at: string;
  /**
   * When this record was last updated.
   */
  updated_at: string;
  /**
   * When the survey begins accepting responses, if scheduled.
   */
  starts_at: string | null;
  /**
   * When the survey stops accepting responses, if scheduled.
   */
  ends_at: string | null;
};

/**
 * A question record stored in the D1 database.
 */
export type QuestionRow = {
  /**
   * The identifier of this question.
   */
  id: number;
  /**
   * The identifier of the associated survey.
   */
  survey_id: number;
  /**
   * Display text encoded as a locale-to-text JSON object.
   */
  text_translations: string;
  /**
   * The input format used to collect the answer.
   */
  type: string;
  /**
   * The position of this item in its ordered question or choice list.
   */
  order_index: number;
  /**
   * One when the respondent must answer this question and zero otherwise.
   */
  is_required: number;
  /**
   * Input hints encoded as a locale-to-text JSON object.
   */
  placeholder_translations: string;
  /**
   * The minimum accepted text length, or null when no minimum is set.
   */
  min_length: number | null;
  /**
   * The maximum accepted text length, or null when no maximum is set.
   */
  max_length: number | null;
  /**
   * The minimum number of choices or uploaded files required, if set.
   */
  min_selected: number | null;
  /**
   * The maximum number of choices or uploaded files allowed, if set.
   */
  max_selected: number | null;
  /**
   * Whether all visibility rules or any one rule must match.
   */
  visibility_condition_mode: string;
  /**
   * One when the question is marked as deleted and zero otherwise.
   */
  is_deleted: number;
};

/**
 * A choice record stored in the D1 database.
 */
export type ChoiceRow = {
  /**
   * The identifier of this choice.
   */
  id: number;
  /**
   * The identifier of the associated question.
   */
  question_id: number;
  /**
   * Display text encoded as a locale-to-text JSON object.
   */
  text_translations: string;
  /**
   * The position of this item in its ordered question or choice list.
   */
  order_index: number;
  /**
   * An optional application-defined value for this choice.
   */
  value: string | null;
};

/**
 * A survey response and its metadata as stored in D1.
 */
export type ResponseRow = {
  /**
   * The identifier of this response.
   */
  id: number;
  /**
   * The identifier of the associated survey.
   */
  survey_id: number;
  /**
   * The anonymous account that owns the response or reply.
   */
  anonymous_account_id: string;
  /**
   * An optional respondent identifier supplied by the host application.
   */
  anonymous_id: string | null;
  /**
   * When the survey response was submitted.
   */
  submitted_at: string;
  /**
   * The user agent reported by the client, when available.
   */
  user_agent: string | null;
  /**
   * An application-provided identifier for the device.
   */
  device_id: string | null;
  /**
   * A human-readable label.
   */
  device_label: string | null;
  /**
   * The platform on which the respondent is running the form.
   */
  device_platform: string | null;
  /**
   * The name of the operating system.
   */
  device_os: string | null;
  /**
   * The version of the operating system.
   */
  device_os_version: string | null;
  /**
   * The browser name, when available.
   */
  device_browser: string | null;
  /**
   * The browser version, when available.
   */
  device_browser_version: string | null;
  /**
   * The locale reported by the respondent's device.
   */
  device_locale: string | null;
  /**
   * The device's time zone identifier.
   */
  device_timezone: string | null;
  /**
   * The screen width reported by the host platform.
   */
  screen_width: number | null;
  /**
   * The screen height reported by the host platform.
   */
  screen_height: number | null;
  /**
   * The number of physical pixels per logical screen pixel.
   */
  device_pixel_ratio: number | null;
  /**
   * Additional device details encoded as JSON, when supplied.
   */
  device_info: string | null;
  /**
   * Application metadata encoded as JSON, when supplied.
   */
  metadata: string | null;
  /**
   * The follow-up interview encoded as JSON, when available.
   */
  follow_up: string | null;
  /**
   * The number of administrator replies attached to the response.
   */
  reply_count?: number;
};

/**
 * An answer record with serialized choice identifiers or uploaded file references.
 */
export type AnswerRow = {
  /**
   * The identifier of this answer.
   */
  id: number;
  /**
   * The identifier of the associated survey response.
   */
  survey_response_id: number;
  /**
   * The identifier of the associated question.
   */
  question_id: number;
  /**
   * The submitted text or encoded uploaded file references, when present.
   */
  text_value: string | null;
  /**
   * Selected choice identifiers encoded as a JSON array, when applicable.
   */
  selected_choice_ids: string | null;
};

/**
 * Unvalidated answer fields received in a submission request.
 */
export type AnswerInput = {
  /**
   * The identifier of the associated question.
   */
  questionId?: unknown;
  /**
   * The submitted text for a text question, when present.
   */
  textValue?: unknown;
  /**
   * The identifiers of the selected answer choices.
   */
  selectedChoiceIds?: unknown;
  /**
   * Storage keys for the uploaded files attached to the answer.
   */
  fileKeys?: unknown;
};

/**
 * An administrator reply record stored in D1.
 */
export type ReplyRow = {
  /**
   * The identifier of this reply.
   */
  id: number;
  /**
   * The identifier of the associated survey response.
   */
  survey_response_id: number;
  /**
   * The anonymous account that owns the response or reply.
   */
  anonymous_account_id: string;
  /**
   * The identifier of the administrator who wrote the reply, if available.
   */
  admin_id: string | null;
  /**
   * The reply text sent to the respondent.
   */
  body: string;
  /**
   * When this record was created.
   */
  created_at: string;
  /**
   * When the reply was marked as read, if available.
   */
  read_at: string | null;
};

/**
 * An administrator identity with serialized permission scopes.
 */
export type AdminRow = {
  /**
   * The identifier of this admin.
   */
  id: string;
  /**
   * The administrator's email address, when available.
   */
  email: string;
  /**
   * Permission scopes encoded as a JSON array.
   */
  scope_names: string;
  /**
   * When this record was created.
   */
  created_at: string;
};

/**
 * An anonymous respondent account stored in D1.
 */
export type AnonymousAccountRow = {
  /**
   * The identifier of this anonymous account.
   */
  id: string;
  /**
   * The optional display name attached to the anonymous account.
   */
  display_name: string | null;
  /**
   * When this record was created.
   */
  created_at: string;
  /**
   * When the anonymous account was last active.
   */
  last_seen_at: string;
};

/**
 * A survey's persisted email notification settings.
 */
export type NotificationSettingsRow = {
  /**
   * The identifier of this notification settings.
   */
  id: number;
  /**
   * The identifier of the associated survey.
   */
  survey_id: number;
  /**
   * One when response notifications are enabled and zero otherwise.
   */
  enabled: number;
  /**
   * The address that receives survey response notifications.
   */
  recipient_email: string;
  /**
   * When this record was last updated.
   */
  updated_at: string;
};

/**
 * Persisted integration configuration with secrets stored separately.
 */
export type IntegrationSettingsRow = {
  /**
   * The identifier of this integration settings.
   */
  id: number;
  /**
   * The AI provider to select after saving the settings.
   */
  ai_provider: string;
  /**
   * The host name of the SMTP server.
   */
  smtp_host: string | null;
  /**
   * The TCP port used to connect to the SMTP server.
   */
  smtp_port: number | null;
  /**
   * The username used for SMTP authentication, if required.
   */
  smtp_username: string | null;
  /**
   * The email address used as the message sender.
   */
  smtp_from_email: string | null;
  /**
   * The display name used for the message sender.
   */
  smtp_from_name: string | null;
  /**
   * The transport security used for the SMTP connection.
   */
  smtp_secure_mode: string;
  /**
   * When this record was last updated.
   */
  updated_at: string;
};

/**
 * A validated question definition with localized content and optional choices.
 */
export type QuestionInput = {
  /**
   * Display text indexed by locale code.
   */
  textTranslations: Record<string, string>;
  /**
   * The input format used to collect the answer.
   */
  type: string;
  /**
   * Whether the respondent must answer this question.
   */
  isRequired: boolean;
  /**
   * Input hints indexed by locale code.
   */
  placeholderTranslations: Record<string, string>;
  /**
   * The minimum accepted text length, or null when no minimum is set.
   */
  minLength: number | null;
  /**
   * The maximum accepted text length, or null when no maximum is set.
   */
  maxLength: number | null;
  /**
   * The minimum number of choices or uploaded files required, if set.
   */
  minSelected: number | null;
  /**
   * The maximum number of choices or uploaded files allowed, if set.
   */
  maxSelected: number | null;
  /**
   * Whether all visibility rules or any one rule must match.
   */
  visibilityConditionMode: string;
  /**
   * Localized text for each choice in display order.
   */
  choiceTranslations: Record<string, string>[];
};

/**
 * A persisted condition controlling a question's visibility.
 */
export type VisibilityRuleRow = {
  /**
   * The identifier of this visibility rule.
   */
  id: number;
  /**
   * The identifier of the associated survey.
   */
  survey_id: number;
  /**
   * The identifier of the question whose visibility is controlled.
   */
  target_question_id: number;
  /**
   * The identifier of the question whose answer is tested.
   */
  source_question_id: number;
  /**
   * The comparison applied to the source answer.
   */
  operator: string;
  /**
   * The JSON-encoded text or choice identifier used for comparison.
   */
  value_json: string | null;
  /**
   * When this record was created.
   */
  created_at: string;
  /**
   * When this record was last updated.
   */
  updated_at: string;
};

/**
 * Unvalidated visibility condition fields received in an update request.
 */
export type VisibilityRuleInput = {
  /**
   * The identifier of the question whose visibility is controlled.
   */
  targetQuestionId?: unknown;
  /**
   * The identifier of the question whose answer is tested.
   */
  sourceQuestionId?: unknown;
  /**
   * The comparison applied to the source answer.
   */
  operator?: unknown;
  /**
   * The unvalidated text or choice identifier to compare with the source answer.
   */
  value?: unknown;
};

/**
 * Validated device fields and their serialized representation for storage.
 */
export type NormalizedDeviceInfo = {
  /**
   * An application-provided identifier for the device.
   */
  deviceId: string | null;
  /**
   * A human-readable label.
   */
  label: string | null;
  /**
   * The platform on which the respondent is running the form.
   */
  platform: string | null;
  /**
   * The name of the operating system.
   */
  os: string | null;
  /**
   * The version of the operating system.
   */
  osVersion: string | null;
  /**
   * The browser name, when available.
   */
  browser: string | null;
  /**
   * The browser version, when available.
   */
  browserVersion: string | null;
  /**
   * The application's public version string.
   */
  appVersion: string | null;
  /**
   * The application's build identifier.
   */
  appBuild: string | null;
  /**
   * The hardware model reported by the device.
   */
  model: string | null;
  /**
   * The hardware manufacturer reported by the device.
   */
  manufacturer: string | null;
  /**
   * The locale reported by the respondent's device.
   */
  locale: string | null;
  /**
   * The device's time zone identifier.
   */
  timezone: string | null;
  /**
   * The screen width reported by the host platform.
   */
  screenWidth: number | null;
  /**
   * The screen height reported by the host platform.
   */
  screenHeight: number | null;
  /**
   * The number of physical pixels per logical screen pixel.
   */
  devicePixelRatio: number | null;
  /**
   * The serialized device details, or null when none were supplied.
   */
  rawJson: string | null;
};
