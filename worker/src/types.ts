export type Env = WorkerEnv;

export type AdminContext = {
  id: string;
  email: string;
  scopeNames: string[];
  created: string;
};

export type AnonymousContext = {
  id: string;
  displayName: string | null;
  createdAt: string;
  lastSeenAt: string;
};

export type ProjectRow = {
  id: number;
  slug: string;
  custom_domain: string | null;
  default_locale: string;
  supported_locales: string;
  name: string;
  created_by_admin_id: string | null;
  created_at: string;
  updated_at: string;
};

export type SurveyRow = {
  id: number;
  project_id: number;
  title_translations: string;
  description_translations: string;
  status: string;
  web_enabled: number;
  auth_requirement: string;
  created_by_admin_id: string | null;
  created_at: string;
  updated_at: string;
  starts_at: string | null;
  ends_at: string | null;
};

export type QuestionRow = {
  id: number;
  survey_id: number;
  text_translations: string;
  type: string;
  order_index: number;
  is_required: number;
  placeholder_translations: string;
  min_length: number | null;
  max_length: number | null;
  min_selected: number | null;
  max_selected: number | null;
  visibility_condition_mode: string;
  is_deleted: number;
};

export type ChoiceRow = {
  id: number;
  question_id: number;
  text_translations: string;
  order_index: number;
  value: string | null;
};

export type ResponseRow = {
  id: number;
  survey_id: number;
  anonymous_account_id: string;
  anonymous_id: string | null;
  submitted_at: string;
  user_agent: string | null;
  device_id: string | null;
  device_label: string | null;
  device_platform: string | null;
  device_os: string | null;
  device_os_version: string | null;
  device_browser: string | null;
  device_browser_version: string | null;
  device_locale: string | null;
  device_timezone: string | null;
  screen_width: number | null;
  screen_height: number | null;
  device_pixel_ratio: number | null;
  device_info: string | null;
  metadata: string | null;
};

export type AnswerRow = {
  id: number;
  survey_response_id: number;
  question_id: number;
  text_value: string | null;
  selected_choice_ids: string | null;
};

export type AnswerInput = {
  questionId?: unknown;
  textValue?: unknown;
  selectedChoiceIds?: unknown;
};

export type ReplyRow = {
  id: number;
  survey_response_id: number;
  anonymous_account_id: string;
  admin_id: string | null;
  body: string;
  created_at: string;
  read_at: string | null;
};

export type AdminRow = {
  id: string;
  email: string;
  scope_names: string;
  created_at: string;
};

export type AnonymousAccountRow = {
  id: string;
  display_name: string | null;
  created_at: string;
  last_seen_at: string;
};

export type NotificationSettingsRow = {
  id: number;
  survey_id: number;
  enabled: number;
  recipient_email: string;
  updated_at: string;
};

export type IntegrationSettingsRow = {
  id: number;
  ai_provider: string;
  gemini_api_key: string | null;
  openai_api_key: string | null;
  claude_api_key: string | null;
  cerebras_api_key: string | null;
  smtp_host: string | null;
  smtp_port: number | null;
  smtp_username: string | null;
  smtp_password: string | null;
  smtp_from_email: string | null;
  smtp_from_name: string | null;
  smtp_secure_mode: string;
  updated_at: string;
};

export type QuestionInput = {
  textTranslations: Record<string, string>;
  type: string;
  isRequired: boolean;
  placeholderTranslations: Record<string, string>;
  minLength: number | null;
  maxLength: number | null;
  minSelected: number | null;
  maxSelected: number | null;
  visibilityConditionMode: string;
  choiceTranslations: Record<string, string>[];
};

export type VisibilityRuleRow = {
  id: number;
  survey_id: number;
  target_question_id: number;
  source_question_id: number;
  operator: string;
  value_json: string | null;
  created_at: string;
  updated_at: string;
};

export type VisibilityRuleInput = {
  targetQuestionId?: unknown;
  sourceQuestionId?: unknown;
  operator?: unknown;
  value?: unknown;
};

export type NormalizedDeviceInfo = {
  deviceId: string | null;
  label: string | null;
  platform: string | null;
  os: string | null;
  osVersion: string | null;
  browser: string | null;
  browserVersion: string | null;
  appVersion: string | null;
  appBuild: string | null;
  model: string | null;
  manufacturer: string | null;
  locale: string | null;
  timezone: string | null;
  screenWidth: number | null;
  screenHeight: number | null;
  devicePixelRatio: number | null;
  rawJson: string | null;
};
