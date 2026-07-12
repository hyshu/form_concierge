import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_concierge_flutter/src/core/localization/app_localizations.dart';

void main() {
  group('AppLocalizations', () {
    test('localeResolutionCallback normalizes supported language families', () {
      expect(
        AppLocalizations.localeResolutionCallback(
          const Locale('ja', 'JP'),
          AppLocalizations.supportedLocales,
        ),
        const Locale('ja'),
      );
      expect(
        AppLocalizations.localeResolutionCallback(
          const Locale('zh', 'TW'),
          AppLocalizations.supportedLocales,
        ),
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      );
      expect(
        AppLocalizations.localeResolutionCallback(
          const Locale('zh', 'CN'),
          AppLocalizations.supportedLocales,
        ),
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      );
      expect(
        AppLocalizations.localeResolutionCallback(
          const Locale('es', 'ES'),
          AppLocalizations.supportedLocales,
        ),
        const Locale('es'),
      );
      expect(
        AppLocalizations.localeResolutionCallback(
          const Locale('fr', 'FR'),
          AppLocalizations.supportedLocales,
        ),
        const Locale('fr'),
      );
      expect(
        AppLocalizations.localeResolutionCallback(
          const Locale('th', 'TH'),
          AppLocalizations.supportedLocales,
        ),
        const Locale('th'),
      );
    });

    test('text interpolates values and falls back to English or key', () {
      const l10n = AppLocalizations(Locale('en'));

      expect(
        l10n.text('Page {currentPage} of {totalPages}', {
          'currentPage': 2,
          'totalPages': 5,
        }),
        'Page 2 of 5',
      );
      expect(l10n.text('Unknown key'), 'Unknown key');
    });

    test('message localizes known error prefixes', () {
      const l10n = AppLocalizations(Locale('en'));

      expect(
        l10n.message('Failed to create survey: Domain already exists'),
        'Failed to create survey: Domain already exists',
      );
    });

    test('Japanese translations are available for custom domain labels', () {
      const l10n = AppLocalizations(Locale('ja'));

      expect(l10n.text('Custom domain (optional)'), 'カスタムドメイン (任意)');
      expect(
        l10n.text('Custom domain must be a hostname like forms.example.com'),
        'カスタムドメインは forms.example.com のようなホスト名にしてください',
      );
    });

    test(
      'project dashboard labels are localized for every supported locale',
      () {
        const projectKeys = [
          'New Project',
          'Project Settings',
          'Project not found',
          'Create Project',
          'Project URL Slug',
          'Custom domain (optional)',
          'Localized languages',
          'Select languages',
          'Default language',
          'Project name',
          'Enter project name',
          'Project name is required',
          'Web public',
        ];

        for (final locale in AppLocalizations.supportedLocales.skip(1)) {
          final l10n = AppLocalizations(locale);
          for (final key in projectKeys) {
            expect(
              l10n.text(key),
              isNot(key),
              reason: 'Missing $key for $locale',
            );
          }
        }
      },
    );

    test(
      'Turnstile settings labels are localized for every supported locale',
      () {
        const turnstileKeys = [
          'Turnstile CAPTCHA',
          'Cloudflare Turnstile keys for web form bot protection. '
              'Create a widget in the Cloudflare dashboard, then paste both keys here.',
          'Site Key',
          'Secret Key',
          'Leave blank to keep the saved site key',
          'Leave blank to keep the saved secret key',
          'Clear saved site key',
          'Clear saved secret key',
        ];

        // Product name stays "Turnstile CAPTCHA" in all locales; assert ja + others
        // for keys that should differ from English.
        const ja = AppLocalizations(Locale('ja'));
        expect(ja.text('Site Key'), 'サイトキー');
        expect(ja.text('Secret Key'), 'シークレットキー');
        expect(ja.text('Clear saved site key'), '保存済みのサイトキーを削除');
        expect(
          ja.text(
            'Cloudflare Turnstile keys for web form bot protection. '
            'Create a widget in the Cloudflare dashboard, then paste both keys here.',
          ),
          contains('Cloudflare Turnstile'),
        );

        for (final locale in AppLocalizations.supportedLocales.skip(1)) {
          final l10n = AppLocalizations(locale);
          for (final key in turnstileKeys) {
            // All locales must define the key (not fall through to raw key).
            // Some values intentionally equal English (brand names).
            final value = l10n.text(key);
            expect(value, isNotEmpty, reason: 'Empty $key for $locale');
            expect(
              value == key && key != 'Turnstile CAPTCHA',
              isFalse,
              reason: 'Missing translation for $key ($locale)',
            );
          }
        }
      },
    );
  });
}
