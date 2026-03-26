import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/utils/form_validators.dart';
import 'package:agricola_dashboard/core/widgets/app_dropdown_field.dart';
import 'package:agricola_dashboard/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';

/// Suggested categories for marketplace listings.
const _categories = [
  'Vegetables',
  'Fruits',
  'Grains',
  'Livestock',
  'Seeds',
  'Fertilizer',
  'Tools',
  'Other',
];

/// Shows an add/edit marketplace listing dialog. Returns a completed
/// [MarketplaceListing] on submit, or null if the user cancels.
///
/// When [inventoryItem] is provided the form is pre-filled from inventory data.
Future<MarketplaceListing?> showMarketplaceFormDialog(
  BuildContext context, {
  required AppLanguage lang,
  required String sellerId,
  required String sellerName,
  MarketplaceListing? listing,
  InventoryModel? inventoryItem,
}) {
  return showDialog<MarketplaceListing>(
    context: context,
    builder: (context) => _MarketplaceFormDialog(
      lang: lang,
      sellerId: sellerId,
      sellerName: sellerName,
      listing: listing,
      inventoryItem: inventoryItem,
    ),
  );
}

class _MarketplaceFormDialog extends StatefulWidget {
  const _MarketplaceFormDialog({
    required this.lang,
    required this.sellerId,
    required this.sellerName,
    this.listing,
    this.inventoryItem,
  });

  final AppLanguage lang;
  final String sellerId;
  final String sellerName;
  final MarketplaceListing? listing;
  final InventoryModel? inventoryItem;

  @override
  State<_MarketplaceFormDialog> createState() => _MarketplaceFormDialogState();
}

class _MarketplaceFormDialogState extends State<_MarketplaceFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;
  late final TextEditingController _priceController;
  late final TextEditingController _unitController;
  late final TextEditingController _quantityController;
  late final TextEditingController _locationController;
  late ListingType _type;
  CropStatus? _cropStatus;
  String? _harvestDate;
  String? _inventoryId;

  bool get _isEdit => widget.listing != null;

  @override
  void initState() {
    super.initState();
    final listing = widget.listing;
    final inv = widget.inventoryItem;

    // Pre-fill from existing listing or inventory item
    _titleController = TextEditingController(
      text: listing?.title ?? inv?.cropType ?? '',
    );
    _descriptionController = TextEditingController(
      text: listing?.description ?? '',
    );
    _categoryController = TextEditingController(
      text: listing?.category ?? inv?.cropType ?? '',
    );
    _priceController = TextEditingController(
      text: listing?.price?.toString() ?? '',
    );
    _unitController = TextEditingController(
      text: listing?.unit ?? inv?.unit ?? '',
    );
    _quantityController = TextEditingController(
      text: listing?.quantity ?? inv?.quantity.toString() ?? '',
    );
    _locationController = TextEditingController(
      text: listing?.location ?? inv?.storageLocation ?? '',
    );
    _type = listing?.type ?? (inv != null ? ListingType.produce : ListingType.produce);
    _cropStatus = listing?.status;
    _harvestDate = listing?.harvestDate;
    _inventoryId = listing?.inventoryId ?? inv?.id;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;

    return AlertDialog(
      title: Text(_isEdit ? t('edit_listing', lang) : t('add_listing', lang)),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: _titleController,
                  label: t('listing_title', lang),
                  prefixIcon: Icons.title,
                  validator: FormValidators.required(lang),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _descriptionController,
                  label: t('listing_description', lang),
                  prefixIcon: Icons.description,
                  maxLines: 3,
                  validator: FormValidators.required(lang),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppDropdownField<ListingType>(
                        value: _type,
                        items: ListingType.values,
                        itemLabelBuilder: (type) => t(type.name, lang),
                        label: t('listing_type', lang),
                        prefixIcon: Icons.category,
                        onChanged: (value) {
                          if (value != null) setState(() => _type = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppDropdownField<String>(
                        value: _categories.contains(_categoryController.text)
                            ? _categoryController.text
                            : null,
                        items: _categories,
                        itemLabelBuilder: (c) => c,
                        label: t('listing_category', lang),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _categoryController.text = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: AppTextField(
                        controller: _priceController,
                        label: t('listing_price', lang),
                        prefixIcon: Icons.attach_money,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: FormValidators.optionalPositiveNumber(lang),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _unitController,
                        label: t('unit', lang),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _quantityController,
                        label: t('listing_quantity', lang),
                        prefixIcon: Icons.scale,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _locationController,
                        label: t('listing_location', lang),
                        prefixIcon: Icons.location_on,
                        validator: FormValidators.required(lang),
                      ),
                    ),
                  ],
                ),
                // Produce-specific fields
                if (_type == ListingType.produce) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AppDropdownField<CropStatus>(
                          value: _cropStatus,
                          items: CropStatus.values,
                          itemLabelBuilder: (s) => t(s.name, lang),
                          label: t('crop_status', lang),
                          prefixIcon: Icons.eco,
                          onChanged: (value) {
                            setState(() => _cropStatus = value);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DatePickerField(
                          label: t('harvest_date', lang),
                          date: _harvestDate,
                          onTap: () => _pickHarvestDate(context),
                        ),
                      ),
                    ],
                  ),
                ],
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
            _isEdit ? t('edit_listing', lang) : t('add_listing', lang),
          ),
        ),
      ],
    );
  }

  Future<void> _pickHarvestDate(BuildContext context) async {
    final initial = _harvestDate != null
        ? DateTime.tryParse(_harvestDate!) ?? DateTime.now()
        : DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _harvestDate =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final priceText = _priceController.text.trim();
    final listing = MarketplaceListing(
      id: widget.listing?.id ?? '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      type: _type,
      category: _categoryController.text.trim(),
      price: priceText.isNotEmpty ? double.tryParse(priceText) : null,
      unit: _unitController.text.trim().isNotEmpty
          ? _unitController.text.trim()
          : null,
      sellerName: widget.sellerName,
      sellerId: widget.sellerId,
      location: _locationController.text.trim(),
      status: _type == ListingType.produce ? _cropStatus : null,
      harvestDate: _type == ListingType.produce ? _harvestDate : null,
      quantity: _quantityController.text.trim().isNotEmpty
          ? _quantityController.text.trim()
          : null,
      inventoryId: _inventoryId,
      createdAt: widget.listing?.createdAt,
      imagePath: widget.listing?.imagePath,
      additionalImages: widget.listing?.additionalImages,
      sellerPhone: widget.listing?.sellerPhone,
      sellerEmail: widget.listing?.sellerEmail,
    );

    Navigator.of(context).pop(listing);
  }
}

/// A tappable date display field matching input decoration style.
class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final String? date;
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
        child: Text(date ?? '—'),
      ),
    );
  }
}
