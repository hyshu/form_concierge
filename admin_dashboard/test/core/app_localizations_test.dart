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
        const Locale('en'),
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
          'Project content',
          'Project name',
          'Enter project name',
          'Project name is required',
          'Localized descriptions',
          'Brief description of the project',
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
  });
}
