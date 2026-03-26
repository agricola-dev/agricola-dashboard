import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/utils/form_validators.dart';
import 'package:agricola_dashboard/core/widgets/app_dropdown_field.dart';
import 'package:agricola_dashboard/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';

/// Quality assessment options.
const _qualities = ['excellent', 'good', 'fair', 'poor'];

/// Yield units.
const _yieldUnits = ['kg', 'bags', 'tons'];

/// Loss reason options.
const _lossReasons = [
  'pest_damage',
  'disease',
  'drought',
  'flooding',
  'spoilage',
  'other',
];

/// Shows a record harvest dialog. Returns a completed [HarvestModel]
/// on submit, or null if the user cancels.
Future<HarvestModel?> showHarvestFormDialog(
  BuildContext context, {
  required AppLanguage lang,
  required String cropId,
  String defaultYieldUnit = 'kg',
}) {
  return showDialog<HarvestModel>(
    context: context,
    builder: (context) => _HarvestFormDialog(
      lang: lang,
      cropId: cropId,
      defaultYieldUnit: defaultYieldUnit,
    ),
  );
}

class _HarvestFormDialog extends StatefulWidget {
  const _HarvestFormDialog({
    required this.lang,
    required this.cropId,
    required this.defaultYieldUnit,
  });

  final AppLanguage lang;
  final String cropId;
  final String defaultYieldUnit;

  @override
  State<_HarvestFormDialog> createState() => _HarvestFormDialogState();
}

class _HarvestFormDialogState extends State<_HarvestFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _actualYieldController;
  late final TextEditingController _lossAmountController;
  late final TextEditingController _storageLocationController;
  late final TextEditingController _notesController;

  late String _yieldUnit;
  late String _quality;
  String? _lossReason;
  late DateTime _harvestDate;

  @override
  void initState() {
    super.initState();
    _actualYieldController = TextEditingController();
    _lossAmountController = TextEditingController();
    _storageLocationController = TextEditingController();
    _notesController = TextEditingController();
    _yieldUnit = widget.defaultYieldUnit;
    _quality = _qualities[1]; // default to 'good'
    _harvestDate = DateTime.now();
  }

  @override
  void dispose() {
    _actualYieldController.dispose();
    _lossAmountController.dispose();
    _storageLocationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final colors = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(t('record_harvest', lang)),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Harvest date
                _DatePickerField(
                  label: t('harvest_date', lang),
                  date: _harvestDate,
                  colors: colors,
                  onTap: () => _pickDate(context),
                ),
                const SizedBox(height: 16),

                // Actual yield + unit
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: AppTextField(
                        controller: _actualYieldController,
                        label: t('actual_yield', lang),
                        prefixIcon: Icons.scale,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: FormValidators.positiveNumber(lang),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppDropdownField<String>(
                        value: _yieldUnit,
                        items: _yieldUnits,
                        itemLabelBuilder: (u) => u,
                        label: t('unit', lang),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _yieldUnit = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Quality
                AppDropdownField<String>(
                  value: _quality,
                  items: _qualities,
                  itemLabelBuilder: (q) => t(q, lang),
                  label: t('quality_assessment', lang),
                  prefixIcon: Icons.star_outline,
                  onChanged: (value) {
                    if (value != null) setState(() => _quality = value);
                  },
                ),
                const SizedBox(height: 16),

                // Storage location
                AppTextField(
                  controller: _storageLocationController,
                  label: t('storage_location', lang),
                  prefixIcon: Icons.warehouse,
                  validator: FormValidators.required(lang),
                ),
                const SizedBox(height: 16),

                // Loss amount (optional)
                AppTextField(
                  controller: _lossAmountController,
                  label: '${t('loss_amount', lang)} (${t('optional', lang)})',
                  prefixIcon: Icons.trending_down,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: FormValidators.optionalPositiveNumber(lang),
                ),
                const SizedBox(height: 16),

                // Loss reason (optional, shown if loss amount entered)
                AppDropdownField<String?>(
                  value: _lossReason,
                  items: [null, ..._lossReasons],
                  itemLabelBuilder: (r) =>
                      r == null ? '-- ${t('none', lang)} --' : t(r, lang),
                  label:
                      '${t('loss_reason', lang)} (${t('optional', lang)})',
                  prefixIcon: Icons.report_problem_outlined,
                  onChanged: (value) {
                    setState(() => _lossReason = value);
                  },
                ),
                const SizedBox(height: 16),

                // Notes
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
          child: Text(t('record_harvest', lang)),
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _harvestDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _harvestDate = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final lossText = _lossAmountController.text.trim();
    final lossAmount =
        lossText.isNotEmpty ? double.tryParse(lossText) : null;

    final harvest = HarvestModel(
      cropId: widget.cropId,
      harvestDate: _harvestDate,
      actualYield: double.parse(_actualYieldController.text.trim()),
      yieldUnit: _yieldUnit,
      quality: _quality,
      lossAmount: lossAmount,
      lossReason: _lossReason,
      storageLocation: _storageLocationController.text.trim(),
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      createdAt: DateTime.now(),
    );

    Navigator.of(context).pop(harvest);
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
        child: Text(formatCropDate(date)),
      ),
    );
  }
}
