import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/widgets/app_dropdown_field.dart';
import 'package:agricola_dashboard/core/widgets/app_text_field.dart';
import 'package:agricola_dashboard/core/widgets/labeled_divider.dart';
import 'package:flutter/material.dart';

const _stages = ['field', 'transport', 'storage', 'processing'];
const _units = ['kg', 'bags', 'tons'];
const _storageMethods = [
  'traditional_granary',
  'improved_storage',
  'bags_in_room',
  'open_air',
  'warehouse',
];
const _cropCategories = ['cereals', 'vegetables', 'fruits', 'legumes', 'roots_tubers'];

/// Shows a form dialog for creating a new loss calculation.
/// Returns a [LossCalculation] on submit, or null if cancelled.
Future<LossCalculation?> showLossCalculatorFormDialog(
  BuildContext context, {
  required AppLanguage lang,
}) {
  return showDialog<LossCalculation>(
    context: context,
    builder: (context) => _LossCalculatorFormDialog(lang: lang),
  );
}

class _LossCalculatorFormDialog extends StatefulWidget {
  const _LossCalculatorFormDialog({required this.lang});

  final AppLanguage lang;

  @override
  State<_LossCalculatorFormDialog> createState() =>
      _LossCalculatorFormDialogState();
}

class _LossCalculatorFormDialogState extends State<_LossCalculatorFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _cropTypeController;
  late final TextEditingController _harvestAmountController;
  late final TextEditingController _marketPriceController;

  String _cropCategory = _cropCategories.first;
  String _unit = _units.first;
  String _storageMethod = _storageMethods.first;

  final List<_LossStageEntry> _stageEntries = [];

  @override
  void initState() {
    super.initState();
    _cropTypeController = TextEditingController();
    _harvestAmountController = TextEditingController();
    _marketPriceController = TextEditingController();
    _stageEntries.add(_LossStageEntry());
  }

  @override
  void dispose() {
    _cropTypeController.dispose();
    _harvestAmountController.dispose();
    _marketPriceController.dispose();
    for (final entry in _stageEntries) {
      entry.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;

    return AlertDialog(
      title: Text(t('add_calculation', lang)),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Crop type
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

                // Crop category
                AppDropdownField<String>(
                  value: _cropCategory,
                  items: _cropCategories,
                  itemLabelBuilder: (c) => t(c, lang),
                  label: t('crop_category', lang),
                  prefixIcon: Icons.category,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _cropCategory = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Harvest amount + unit
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: AppTextField(
                        controller: _harvestAmountController,
                        label: t('harvest_amount', lang),
                        prefixIcon: Icons.scale,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return t('field_required', lang);
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
                          if (value != null) {
                            setState(() => _unit = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Market price per unit
                AppTextField(
                  controller: _marketPriceController,
                  label: t('market_price_per_unit', lang),
                  prefixIcon: Icons.payments,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return t('field_required', lang);
                    }
                    final parsed = double.tryParse(value);
                    if (parsed == null || parsed <= 0) {
                      return t('quantity_invalid', lang);
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Storage method
                AppDropdownField<String>(
                  value: _storageMethod,
                  items: _storageMethods,
                  itemLabelBuilder: (m) => t(m, lang),
                  label: t('storage_method', lang),
                  prefixIcon: Icons.warehouse,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _storageMethod = value);
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Loss stages section
                LabeledDivider(label: t('loss_by_stage', lang)),
                const SizedBox(height: 12),

                ..._stageEntries.asMap().entries.map((mapEntry) {
                  final index = mapEntry.key;
                  final entry = mapEntry.value;
                  return _buildStageRow(entry, index, lang);
                }),
                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _stageEntries.add(_LossStageEntry()));
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(t('add_stage', lang)),
                  ),
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
          child: Text(t('save', lang)),
        ),
      ],
    );
  }

  Widget _buildStageRow(_LossStageEntry entry, int index, AppLanguage lang) {
    final causes = lossCausesPerStage[entry.stage] ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              // Stage dropdown
              Expanded(
                child: AppDropdownField<String>(
                  value: entry.stage,
                  items: _stages,
                  itemLabelBuilder: (s) => t('loss_stage_$s', lang),
                  label: t('loss_by_stage', lang),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        entry.stage = value;
                        // Reset cause when stage changes
                        final newCauses = lossCausesPerStage[value] ?? [];
                        entry.cause =
                            newCauses.isNotEmpty ? newCauses.first : null;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Amount lost
              Expanded(
                child: AppTextField(
                  controller: entry.amountController,
                  label: t('loss_amount', lang),
                  prefixIcon: Icons.scale,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return t('field_required', lang);
                    }
                    final parsed = double.tryParse(value);
                    if (parsed == null || parsed < 0) {
                      return t('quantity_invalid', lang);
                    }
                    return null;
                  },
                ),
              ),
              // Remove button
              if (_stageEntries.length > 1)
                IconButton(
                  icon: Icon(
                    Icons.remove_circle_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () {
                    setState(() {
                      _stageEntries[index].dispose();
                      _stageEntries.removeAt(index);
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Cause dropdown
          if (causes.isNotEmpty)
            AppDropdownField<String>(
              value: entry.cause ?? causes.first,
              items: causes,
              itemLabelBuilder: (c) => t(c, lang),
              label: t('loss_cause', lang),
              onChanged: (value) {
                if (value != null) {
                  setState(() => entry.cause = value);
                }
              },
            ),
        ],
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final stages = _stageEntries.map((entry) {
      return LossStage(
        stage: entry.stage,
        amount: double.parse(entry.amountController.text.trim()),
        cause: entry.cause,
      );
    }).toList();

    final calculation = LossCalculation(
      cropType: _cropTypeController.text.trim(),
      cropCategory: _cropCategory,
      harvestAmount: double.parse(_harvestAmountController.text.trim()),
      unit: _unit,
      marketPricePerUnit: double.parse(_marketPriceController.text.trim()),
      storageMethod: _storageMethod,
      stages: stages,
      calculationDate: DateTime.now(),
    );

    Navigator.of(context).pop(calculation);
  }
}

/// Mutable state for a single loss stage row in the form.
class _LossStageEntry {
  String stage = _stages.first;
  final TextEditingController amountController = TextEditingController();
  String? cause;

  _LossStageEntry() {
    final causes = lossCausesPerStage[stage] ?? [];
    cause = causes.isNotEmpty ? causes.first : null;
  }

  void dispose() {
    amountController.dispose();
  }
}
