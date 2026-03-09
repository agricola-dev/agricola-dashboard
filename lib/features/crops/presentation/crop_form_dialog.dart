import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/widgets/app_dropdown_field.dart';
import 'package:agricola_dashboard/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';

/// Field size units.
const _fieldSizeUnits = ['hectares', 'acres', 'square_metres'];

/// Yield units.
const _yieldUnits = ['kg', 'bags', 'tons'];

/// Storage methods.
const _storageMethods = [
  'traditional_granary',
  'improved_storage',
  'bags_in_room',
  'open_air',
  'warehouse',
];

/// Shows an add/edit crop dialog. Returns a completed [CropModel]
/// on submit, or null if the user cancels.
Future<CropModel?> showCropFormDialog(
  BuildContext context, {
  required AppLanguage lang,
  List<CropCatalogEntry> catalog = const [],
  CropModel? crop,
}) {
  return showDialog<CropModel>(
    context: context,
    builder: (context) => _CropFormDialog(
      lang: lang,
      catalog: catalog,
      crop: crop,
    ),
  );
}

class _CropFormDialog extends StatefulWidget {
  const _CropFormDialog({
    required this.lang,
    required this.catalog,
    this.crop,
  });

  final AppLanguage lang;
  final List<CropCatalogEntry> catalog;
  final CropModel? crop;

  @override
  State<_CropFormDialog> createState() => _CropFormDialogState();
}

class _CropFormDialogState extends State<_CropFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fieldNameController;
  late final TextEditingController _fieldSizeController;
  late final TextEditingController _estimatedYieldController;
  late final TextEditingController _notesController;

  late String _cropType;
  late String _fieldSizeUnit;
  late String _yieldUnit;
  late String _storageMethod;
  late DateTime _plantingDate;
  late DateTime _expectedHarvestDate;

  bool get _isEdit => widget.crop != null;
  bool get _hasCatalog => widget.catalog.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final crop = widget.crop;
    _fieldNameController =
        TextEditingController(text: crop?.fieldName ?? '');
    _fieldSizeController = TextEditingController(
      text: crop != null ? crop.fieldSize.toString() : '',
    );
    _estimatedYieldController = TextEditingController(
      text: crop != null ? crop.estimatedYield.toString() : '',
    );
    _notesController = TextEditingController(text: crop?.notes ?? '');

    _cropType = crop?.cropType ?? (widget.catalog.isNotEmpty ? widget.catalog.first.key : '');
    _fieldSizeUnit = crop?.fieldSizeUnit ?? _fieldSizeUnits.first;
    _yieldUnit = crop?.yieldUnit ?? _yieldUnits.first;
    _storageMethod = crop?.storageMethod ?? _storageMethods.first;
    _plantingDate = crop?.plantingDate ?? DateTime.now();
    _expectedHarvestDate = crop?.expectedHarvestDate ??
        DateTime.now().add(const Duration(days: 90));
  }

  @override
  void dispose() {
    _fieldNameController.dispose();
    _fieldSizeController.dispose();
    _estimatedYieldController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final colors = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(_isEdit ? t('edit_crop', lang) : t('add_crop', lang)),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Crop type
                if (_hasCatalog)
                  AppDropdownField<String>(
                    value: _cropType.isEmpty ? null : _cropType,
                    items: widget.catalog.map((e) => e.key).toList(),
                    itemLabelBuilder: (key) {
                      final entry = widget.catalog
                          .where((e) => e.key == key)
                          .firstOrNull;
                      return entry?.displayName(lang) ?? key;
                    },
                    label: t('crop_type', lang),
                    prefixIcon: Icons.grass,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _cropType = value;
                        _autoSetHarvestDate(value);
                      });
                    },
                  )
                else
                  AppTextField(
                    controller: TextEditingController(text: _cropType),
                    label: t('crop_type', lang),
                    prefixIcon: Icons.grass,
                    onChanged: (value) => _cropType = value,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return t('field_required', lang);
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 16),

                // Field name
                AppTextField(
                  controller: _fieldNameController,
                  label: t('field_name', lang),
                  prefixIcon: Icons.landscape,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return t('field_required', lang);
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Field size + unit
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: AppTextField(
                        controller: _fieldSizeController,
                        label: t('field_size', lang),
                        prefixIcon: Icons.straighten,
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
                        value: _fieldSizeUnit,
                        items: _fieldSizeUnits,
                        itemLabelBuilder: (u) => t(u, lang),
                        label: t('unit', lang),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _fieldSizeUnit = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Planting date
                _DatePickerField(
                  label: t('planting_date', lang),
                  date: _plantingDate,
                  colors: colors,
                  onTap: () => _pickPlantingDate(context),
                ),
                const SizedBox(height: 16),

                // Expected harvest date
                _DatePickerField(
                  label: t('expected_harvest_date', lang),
                  date: _expectedHarvestDate,
                  colors: colors,
                  onTap: () => _pickHarvestDate(context),
                ),
                const SizedBox(height: 16),

                // Estimated yield + unit
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: AppTextField(
                        controller: _estimatedYieldController,
                        label: t('estimated_yield', lang),
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
          child: Text(
            _isEdit ? t('edit_crop', lang) : t('add_crop', lang),
          ),
        ),
      ],
    );
  }

  /// Auto-set expected harvest date based on catalog harvestDays.
  void _autoSetHarvestDate(String cropKey) {
    final entry =
        widget.catalog.where((e) => e.key == cropKey).firstOrNull;
    if (entry != null) {
      setState(() {
        _expectedHarvestDate =
            _plantingDate.add(Duration(days: entry.harvestDays));
      });
    }
  }

  Future<void> _pickPlantingDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _plantingDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _plantingDate = picked;
        // Recalculate expected harvest if catalog entry exists
        _autoSetHarvestDate(_cropType);
      });
    }
  }

  Future<void> _pickHarvestDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expectedHarvestDate,
      firstDate: _plantingDate,
      lastDate: _plantingDate.add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() => _expectedHarvestDate = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_cropType.trim().isEmpty) return;

    final crop = CropModel(
      id: widget.crop?.id,
      cropType: _cropType.trim(),
      fieldName: _fieldNameController.text.trim(),
      fieldSize: double.parse(_fieldSizeController.text.trim()),
      fieldSizeUnit: _fieldSizeUnit,
      plantingDate: _plantingDate,
      expectedHarvestDate: _expectedHarvestDate,
      estimatedYield: double.parse(_estimatedYieldController.text.trim()),
      yieldUnit: _yieldUnit,
      storageMethod: _storageMethod,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      createdAt: widget.crop?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Navigator.of(context).pop(crop);
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
