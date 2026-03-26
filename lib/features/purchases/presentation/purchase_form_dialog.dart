import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/utils/form_validators.dart';
import 'package:agricola_dashboard/core/widgets/app_dropdown_field.dart';
import 'package:agricola_dashboard/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';

/// Units available for purchase quantities.
const _units = ['kg', 'bags', 'tons'];

/// Shows an add/edit purchase dialog. Returns a completed [PurchaseModel]
/// on submit, or null if the user cancels.
Future<PurchaseModel?> showPurchaseFormDialog(
  BuildContext context, {
  required AppLanguage lang,
  required String userId,
  PurchaseModel? purchase,
}) {
  return showDialog<PurchaseModel>(
    context: context,
    builder: (context) => _PurchaseFormDialog(
      lang: lang,
      userId: userId,
      purchase: purchase,
    ),
  );
}

class _PurchaseFormDialog extends StatefulWidget {
  const _PurchaseFormDialog({
    required this.lang,
    required this.userId,
    this.purchase,
  });

  final AppLanguage lang;
  final String userId;
  final PurchaseModel? purchase;

  @override
  State<_PurchaseFormDialog> createState() => _PurchaseFormDialogState();
}

class _PurchaseFormDialogState extends State<_PurchaseFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _sellerNameController;
  late final TextEditingController _cropTypeController;
  late final TextEditingController _quantityController;
  late final TextEditingController _pricePerUnitController;
  late final TextEditingController _notesController;
  late String _unit;
  late DateTime _purchaseDate;

  bool get _isEdit => widget.purchase != null;

  @override
  void initState() {
    super.initState();
    final p = widget.purchase;
    _sellerNameController = TextEditingController(text: p?.sellerName ?? '');
    _cropTypeController = TextEditingController(text: p?.cropType ?? '');
    _quantityController = TextEditingController(
      text: p != null ? p.quantity.toString() : '',
    );
    _pricePerUnitController = TextEditingController(
      text: p != null ? p.pricePerUnit.toString() : '',
    );
    _notesController = TextEditingController(text: p?.notes ?? '');
    _unit = p?.unit ?? _units.first;
    _purchaseDate = p?.purchaseDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _sellerNameController.dispose();
    _cropTypeController.dispose();
    _quantityController.dispose();
    _pricePerUnitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _computedTotal {
    final qty = double.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_pricePerUnitController.text) ?? 0;
    return qty * price;
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final colors = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(_isEdit ? t('edit_purchase', lang) : t('add_purchase', lang)),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: _sellerNameController,
                  label: t('seller_name', lang),
                  prefixIcon: Icons.person,
                  validator: FormValidators.required(lang),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _cropTypeController,
                  label: t('crop_type', lang),
                  prefixIcon: Icons.grass,
                  validator: FormValidators.required(lang),
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
                        onChanged: (_) => setState(() {}),
                        validator: FormValidators.positiveNumber(lang),
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
                AppTextField(
                  controller: _pricePerUnitController,
                  label: t('price_per_unit', lang),
                  prefixIcon: Icons.attach_money,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: FormValidators.positiveNumber(lang),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${t('total_amount', lang)}: P${_computedTotal.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                _DatePickerField(
                  label: t('purchase_date', lang),
                  date: _purchaseDate,
                  colors: colors,
                  onTap: () => _pickDate(context),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _notesController,
                  label: t('notes', lang),
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
            _isEdit ? t('edit_purchase', lang) : t('add_purchase', lang),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _purchaseDate = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final purchase = PurchaseModel(
      id: widget.purchase?.id,
      userId: widget.userId,
      sellerName: _sellerNameController.text.trim(),
      cropType: _cropTypeController.text.trim(),
      quantity: double.parse(_quantityController.text.trim()),
      unit: _unit,
      pricePerUnit: double.parse(_pricePerUnitController.text.trim()),
      totalAmount: _computedTotal,
      purchaseDate: _purchaseDate,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      createdAt: widget.purchase?.createdAt,
      updatedAt: DateTime.now(),
    );

    Navigator.of(context).pop(purchase);
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
