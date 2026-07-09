import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:form_concierge_survey_widget/form_concierge_survey_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _apiUrl = String.fromEnvironment(
  'FORM_CONCIERGE_API_URL',
  defaultValue: 'http://localhost:8787',
);
const _defaultProjectSlug = String.fromEnvironment(
  'FORM_CONCIERGE_PROJECT_SLUG',
  defaultValue: 'demo-project',
);
const _defaultSurveySlug = String.fromEnvironment('FORM_CONCIERGE_SURVEY_SLUG');
const _defaultSurveyId = int.fromEnvironment('FORM_CONCIERGE_SURVEY_ID');
const _defaultLocale = String.fromEnvironment(
  'FORM_CONCIERGE_LOCALE',
  defaultValue: defaultFormContentLocale,
);

const _projectSlugKey = 'form_concierge.flutter_mobile_full.project_slug';
const _surveySlugKey = 'form_concierge.flutter_mobile_full.survey_slug';
const _surveyIdKey = 'form_concierge.flutter_mobile_full.survey_id';
const _appLocaleKey = 'form_concierge.flutter_mobile_full.app_locale';
const _formLocaleKey = 'form_concierge.flutter_mobile_full.form_locale';
const _lastResponseIdKey =
    'form_concierge.flutter_mobile_full.last_response_id';
const _anonymousTokenKey = 'form_concierge.flutter_mobile_full.anonymous_token';

const _secureStorage = FlutterSecureStorage(
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final token = await _secureStorage.read(key: _anonymousTokenKey);
  runApp(
    FlutterMobileFullApp(
      prefs: prefs,
      secureStorage: _secureStorage,
      initialAnonymousToken: token,
    ),
  );
}

class FlutterMobileFullApp extends StatefulWidget {
  const FlutterMobileFullApp({
    super.key,
    required this.prefs,
    required this.secureStorage,
    required this.initialAnonymousToken,
  });

  final SharedPreferences prefs;
  final FlutterSecureStorage secureStorage;
  final String? initialAnonymousToken;

  @override
  State<FlutterMobileFullApp> createState() => _FlutterMobileFullAppState();
}

class _FlutterMobileFullAppState extends State<FlutterMobileFullApp> {
  late Locale _appLocale;

  @override
  void initState() {
    super.initState();
    _appLocale = Locale(
      widget.prefs.getString(_appLocaleKey) ?? defaultFormContentLocale,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Mobile Full',
      locale: _appLocale,
      supportedLocales: ExampleStrings.supportedLocales,
      localizationsDelegates: const [
        ExampleStringsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: FlutterMobileFullHomePage(
        prefs: widget.prefs,
        secureStorage: widget.secureStorage,
        initialAnonymousToken: widget.initialAnonymousToken,
        onAppLocaleChanged: (locale) => setState(() => _appLocale = locale),
      ),
    );
  }
}

class FlutterMobileFullHomePage extends StatefulWidget {
  const FlutterMobileFullHomePage({
    super.key,
    required this.prefs,
    required this.secureStorage,
    required this.initialAnonymousToken,
    required this.onAppLocaleChanged,
  });

  final SharedPreferences prefs;
  final FlutterSecureStorage secureStorage;
  final String? initialAnonymousToken;
  final ValueChanged<Locale> onAppLocaleChanged;

  @override
  State<FlutterMobileFullHomePage> createState() =>
      _FlutterMobileFullHomePageState();
}

class _FlutterMobileFullHomePageState extends State<FlutterMobileFullHomePage> {
  late final Client _client;
  late final TextEditingController _projectSlugController;
  late final TextEditingController _surveySlugController;
  late final TextEditingController _surveyIdController;
  late String _formLocale;
  String? _anonymousToken;
  int? _lastResponseId;
  bool _checkingReplies = false;
  FormConciergeReplyCheckResult? _replyCheckResult;

  @override
  void initState() {
    super.initState();
    _client = Client(_apiUrl);
    _anonymousToken = widget.initialAnonymousToken;
    if (_anonymousToken case final token?) {
      _client.anonymous.useToken(token);
    }
    _projectSlugController = TextEditingController(
      text: widget.prefs.getString(_projectSlugKey) ?? _defaultProjectSlug,
    );
    _surveySlugController = TextEditingController(
      text: widget.prefs.getString(_surveySlugKey) ?? _defaultSurveySlug,
    );
    _surveyIdController = TextEditingController(text: _initialSurveyIdText());
    _formLocale = _normalizedFormLocale(
      widget.prefs.getString(_formLocaleKey) ?? _defaultLocale,
    );
    _lastResponseId = widget.prefs.getInt(_lastResponseIdKey);
  }

  String _initialSurveyIdText() {
    final saved = widget.prefs.getInt(_surveyIdKey);
    if (saved != null) return '$saved';
    return _defaultSurveyId == 0 ? '' : '$_defaultSurveyId';
  }

  @override
  void dispose() {
    _projectSlugController.dispose();
    _surveySlugController.dispose();
    _surveyIdController.dispose();
    _client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ExampleStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.text('title')),
        actions: [
          PopupMenuButton<String>(
            tooltip: strings.text('app_language'),
            icon: const Icon(Icons.language),
            onSelected: _setAppLocale,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'en', child: Text('English')),
              PopupMenuItem(value: 'ja', child: Text('日本語')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              strings.text('overview'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            _Section(
              title: strings.text('connection'),
              children: [
                _InfoRow(label: strings.text('api_url'), value: _apiUrl),
                const SizedBox(height: 12),
                TextField(
                  controller: _projectSlugController,
                  decoration: InputDecoration(
                    labelText: strings.text('project_slug'),
                    border: const OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _surveySlugController,
                  decoration: InputDecoration(
                    labelText: strings.text('survey_slug'),
                    helperText: strings.text('survey_slug_helper'),
                    border: const OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _surveyIdController,
                  decoration: InputDecoration(
                    labelText: strings.text('survey_id'),
                    helperText: strings.text('survey_id_helper'),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Section(
              title: strings.text('localization'),
              children: [
                DropdownButtonFormField<String>(
                  key: ValueKey(_formLocale),
                  initialValue: _formLocale,
                  decoration: InputDecoration(
                    labelText: strings.text('form_language'),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    for (final locale in formContentLocaleCodes)
                      DropdownMenuItem(
                        value: locale,
                        child: Text(formContentLocaleLabels[locale]!),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _formLocale = value);
                    _saveSettings();
                  },
                ),
                const SizedBox(height: 8),
                Text(strings.text('localization_note')),
              ],
            ),
            const SizedBox(height: 16),
            _Section(
              title: strings.text('storage'),
              children: [
                _InfoRow(
                  label: strings.text('shared_preferences'),
                  value: _lastResponseId == null
                      ? strings.text('no_response')
                      : strings.format('last_response', {
                          'id': _lastResponseId!,
                        }),
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  label: strings.text('secure_storage'),
                  value: _anonymousToken == null
                      ? strings.text('token_missing')
                      : strings.text('token_saved'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Section(
              title: strings.text('reply_checker'),
              children: [
                if (_replyCheckResult case final result?) ...[
                  _InfoRow(
                    label: strings.text('latest_reply'),
                    value: _formatDate(result.latestReplyAt),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: strings.text('last_seen'),
                    value: _formatDate(result.lastSeenReplyAt),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: strings.text('new_replies'),
                    value: result.hasNewReplies
                        ? strings.text('yes')
                        : strings.text('no'),
                  ),
                  const SizedBox(height: 12),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _checkingReplies
                          ? null
                          : () => _checkReplies(),
                      icon: const Icon(Icons.mark_chat_unread),
                      label: Text(strings.text('check_replies')),
                    ),
                    OutlinedButton.icon(
                      onPressed: _checkingReplies
                          ? null
                          : () => _checkReplies(markSeen: true),
                      icon: const Icon(Icons.done_all),
                      label: Text(strings.text('mark_seen')),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _openSurvey,
              icon: const Icon(Icons.open_in_new),
              label: Text(strings.text('open_survey')),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _clearLocalState,
              icon: const Icon(Icons.delete_outline),
              label: Text(strings.text('clear_state')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setAppLocale(String value) async {
    final locale = Locale(value);
    await widget.prefs.setString(_appLocaleKey, value);
    widget.onAppLocaleChanged(locale);
  }

  String _normalizedFormLocale(String value) {
    final normalized = normalizeFormContentLocale(value);
    return formContentLocaleCodes.contains(normalized)
        ? normalized
        : defaultFormContentLocale;
  }

  Future<void> _saveSettings() async {
    final projectSlug = _projectSlugController.text.trim();
    if (projectSlug.isNotEmpty) {
      await widget.prefs.setString(_projectSlugKey, projectSlug);
    }
    final surveySlug = _surveySlugController.text.trim();
    if (surveySlug.isEmpty) {
      await widget.prefs.remove(_surveySlugKey);
    } else {
      await widget.prefs.setString(_surveySlugKey, surveySlug);
    }
    await widget.prefs.setString(_formLocaleKey, _formLocale);
    final surveyId = int.tryParse(_surveyIdController.text.trim());
    if (surveyId == null) {
      await widget.prefs.remove(_surveyIdKey);
    } else {
      await widget.prefs.setInt(_surveyIdKey, surveyId);
    }
  }

  Future<void> _openSurvey() async {
    final strings = ExampleStrings.of(context);
    await _saveSettings();
    if (!mounted) return;
    final projectSlug = _projectSlugController.text.trim();
    if (projectSlug.isEmpty) {
      _showSnack(strings.text('project_slug_required'));
      return;
    }
    final submittedResponse = await Navigator.of(context).push<SurveyResponse>(
      MaterialPageRoute(
        builder: (context) => SurveyScreen(
          client: _client,
          projectSlug: projectSlug,
          surveySlug: _surveySlugController.text.trim().isEmpty
              ? null
              : _surveySlugController.text.trim(),
          surveyId: int.tryParse(_surveyIdController.text.trim()),
          locale: _formLocale,
          anonymousToken: _anonymousToken,
          onAnonymousSession: _storeAnonymousSession,
        ),
      ),
    );
    if (submittedResponse == null) return;
    await widget.prefs.setInt(_lastResponseIdKey, submittedResponse.id!);
    if (!mounted) return;
    setState(() => _lastResponseId = submittedResponse.id);
    _showSnack(strings.text('submitted'));
  }

  Future<void> _storeAnonymousSession(AnonymousSession session) async {
    await widget.secureStorage.write(
      key: _anonymousTokenKey,
      value: session.token,
    );
    _client.anonymous.useToken(session.token, account: session.account);
    if (mounted) setState(() => _anonymousToken = session.token);
  }

  Future<void> _checkReplies({bool markSeen = false}) async {
    final strings = ExampleStrings.of(context);
    final token = _anonymousToken;
    if (token == null) {
      _showSnack(strings.text('token_required'));
      return;
    }
    setState(() => _checkingReplies = true);
    try {
      final prefs = widget.prefs;
      final checker = FormConciergeReplyChecker(
        client: _client,
        anonymousToken: token,
        responseId: _lastResponseId,
        // Persistence stays in the host app; the widget package has no store.
        store: FormConciergeReplySeenStore(
          read: (key) async => prefs.getString(key),
          write: (key, value) async {
            await prefs.setString(key, value);
          },
          remove: (key) async {
            await prefs.remove(key);
          },
        ),
      );
      final result = await checker.check(markSeen: markSeen);
      if (!mounted) return;
      setState(() => _replyCheckResult = result);
      _showSnack(strings.text(markSeen ? 'seen_saved' : 'reply_checked'));
    } on Exception catch (error) {
      if (mounted) _showSnack('${strings.text('reply_check_failed')}$error');
    } finally {
      if (mounted) setState(() => _checkingReplies = false);
    }
  }

  Future<void> _clearLocalState() async {
    await widget.prefs.remove(_projectSlugKey);
    await widget.prefs.remove(_surveySlugKey);
    await widget.prefs.remove(_surveyIdKey);
    await widget.prefs.remove(_lastResponseIdKey);
    await widget.prefs.remove(_appLocaleKey);
    await widget.prefs.remove(_formLocaleKey);
    await widget.secureStorage.delete(key: _anonymousTokenKey);
    _client.anonymous.clear();
    if (!mounted) return;
    setState(() {
      _projectSlugController.text = _defaultProjectSlug;
      _surveySlugController.text = _defaultSurveySlug;
      _surveyIdController.text = _defaultSurveyId == 0
          ? ''
          : '$_defaultSurveyId';
      _formLocale = defaultFormContentLocale;
      _anonymousToken = null;
      _lastResponseId = null;
      _replyCheckResult = null;
    });
    widget.onAppLocaleChanged(const Locale(defaultFormContentLocale));
    _showSnack(ExampleStrings.of(context).text('state_cleared'));
  }

  String _formatDate(DateTime? value) {
    if (value == null) return ExampleStrings.of(context).text('none');
    return value.toLocal().toIso8601String();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class SurveyScreen extends StatelessWidget {
  const SurveyScreen({
    super.key,
    required this.client,
    required this.projectSlug,
    required this.surveySlug,
    required this.surveyId,
    required this.locale,
    required this.anonymousToken,
    required this.onAnonymousSession,
  });

  final Client client;
  final String projectSlug;
  final String? surveySlug;
  final int? surveyId;
  final String locale;
  final String? anonymousToken;
  final ValueChanged<AnonymousSession> onAnonymousSession;

  @override
  Widget build(BuildContext context) {
    final strings = ExampleStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.text('survey'))),
      body: FormConciergeSurvey(
        client: client,
        projectSlug: projectSlug,
        surveySlug: surveySlug,
        surveyId: surveyId,
        locale: locale,
        anonymousToken: anonymousToken,
        anonymousId: 'flutter-mobile-full',
        deviceInfo: DeviceInfo(
          label: defaultTargetPlatform.name,
          platform: 'flutter-mobile',
          os: defaultTargetPlatform.name,
          appVersion: 'flutter-mobile-full',
        ),
        metadata: {
          'source': 'flutter-mobile-full',
          'locale': locale,
          'projectSlug': projectSlug,
          if (surveySlug != null) 'surveySlug': surveySlug,
          if (surveyId != null) 'surveyId': surveyId,
        },
        onAnonymousSession: onAnonymousSession,
        onResponseSubmitted: (response) {
          Navigator.of(context).pop(response);
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
        Expanded(child: SelectableText(value)),
      ],
    );
  }
}

class ExampleStrings {
  const ExampleStrings(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('ja')];

  static ExampleStrings of(BuildContext context) {
    return Localizations.of<ExampleStrings>(context, ExampleStrings)!;
  }

  String text(String key) => _values[_language]![key] ?? _values['en']![key]!;

  String format(String key, Map<String, Object> values) {
    var result = text(key);
    for (final entry in values.entries) {
      result = result.replaceAll('{${entry.key}}', '${entry.value}');
    }
    return result;
  }

  String get _language =>
      _values.containsKey(locale.languageCode) ? locale.languageCode : 'en';
}

class ExampleStringsDelegate extends LocalizationsDelegate<ExampleStrings> {
  const ExampleStringsDelegate();

  @override
  bool isSupported(Locale locale) {
    return _values.containsKey(locale.languageCode);
  }

  @override
  Future<ExampleStrings> load(Locale locale) async => ExampleStrings(locale);

  @override
  bool shouldReload(ExampleStringsDelegate old) => false;
}

const _values = {
  'en': {
    'title': 'Flutter Mobile Full',
    'overview':
        'Full mobile sample using SharedPreferences, secure storage, localized UI, callbacks, metadata, device info, and reply checks.',
    'connection': 'Connection',
    'api_url': 'API URL',
    'project_slug': 'Project slug',
    'project_slug_required': 'Project slug is required.',
    'survey_slug': 'Survey slug',
    'survey_slug_helper':
        'Preferred. Leave empty to use survey ID or the first published survey.',
    'survey_id': 'Survey ID',
    'survey_id_helper': 'Optional fallback for older survey URLs.',
    'localization': 'Localization',
    'form_language': 'Form language',
    'localization_note':
        'The selected locale is saved in SharedPreferences and passed to the embedded form.',
    'storage': 'Storage',
    'shared_preferences': 'SharedPreferences',
    'secure_storage': 'Secure storage',
    'no_response': 'No submitted response saved.',
    'last_response': 'Last response ID: {id}',
    'token_missing': 'No anonymous token saved.',
    'token_saved': 'Anonymous token saved in secure storage.',
    'reply_checker': 'Reply checker',
    'latest_reply': 'Latest reply',
    'last_seen': 'Last seen',
    'new_replies': 'New replies',
    'yes': 'Yes',
    'no': 'No',
    'none': 'None',
    'check_replies': 'Check replies',
    'mark_seen': 'Mark seen',
    'open_survey': 'Open survey',
    'clear_state': 'Clear local state',
    'app_language': 'App language',
    'survey': 'Survey',
    'submitted': 'Survey submitted.',
    'token_required': 'Submit once to create an anonymous token.',
    'seen_saved': 'Latest reply marked seen.',
    'reply_checked': 'Reply status checked.',
    'reply_check_failed': 'Reply check failed: ',
    'state_cleared': 'Local state cleared.',
  },
  'ja': {
    'title': 'モバイル全部入りサンプル',
    'overview':
        'SharedPreferences、Secure Storage、ローカライズ、callbacks、metadata、device info、返信確認を使う全部入りモバイルサンプルです。',
    'connection': '接続',
    'api_url': 'API URL',
    'project_slug': 'プロジェクト slug',
    'project_slug_required': 'プロジェクト slug は必須です。',
    'survey_slug': 'フォーム slug',
    'survey_slug_helper': '推奨。空ならフォーム ID または最初の公開フォームを使います。',
    'survey_id': 'フォーム ID',
    'survey_id_helper': '古いフォームURL向けの任意fallbackです。',
    'localization': 'ローカライズ',
    'form_language': 'フォーム言語',
    'localization_note':
        '選択した locale は SharedPreferences に保存され、埋め込みフォームへ渡されます。',
    'storage': 'ストレージ',
    'shared_preferences': 'SharedPreferences',
    'secure_storage': 'Secure Storage',
    'no_response': '保存済み回答はありません。',
    'last_response': '最後の回答 ID: {id}',
    'token_missing': '匿名 token は未保存です。',
    'token_saved': '匿名 token は secure storage に保存済みです。',
    'reply_checker': '返信確認',
    'latest_reply': '最新返信',
    'last_seen': '既読',
    'new_replies': '新着返信',
    'yes': 'あり',
    'no': 'なし',
    'none': 'なし',
    'check_replies': '返信確認',
    'mark_seen': '既読にする',
    'open_survey': 'フォームを開く',
    'clear_state': 'ローカル状態を削除',
    'app_language': 'アプリ言語',
    'survey': 'フォーム',
    'submitted': 'フォームを送信しました。',
    'token_required': '一度送信して匿名 token を作成してください。',
    'seen_saved': '最新返信を既読にしました。',
    'reply_checked': '返信状態を確認しました。',
    'reply_check_failed': '返信確認に失敗しました: ',
    'state_cleared': 'ローカル状態を削除しました。',
  },
};
