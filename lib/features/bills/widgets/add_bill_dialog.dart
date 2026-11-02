import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format.dart';
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
  int _splitWays = 1;

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
          splitWays: _splitWays,
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final parsedAmount = int.tryParse(_amount.text.trim());

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
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.t('bill_split_ways', {'n': '$_splitWays'}),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (_splitWays > 1 && parsedAmount != null)
                          Text(
                            s.t('bill_my_share', {
                              'amount': fmtMoney(
                                (parsedAmount / _splitWays).round(),
                                s.lang,
                              ),
                            }),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.mint,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                      ],
                    ),
                  ),
                  IconButton.outlined(
                    icon: const Icon(Icons.remove, size: 18),
                    visualDensity: VisualDensity.compact,
                    onPressed: _splitWays > 1
                        ? () => setState(() => _splitWays--)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$_splitWays',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    icon: const Icon(Icons.add, size: 18),
                    visualDensity: VisualDensity.compact,
                    onPressed: _splitWays < 10
                        ? () => setState(() => _splitWays++)
                        : null,
                  ),
                ],
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
