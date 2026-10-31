import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/app_strings.dart';
import '../data/bills_controller.dart';

class AddBillDialog extends StatefulWidget {
  const AddBillDialog({super.key});

  @override
  State<AddBillDialog> createState() => _AddBillDialogState();
}

class _AddBillDialogState extends State<AddBillDialog> {
  static const _presets = [
    'bill_preset_rent',
    'bill_preset_wifi',
    'bill_preset_water',
    'bill_preset_phone',
  ];

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _day = TextEditingController(text: '${DateTime.now().day}');

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _day.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<BillsController>().add(
          name: _name.text.trim(),
          amountRp: int.tryParse(_amount.text.trim()),
          dayOfMonth: int.parse(_day.text.trim()),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AlertDialog(
      title: Text(s.t('bill_add')),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final p in _presets)
                    ActionChip(
                      label: Text(s.t(p)),
                      onPressed: () => setState(() => _name.text = s.t(p)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: s.t('bill_name')),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? s.t('name_required') : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amount,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: s.t('bill_amount')),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _day,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: s.t('bill_day')),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return (n == null || n < 1 || n > 31)
                      ? s.t('bill_day_invalid')
                      : null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
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
