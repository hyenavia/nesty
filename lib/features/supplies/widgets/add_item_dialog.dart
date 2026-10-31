import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/app_strings.dart';
import '../data/supplies_controller.dart';
import '../data/supply_item.dart';
import 'supply_ui.dart';

class AddItemDialog extends StatefulWidget {
  const AddItemDialog({super.key, this.initialCategory});
  final SupplyCategory? initialCategory;

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late SupplyCategory _category = widget.initialCategory ?? SupplyCategory.food;
  SupplyStatus _status = SupplyStatus.safe;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<SuppliesController>().add(
          name: _nameCtrl.text.trim(),
          category: _category,
          status: _status,
          quantity: int.tryParse(_qtyCtrl.text.trim()),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final label = Theme.of(context).textTheme.labelLarge;

    return AlertDialog(
      title: Text(s.t('add_item')),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: s.t('item_name')),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? s.t('name_required')
                    : null,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _qtyCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: s.t('qty_optional')),
              ),
              const SizedBox(height: 16),
              Text(s.t('category'), style: label),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final c in SupplyCategory.values)
                    ChoiceChip(
                      label: Text(s.t(c.labelKey)),
                      selected: _category == c,
                      onSelected: (_) => setState(() => _category = c),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(s.t('status'), style: label),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final st in SupplyStatus.values)
                    ChoiceChip(
                      label: Text(s.t(st.labelKey)),
                      avatar: CircleAvatar(radius: 6, backgroundColor: st.color),
                      selected: _status == st,
                      onSelected: (_) => setState(() => _status = st),
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
          child: Text(s.t('cancel')),
        ),
        FilledButton(onPressed: _submit, child: Text(s.t('add'))),
      ],
    );
  }
}
