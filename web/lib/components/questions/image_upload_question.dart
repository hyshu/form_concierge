import 'dart:js_interop';
import 'dart:typed_data';

import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:universal_web/web.dart' as web;

/// Browser file-picker image upload for main survey answers.
class ImageUploadQuestion extends StatefulComponent {
  const ImageUploadQuestion({
    required this.client,
    required this.question,
    required this.value,
    required this.locale,
    required this.onChanged,
    required this.ensureAuthenticated,
    super.key,
  });

  final Client client;
  final Question question;
  final List<String> value;
  final String locale;
  final void Function(AnswerValue value) onChanged;
  final Future<void> Function() ensureAuthenticated;

  @override
  State<ImageUploadQuestion> createState() => _ImageUploadQuestionState();
}

class _ImageUploadQuestionState extends State<ImageUploadQuestion> {
  bool _uploading = false;
  String? _error;

  int get _maxFiles => component.question.maxSelected ?? 3;

  @override
  Component build(context) {
    final keys = component.value;
    final canAdd = !_uploading && keys.length < _maxFiles;

    return div(classes: 'space-y-3', [
      if (keys.isNotEmpty)
        div(classes: 'space-y-2', [
          for (final key in keys)
            div(
              classes:
                  'flex items-center justify-between gap-3 rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-sm',
              [
                span(classes: 'truncate text-slate-700', [
                  Component.text(key.split('/').last),
                ]),
                button(
                  [Component.text('×')],
                  type: ButtonType.button,
                  classes:
                      'text-base leading-none text-red-600 hover:text-red-700 px-1',
                  disabled: _uploading,
                  onClick: _uploading
                      ? null
                      : () {
                          final next = List<String>.from(keys)..remove(key);
                          component.onChanged(next);
                        },
                  attributes: const {'aria-label': 'Remove image'},
                ),
              ],
            ),
        ]),
      p(classes: 'text-xs text-slate-500', [
        Component.text(
          FormContentMessages.text(component.locale, 'maxPhotosReached')
              .replaceAll('{count}', '$_maxFiles'),
        ),
      ]),
      label(
        classes: canAdd
            ? 'inline-flex cursor-pointer items-center rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm text-slate-700 hover:bg-slate-50'
            : 'inline-flex cursor-not-allowed items-center rounded-lg border border-slate-200 bg-slate-100 px-4 py-2 text-sm text-slate-400',
        [
          Component.text(
            FormContentMessages.text(
              component.locale,
              _uploading ? 'uploadingPhotos' : 'addPhotos',
            ),
          ),
          input(
            type: InputType.file,
            classes: 'hidden',
            attributes: {
              'accept': 'image/jpeg,image/png,image/webp,image/gif',
              if (_maxFiles > 1) 'multiple': 'multiple',
              if (!canAdd) 'disabled': 'disabled',
            },
            onChange: canAdd
                ? (List<web.File> files) {
                    _onFilesSelected(files);
                  }
                : null,
          ),
        ],
      ),
      if (_error != null)
        p(classes: 'text-xs text-red-600', [Component.text(_error!)]),
    ]);
  }

  Future<void> _onFilesSelected(List<web.File> files) async {
    if (files.isEmpty) return;

    setState(() {
      _uploading = true;
      _error = null;
    });

    try {
      await component.ensureAuthenticated();
      final remaining = _maxFiles - component.value.length;
      final keys = List<String>.from(component.value);
      final selected = files.take(remaining);

      for (final file in selected) {
        final contentType = _contentTypeFor(file);
        final bytes = await _readFileBytes(file);
        final uploaded = await component.client.survey.uploadMedia(
          bytes: bytes,
          contentType: contentType,
        );
        keys.add(uploaded.key);
      }

      component.onChanged(keys);
      setState(() => _uploading = false);
    } on Exception catch (_) {
      setState(() {
        _uploading = false;
        _error = FormContentMessages.text(
          component.locale,
          'photoUploadFailed',
        );
      });
    }
  }

  String _contentTypeFor(web.File file) {
    final type = file.type;
    if (type.startsWith('image/')) return type;
    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  Future<Uint8List> _readFileBytes(web.File file) async {
    final buffer = await file.arrayBuffer().toDart;
    return buffer.toDart.asUint8List();
  }
}
