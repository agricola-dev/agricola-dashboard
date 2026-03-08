import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/widgets/app_dropdown_field.dart';
import 'package:agricola_dashboard/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';

/// Units available for inventory quantities.
const _units = ['kg', 'bags', 'tons'];

/// Condition levels for inventory items.
const _conditions = [
  'excellent',
  'good',
  'fair',
  'poor',
  'needs_attention',
  'critical',
];

/// Shows an add/edit inventory dialog. Returns a completed [InventoryModel]
/// on submit, or null if the user cancels.
Future<InventoryModel?> showInventoryFormDialog(
  BuildContext context, {
  required AppLanguage lang,
  InventoryModel? item,
}) {
  return showDialog<InventoryModel>(
    context: context,
    builder: (context) => _InventoryFormDialog(lang: lang, item: item),
  );
}

class _InventoryFormDialog extends StatefulWidget {
  const _InventoryFormDialog({required this.lang, this.item});

  final AppLanguage lang;
  final InventoryModel? item;

  @override
  State<_InventoryFormDialog> createState() => _InventoryFormDialogState();
}

class _InventoryFormDialogState extends State<_InventoryFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _cropTypeController;
  late final TextEditingController _quantityController;
  late final TextEditingController _storageLocationController;
  late final TextEditingController _notesController;
  late String _unit;
  late String _condition;
  late DateTime _storageDate;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _cropTypeController = TextEditingController(text: item?.cropType ?? '');
    _quantityController = TextEditingController(
      text: item != null ? item.quantity.toString() : '',
    );
    _storageLocationController =
        TextEditingController(text: item?.storageLocation ?? '');
    _notesController = TextEditingController(text: item?.notes ?? '');
    _unit = item?.unit ?? _units.first;
    _condition = item?.condition ?? _conditions.first;
    _storageDate = item?.storageDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _cropTypeController.dispose();
    _quantityController.dispose();
    _storageLocationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final colors = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(_isEdit ? t('edit_inventory', lang) : t('add_inventory', lang)),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: _cropTypeController,
                  label: t('crop_type', lang),
                  prefixIcon: Icons.grass,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return t('field_required', lang);
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: AppTextField(
                        controller: _quantityController,
                        label: t('quantity', lang),
                        prefixIcon: Icons.scale,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return t('quantity_required', lang);
                          }
                          final parsed = double.tryParse(value);
                          if (parsed == null || parsed <= 0) {
                            return t('quantity_invalid', lang);
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppDropdownField<String>(
                        value: _unit,
                        items: _units,
                        itemLabelBuilder: (u) => u,
                        label: t('unit', lang),
                        onChanged: (value) {
                          if (value != null) setState(() => _unit = value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppDropdownField<String>(
                  value: _condition,
                  items: _conditions,
                  itemLabelBuilder: (c) => t(c, lang),
                  label: t('condition', lang),
                  prefixIcon: Icons.health_and_safety,
                  onChanged: (value) {
                    if (value != null) setState(() => _condition = value);
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _storageLocationController,
                  label: t('storage_location', lang),
                  prefixIcon: Icons.warehouse,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return t('field_required', lang);
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _DatePickerField(
                  label: t('storage_date', lang),
                  date: _storageDate,
                  colors: colors,
                  onTap: () => _pickDate(context),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _notesController,
                  label: t('add_notes', lang),
                  prefixIcon: Icons.notes,
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t('cancel', lang)),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(
            _isEdit ? t('update_inventory', lang) : t('add_inventory', lang),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _storageDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _storageDate = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final item = InventoryModel(
      id: widget.item?.id,
      cropType: _cropTypeController.text.trim(),
      quantity: double.parse(_quantityController.text.trim()),
      unit: _unit,
      storageDate: _storageDate,
      storageLocation: _storageLocationController.text.trim(),
      condition: _condition,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      createdAt: widget.item?.createdAt,
      updatedAt: DateTime.now(),
    );

    Navigator.of(context).pop(item);
  }
}

/// A tappable date display field matching input decoration style.
class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.date,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final ColorScheme colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }
}
