import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';

class FieldSpec {
  const FieldSpec({
    required this.label,
    this.helper,
    this.required = true,
    this.integer = false,
    this.allowZero = false,
    this.initial,
  });
  final String label;
  final String? helper;
  final bool required;
  final bool integer; // digits only
  final bool allowZero;
  final String? initial;
}

/// Small reusable dialog with 1+ numeric fields.
/// Returns null if cancelled, else one value per field (null = left empty).
Future<List<double?>?> showNumbersDialog(
  BuildContext context, {
  required String title,
  required List<FieldSpec> fields,
  String? hint,
}) =>
    showDialog<List<double?>>(
      context: context,
      builder: (_) => _NumbersDialog(title: title, fields: fields, hint: hint),
    );

class _NumbersDialog extends StatefulWidget {
  const _NumbersDialog({required this.title, required this.fields, this.hint});
  final String title;
  final List<FieldSpec> fields;
  final String? hint;

  @override
  State<_NumbersDialog> createState() => _NumbersDialogState();
}

class _NumbersDialogState extends State<_NumbersDialog> {
  final _formKey = GlobalKey<FormState>();
  late final List<TextEditingController> _ctrls = [
    for (final f in widget.fields) TextEditingController(text: f.initial ?? ''),
  ];

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  double? _parse(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, [
      for (final c in _ctrls) c.text.trim().isEmpty ? null : _parse(c.text),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < widget.fields.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                TextFormField(
                  controller: _ctrls[i],
                  autofocus: i == 0,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    widget.fields[i].integer
                        ? FilteringTextInputFormatter.digitsOnly
                        : FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: InputDecoration(
                    labelText: widget.fields[i].label,
                    helperText: widget.fields[i].helper,
                  ),
                  validator: (v) {
                    final f = widget.fields[i];
                    if ((v ?? '').trim().isEmpty) {
                      return f.required ? s.t('invalid_number') : null;
                    }
                    final n = _parse(v!);
                    if (n == null || n < 0 || (!f.allowZero && n == 0)) {
                      return s.t('invalid_number');
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _submit(),
                ),
              ],
              if (widget.hint != null) ...[
                const SizedBox(height: 12),
                Text(widget.hint!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.brownSoft)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.t('cancel'))),
        FilledButton(onPressed: _submit, child: Text(s.t('add'))),
      ],
    );
  }
}
