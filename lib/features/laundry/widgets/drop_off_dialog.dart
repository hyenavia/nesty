import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/format.dart';
import 'photo_actions.dart';

class DropOffResult {
  const DropOffResult({this.shop, this.weightKg, required this.dueDate, this.photo});
  final String? shop;
  final double? weightKg;
  final DateTime dueDate;
  final String? photo;
}

/// "Hand over": shop, weight (kg), promised date, optional receipt photo.
class DropOffDialog extends StatefulWidget {
  const DropOffDialog({super.key, this.initialShop, this.initialDue, this.initialPhoto});
  final String? initialShop;
  final DateTime? initialDue;
  final String? initialPhoto;

  @override
  State<DropOffDialog> createState() => _DropOffDialogState();
}

class _DropOffDialogState extends State<DropOffDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _shop = TextEditingController(text: widget.initialShop ?? '');
  final _weight = TextEditingController();
  late DateTime _due = widget.initialDue ??
      DateTime.now().add(const Duration(days: 2)); // typical kiloan turnaround
  late String? _photo = widget.initialPhoto;

  @override
  void dispose() {
    _shop.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _due = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final w = double.tryParse(_weight.text.trim().replaceAll(',', '.'));
    Navigator.pop(
      context,
      DropOffResult(
        shop: _shop.text.trim().isEmpty ? null : _shop.text.trim(),
        weightKg: w,
        dueDate: _due,
        photo: _photo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AlertDialog(
      title: Text(s.t('laundry_handover_title')),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _shop,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: s.t('laundry_shop')),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _weight,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: InputDecoration(labelText: s.t('laundry_weight')),
                validator: (v) {
                  if ((v ?? '').trim().isEmpty) return null;
                  final n = double.tryParse(v!.trim().replaceAll(',', '.'));
                  return (n == null || n <= 0) ? s.t('invalid_number') : null;
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event_rounded),
                label: Text('${s.t('laundry_due')}: ${fmtDate(_due, s.lang)}'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (_photo != null) ...[
                    OrderPhoto(name: _photo!, size: 56),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final p = await choosePhoto(context);
                        if (p != null) setState(() => _photo = p);
                      },
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: Text(s.t('laundry_receipt_photo')),
                    ),
                  ),
                  if (_photo != null)
                    IconButton(
                      tooltip: s.t('laundry_photo_remove'),
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => setState(() => _photo = null),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.t('cancel'))),
        FilledButton(
            onPressed: _submit, child: Text(s.t('laundry_act_handover'))),
      ],
    );
  }
}
