import 'package:flutter/material.dart';

/// Generic reusable dropdown field with consistent styling.
///
/// Works with any type [T] — uses [itemLabelBuilder] to render labels,
/// so it has no dependency on the data format.
class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.items,
    required this.itemLabelBuilder,
    this.value,
    this.label,
    this.hint,
    this.onChanged,
    this.validator,
    this.prefixIcon,
  });

  final T? value;
  final List<T> items;
  final String Function(T) itemLabelBuilder;
  final String? label;
  final String? hint;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(itemLabelBuilder(item)),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      ),
    );
  }
}
