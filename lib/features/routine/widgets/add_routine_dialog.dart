import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/app_strings.dart';
import '../data/routines_controller.dart';

class AddRoutineDialog extends StatefulWidget {
  const AddRoutineDialog({super.key});

  @override
  State<AddRoutineDialog> createState() => _AddRoutineDialogState();
}

class _AddRoutineDialogState extends State<AddRoutineDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _days = TextEditingController(text: '7');

  @override
  void dispose() {
    _name.dispose();
    _days.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context
        .read<RoutinesController>()
        .add(_name.text.trim(), int.parse(_days.text));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AlertDialog(
      title: Text(s.t('add_routine')),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: s.t('routine_name')),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? s.t('name_required') : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _days,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: s.t('interval_days')),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return (n == null || n < 1 || n > 365)
                    ? s.t('interval_invalid')
                    : null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
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
