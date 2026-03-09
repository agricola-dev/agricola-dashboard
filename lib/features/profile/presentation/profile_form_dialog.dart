import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/widgets/app_dropdown_field.dart';
import 'package:agricola_dashboard/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Location options (shared between farmer village and merchant location)
// ---------------------------------------------------------------------------

const _locations = [
  'Gaborone',
  'Francistown',
  'Maun',
  'Serowe',
  'Molepolole',
  'Kanye',
  'Mochudi',
  'Mahalapye',
  'Palapye',
  'Tlokweng',
  'Ramotswa',
  'Mogoditshane',
  'Gabane',
  'Lobatse',
  'Thamaga',
  'Letlhakane',
  'Tonota',
  'Moshupa',
  'Jwaneng',
  'Ghanzi',
  'Other',
];

const _farmSizes = [
  '< 1 Hectare',
  '1-5 Hectares',
  '5-10 Hectares',
  '10+ Hectares',
];

const _agriShopProducts = [
  'Seeds',
  'Fertiliser',
  'Pesticides',
  'Tools',
  'Machinery',
  'Animal Feed',
  'Irrigation Equipment',
  'Farming Supplies',
];

const _generalProducts = [
  'Grains',
  'Vegetables',
  'Fruits',
  'Livestock Products',
  'Dairy',
  'Poultry',
  'Eggs',
  'Processed Foods',
];

// ---------------------------------------------------------------------------
// Farmer profile form dialog
// ---------------------------------------------------------------------------

/// Shows a dialog to create/edit a farmer profile.
/// Returns the updated [FarmerProfileModel] or null if cancelled.
Future<FarmerProfileModel?> showFarmerProfileFormDialog(
  BuildContext context, {
  required AppLanguage lang,
  required String userId,
  FarmerProfileModel? profile,
}) {
  return showDialog<FarmerProfileModel>(
    context: context,
    builder: (context) => _FarmerProfileForm(
      lang: lang,
      userId: userId,
      profile: profile,
    ),
  );
}

class _FarmerProfileForm extends StatefulWidget {
  const _FarmerProfileForm({
    required this.lang,
    required this.userId,
    this.profile,
  });

  final AppLanguage lang;
  final String userId;
  final FarmerProfileModel? profile;

  @override
  State<_FarmerProfileForm> createState() => _FarmerProfileFormState();
}

class _FarmerProfileFormState extends State<_FarmerProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late String _village;
  late String _customVillage;
  late String _farmSize;
  late List<String> _primaryCrops;

  bool get _isEditing => widget.profile != null;

  @override
  void initState() {
    super.initState();
    _village = widget.profile?.village ?? '';
    _customVillage = widget.profile?.customVillage ?? '';
    _farmSize = widget.profile?.farmSize ?? '';
    _primaryCrops = List.of(widget.profile?.primaryCrops ?? []);
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final isOtherVillage = _village == 'Other';

    return AlertDialog(
      title: Text(
        _isEditing ? t('edit_profile', lang) : t('complete_profile', lang),
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppDropdownField<String>(
                  label: t('village', lang),
                  value: _village.isEmpty ? null : _village,
                  items: _locations,
                  itemLabelBuilder: (v) => v,
                  onChanged: (v) => setState(() => _village = v ?? ''),
                  validator: ProfileValidators.validateVillage,
                ),
                if (isOtherVillage) ...[
                  const SizedBox(height: 16),
                  AppTextField(
                    label: t('village', lang),
                    initialValue: _customVillage,
                    onChanged: (v) => _customVillage = v,
                    validator: ProfileValidators.validateVillage,
                  ),
                ],
                const SizedBox(height: 16),
                AppDropdownField<String>(
                  label: t('farm_size', lang),
                  value: _farmSize.isEmpty ? null : _farmSize,
                  items: _farmSizes,
                  itemLabelBuilder: (v) => v,
                  onChanged: (v) => setState(() => _farmSize = v ?? ''),
                  validator: (v) =>
                      v == null || v.isEmpty ? t('required', lang) : null,
                ),
                const SizedBox(height: 16),
                Text(
                  t('primary_crops', lang),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                _CropChipsSelector(
                  selected: _primaryCrops,
                  onChanged: (crops) =>
                      setState(() => _primaryCrops = crops),
                ),
                if (ProfileValidators.validateCrops(_primaryCrops) != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      ProfileValidators.validateCrops(_primaryCrops)!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (ProfileValidators.validateCrops(_primaryCrops) != null) return;

    final now = DateTime.now();
    final result = FarmerProfileModel(
      id: widget.profile?.id ?? '',
      userId: widget.userId,
      village: _village,
      customVillage: _village == 'Other' ? _customVillage : null,
      primaryCrops: _primaryCrops,
      farmSize: _farmSize,
      photoUrl: widget.profile?.photoUrl,
      createdAt: widget.profile?.createdAt ?? now,
      updatedAt: now,
    );

    Navigator.of(context).pop(result);
  }
}

// ---------------------------------------------------------------------------
// Merchant profile form dialog
// ---------------------------------------------------------------------------

/// Shows a dialog to create/edit a merchant profile.
/// Returns the updated [MerchantProfileModel] or null if cancelled.
Future<MerchantProfileModel?> showMerchantProfileFormDialog(
  BuildContext context, {
  required AppLanguage lang,
  required String userId,
  MerchantType? merchantType,
  MerchantProfileModel? profile,
}) {
  return showDialog<MerchantProfileModel>(
    context: context,
    builder: (context) => _MerchantProfileForm(
      lang: lang,
      userId: userId,
      merchantType: merchantType,
      profile: profile,
    ),
  );
}

class _MerchantProfileForm extends StatefulWidget {
  const _MerchantProfileForm({
    required this.lang,
    required this.userId,
    this.merchantType,
    this.profile,
  });

  final AppLanguage lang;
  final String userId;
  final MerchantType? merchantType;
  final MerchantProfileModel? profile;

  @override
  State<_MerchantProfileForm> createState() => _MerchantProfileFormState();
}

class _MerchantProfileFormState extends State<_MerchantProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late String _businessName;
  late MerchantType _merchantType;
  late String _location;
  late String _customLocation;
  late List<String> _productsOffered;

  bool get _isEditing => widget.profile != null;

  List<String> get _productOptions =>
      _merchantType == MerchantType.agriShop
          ? _agriShopProducts
          : _generalProducts;

  @override
  void initState() {
    super.initState();
    _businessName = widget.profile?.businessName ?? '';
    _merchantType = widget.profile?.merchantType ??
        widget.merchantType ??
        MerchantType.agriShop;
    _location = widget.profile?.location ?? '';
    _customLocation = widget.profile?.customLocation ?? '';
    _productsOffered = List.of(widget.profile?.productsOffered ?? []);
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final isOtherLocation = _location == 'Other';

    return AlertDialog(
      title: Text(
        _isEditing ? t('edit_profile', lang) : t('complete_profile', lang),
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  label: t('business_name', lang),
                  initialValue: _businessName,
                  onChanged: (v) => _businessName = v,
                  validator: ProfileValidators.validateBusinessName,
                ),
                const SizedBox(height: 16),
                AppDropdownField<MerchantType>(
                  label: t('merchant_type', lang),
                  value: _merchantType,
                  items: MerchantType.values,
                  itemLabelBuilder: (v) => v.displayName,
                  onChanged: (v) => setState(() {
                    _merchantType = v ?? MerchantType.agriShop;
                    // Reset products when type changes
                    _productsOffered.clear();
                  }),
                ),
                const SizedBox(height: 16),
                AppDropdownField<String>(
                  label: t('location', lang),
                  value: _location.isEmpty ? null : _location,
                  items: _locations,
                  itemLabelBuilder: (v) => v,
                  onChanged: (v) => setState(() => _location = v ?? ''),
                  validator: ProfileValidators.validateVillage,
                ),
                if (isOtherLocation) ...[
                  const SizedBox(height: 16),
                  AppTextField(
                    label: t('location', lang),
                    initialValue: _customLocation,
                    onChanged: (v) => _customLocation = v,
                    validator: ProfileValidators.validateVillage,
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  t('products_offered', lang),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                _ProductChipsSelector(
                  options: _productOptions,
                  selected: _productsOffered,
                  onChanged: (products) =>
                      setState(() => _productsOffered = products),
                ),
                if (_productsOffered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      t('required', lang),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_productsOffered.isEmpty) return;

    final now = DateTime.now();
    final result = MerchantProfileModel(
      id: widget.profile?.id ?? '',
      userId: widget.userId,
      merchantType: _merchantType,
      businessName: _businessName,
      location: _location,
      customLocation: _location == 'Other' ? _customLocation : null,
      productsOffered: _productsOffered,
      photoUrl: widget.profile?.photoUrl,
      createdAt: widget.profile?.createdAt ?? now,
      updatedAt: now,
    );

    Navigator.of(context).pop(result);
  }
}

// ---------------------------------------------------------------------------
// Multi-select chip selectors
// ---------------------------------------------------------------------------

// Common crop options for farmer primary crops
const _cropOptions = [
  'Maize',
  'Sorghum',
  'Millet',
  'Beans',
  'Groundnuts',
  'Sunflower',
  'Watermelon',
  'Sweet Reed',
  'Cowpeas',
  'Vegetables',
];

class _CropChipsSelector extends StatelessWidget {
  const _CropChipsSelector({
    required this.selected,
    required this.onChanged,
  });

  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _cropOptions.map((crop) {
        final isSelected = selected.contains(crop);
        return FilterChip(
          label: Text(crop),
          selected: isSelected,
          onSelected: (checked) {
            final updated = List<String>.from(selected);
            if (checked) {
              if (updated.length < ValidationRules.maxPrimaryCropsCount) {
                updated.add(crop);
              }
            } else {
              updated.remove(crop);
            }
            onChanged(updated);
          },
        );
      }).toList(),
    );
  }
}

class _ProductChipsSelector extends StatelessWidget {
  const _ProductChipsSelector({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((product) {
        final isSelected = selected.contains(product);
        return FilterChip(
          label: Text(product),
          selected: isSelected,
          onSelected: (checked) {
            final updated = List<String>.from(selected);
            if (checked) {
              updated.add(product);
            } else {
              updated.remove(product);
            }
            onChanged(updated);
          },
        );
      }).toList(),
    );
  }
}
