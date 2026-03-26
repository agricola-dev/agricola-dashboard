import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/providers/language_provider.dart';
import 'package:agricola_dashboard/core/widgets/app_text_field.dart';
import 'package:agricola_dashboard/features/auth/providers/auth_providers.dart';
import 'package:agricola_dashboard/core/providers/pagination_provider.dart';
import 'package:agricola_dashboard/core/widgets/table_pagination_bar.dart';
import 'package:agricola_dashboard/features/inventory/presentation/inventory_form_dialog.dart';
import 'package:agricola_dashboard/features/inventory/presentation/widgets/condition_badge.dart';
import 'package:agricola_dashboard/features/inventory/providers/inventory_providers.dart';
import 'package:agricola_dashboard/features/marketplace/presentation/marketplace_form_dialog.dart';
import 'package:agricola_dashboard/features/marketplace/providers/marketplace_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final filteredAsync = ref.watch(filteredInventoryProvider);
    final sort = ref.watch(inventorySortProvider);

    return filteredAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorView(
        message: error.toString(),
        onRetry: () => ref.invalidate(inventoryControllerProvider),
        lang: lang,
      ),
      data: (items) => _InventoryContent(
        items: items,
        sort: sort,
        lang: lang,
      ),
    );
  }
}

class _InventoryContent extends ConsumerWidget {
  const _InventoryContent({
    required this.items,
    required this.sort,
    required this.lang,
  });

  final List<InventoryModel> items;
  final InventorySort sort;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final pagination = ref.watch(paginationProvider('inventory'));
    final pageItems = paginateList(items, pagination);
    final selectedIds = ref.watch(selectedInventoryIdsProvider);

    // Clear selection and reset page on search/sort/page changes.
    ref.listen(inventorySearchProvider, (_, __) {
      ref.read(selectedInventoryIdsProvider.notifier).state = {};
      ref.read(paginationProvider('inventory').notifier).state =
          ref.read(paginationProvider('inventory')).copyWith(currentPage: 0);
    });
    ref.listen(inventorySortProvider, (_, __) {
      ref.read(selectedInventoryIdsProvider.notifier).state = {};
      ref.read(paginationProvider('inventory').notifier).state =
          ref.read(paginationProvider('inventory')).copyWith(currentPage: 0);
    });
    ref.listen(paginationProvider('inventory'), (prev, next) {
      if (prev?.currentPage != next.currentPage) {
        ref.read(selectedInventoryIdsProvider.notifier).state = {};
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          _buildHeader(context, ref, textTheme, colors),
          const SizedBox(height: 24),
          // Bulk action bar
          if (selectedIds.isNotEmpty) ...[
            _BulkActionBar(
              selectedCount: selectedIds.length,
              lang: lang,
              onDelete: () => _bulkDelete(context, ref, selectedIds),
              onUpdateCondition: (condition) =>
                  _bulkUpdateCondition(context, ref, selectedIds, condition),
              onClear: () =>
                  ref.read(selectedInventoryIdsProvider.notifier).state = {},
            ),
            const SizedBox(height: 12),
          ],
          // Table or empty state
          if (items.isEmpty)
            _EmptyState(lang: lang, onAdd: () => _addItem(context, ref))
          else ...[
            _buildTable(context, ref, colors, pageItems, selectedIds),
            const SizedBox(height: 16),
            TablePaginationBar(
              totalItems: items.length,
              pagination: pagination,
              onPageChanged: (page) =>
                  ref.read(paginationProvider('inventory').notifier).state =
                      pagination.copyWith(currentPage: page),
              onRowsPerPageChanged: (rows) =>
                  ref.read(paginationProvider('inventory').notifier).state =
                      const PaginationState().copyWith(rowsPerPage: rows),
              lang: lang,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    TextTheme textTheme,
    ColorScheme colors,
  ) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Title + count
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t('inventory', lang),
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Chip(
              label: Text('${items.length}'),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        // Search + Add button
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 260,
              child: AppTextField(
                label: t('search', lang),
                prefixIcon: Icons.search,
                onChanged: (value) =>
                    ref.read(inventorySearchProvider.notifier).state = value,
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () => _addItem(context, ref),
              icon: const Icon(Icons.add),
              label: Text(t('add_inventory', lang)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTable(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colors,
    List<InventoryModel> pageItems,
    Set<String> selectedIds,
  ) {
    final allPageIds = pageItems
        .where((item) => item.id != null)
        .map((item) => item.id!)
        .toSet();
    return SizedBox(
      width: double.infinity,
      child: DataTable(
        sortColumnIndex: sort.field.index,
        sortAscending: sort.ascending,
        headingRowColor: WidgetStateProperty.all(
          colors.surfaceContainerLow,
        ),
        onSelectAll: (selected) {
          if (selected == true) {
            ref.read(selectedInventoryIdsProvider.notifier).state =
                {...selectedIds, ...allPageIds};
          } else {
            ref.read(selectedInventoryIdsProvider.notifier).state =
                selectedIds.difference(allPageIds);
          }
        },
        columns: [
          DataColumn(
            label: Text(t('crop_type', lang)),
            onSort: (_, ascending) =>
                _onSort(ref, InventorySortField.cropType, ascending),
          ),
          DataColumn(
            label: Text(t('quantity', lang)),
            numeric: true,
            onSort: (_, ascending) =>
                _onSort(ref, InventorySortField.quantity, ascending),
          ),
          DataColumn(label: Text(t('unit', lang))),
          DataColumn(label: Text(t('condition', lang))),
          DataColumn(label: Text(t('storage_location', lang))),
          DataColumn(
            label: Text(t('days_in_storage', lang)),
            numeric: true,
            onSort: (_, ascending) =>
                _onSort(ref, InventorySortField.storageDate, ascending),
          ),
          DataColumn(label: Text(t('actions', lang))),
        ],
        rows: pageItems
            .map((item) =>
                _buildRow(context, ref, item, colors, selectedIds))
            .toList(),
      ),
    );
  }

  DataRow _buildRow(
    BuildContext context,
    WidgetRef ref,
    InventoryModel item,
    ColorScheme colors,
    Set<String> selectedIds,
  ) {
    final daysInStorage = DateTime.now().difference(item.storageDate).inDays;
    final isSelected = item.id != null && selectedIds.contains(item.id);

    return DataRow(
      selected: isSelected,
      onSelectChanged: item.id == null
          ? null
          : (selected) {
              final current =
                  ref.read(selectedInventoryIdsProvider.notifier).state;
              if (selected == true) {
                ref.read(selectedInventoryIdsProvider.notifier).state = {
                  ...current,
                  item.id!
                };
              } else {
                ref.read(selectedInventoryIdsProvider.notifier).state =
                    current.difference({item.id!});
              }
            },
      cells: [
        DataCell(Text(item.cropType)),
        DataCell(Text(item.quantity.toStringAsFixed(1))),
        DataCell(Text(item.unit)),
        DataCell(ConditionBadge(condition: item.condition, lang: lang)),
        DataCell(Text(item.storageLocation)),
        DataCell(Text('$daysInStorage')),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.storefront_outlined, size: 20),
                tooltip: t('list_on_marketplace', lang),
                onPressed: () => _listOnMarketplace(context, ref, item),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: t('edit_inventory', lang),
                onPressed: () => _editItem(context, ref, item),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 20,
                    color: colors.error),
                tooltip: t('delete_inventory', lang),
                onPressed: () => _deleteItem(context, ref, item),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onSort(WidgetRef ref, InventorySortField field, bool ascending) {
    ref.read(inventorySortProvider.notifier).state = InventorySort(
      field: field,
      ascending: ascending,
    );
  }

  Future<void> _listOnMarketplace(
    BuildContext context,
    WidgetRef ref,
    InventoryModel item,
  ) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final result = await showMarketplaceFormDialog(
      context,
      lang: lang,
      sellerId: user.uid,
      sellerName: user.email,
      inventoryItem: item,
    );
    if (result == null || !context.mounted) return;

    final error = await ref
        .read(myListingsControllerProvider.notifier)
        .createListing(result);

    if (!context.mounted) return;
    _showResultSnackBar(
      context,
      error: error,
      successKey: 'listed_on_marketplace',
      lang: lang,
    );
  }

  Future<void> _addItem(BuildContext context, WidgetRef ref) async {
    final lang = ref.read(languageProvider);
    final result = await showInventoryFormDialog(context, lang: lang);
    if (result == null || !context.mounted) return;

    final error = await ref
        .read(inventoryControllerProvider.notifier)
        .addInventory(result);

    if (!context.mounted) return;
    _showResultSnackBar(
      context,
      error: error,
      successKey: 'inventory_added',
      lang: lang,
    );
  }

  Future<void> _editItem(
    BuildContext context,
    WidgetRef ref,
    InventoryModel item,
  ) async {
    final lang = ref.read(languageProvider);
    final result = await showInventoryFormDialog(context, lang: lang, item: item);
    if (result == null || !context.mounted) return;

    final error = await ref
        .read(inventoryControllerProvider.notifier)
        .updateInventory(item.id!, result);

    if (!context.mounted) return;
    _showResultSnackBar(
      context,
      error: error,
      successKey: 'inventory_updated',
      lang: lang,
    );
  }

  Future<void> _deleteItem(
    BuildContext context,
    WidgetRef ref,
    InventoryModel item,
  ) async {
    final lang = ref.read(languageProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('delete_inventory', lang)),
        content: Text(t('delete_inventory_confirm', lang)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t('cancel', lang)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t('delete', lang)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final error = await ref
        .read(inventoryControllerProvider.notifier)
        .deleteInventory(item.id!);

    if (!context.mounted) return;
    _showResultSnackBar(
      context,
      error: error,
      successKey: 'inventory_deleted',
      lang: lang,
    );
  }

  Future<void> _bulkDelete(
    BuildContext context,
    WidgetRef ref,
    Set<String> selectedIds,
  ) async {
    final lang = ref.read(languageProvider);
    final count = selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('bulk_delete', lang)),
        content: Text(
          t('bulk_delete_confirm', lang)
              .replaceAll('{count}', count.toString()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t('cancel', lang)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t('delete', lang)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final error = await ref
        .read(inventoryControllerProvider.notifier)
        .bulkDeleteInventory(selectedIds.toList());

    ref.read(selectedInventoryIdsProvider.notifier).state = {};

    if (!context.mounted) return;
    _showResultSnackBar(
      context,
      error: error,
      successMessage: t('bulk_delete_success', lang)
          .replaceAll('{count}', count.toString()),
      lang: lang,
    );
  }

  Future<void> _bulkUpdateCondition(
    BuildContext context,
    WidgetRef ref,
    Set<String> selectedIds,
    String condition,
  ) async {
    final lang = ref.read(languageProvider);
    final count = selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('bulk_update_condition', lang)),
        content: Text(
          t('bulk_update_condition_confirm', lang)
              .replaceAll('{count}', count.toString())
              .replaceAll('{condition}', condition),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t('cancel', lang)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t('bulk_update_condition', lang)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final error = await ref
        .read(inventoryControllerProvider.notifier)
        .bulkUpdateCondition(selectedIds.toList(), condition);

    ref.read(selectedInventoryIdsProvider.notifier).state = {};

    if (!context.mounted) return;
    _showResultSnackBar(
      context,
      error: error,
      successMessage: t('bulk_update_success', lang)
          .replaceAll('{count}', count.toString()),
      lang: lang,
    );
  }

  void _showResultSnackBar(
    BuildContext context, {
    required String? error,
    String? successKey,
    String? successMessage,
    required AppLanguage lang,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    if (error != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } else {
      final message = successMessage ?? t(successKey!, lang);
      messenger.showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Bulk action bar
// ---------------------------------------------------------------------------

class _BulkActionBar extends StatelessWidget {
  const _BulkActionBar({
    required this.selectedCount,
    required this.lang,
    required this.onDelete,
    required this.onUpdateCondition,
    required this.onClear,
  });

  final int selectedCount;
  final AppLanguage lang;
  final VoidCallback onDelete;
  final ValueChanged<String> onUpdateCondition;
  final VoidCallback onClear;

  static const _conditions = [
    'excellent',
    'good',
    'fair',
    'needs_attention',
    'critical',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Text(
            '$selectedCount ${t('items_selected', lang)}',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onClear,
            child: Text(t('cancel', lang)),
          ),
          const Spacer(),
          PopupMenuButton<String>(
            tooltip: t('bulk_update_condition', lang),
            onSelected: onUpdateCondition,
            itemBuilder: (_) => _conditions
                .map((c) => PopupMenuItem(
                      value: c,
                      child: ConditionBadge(condition: c, lang: lang),
                    ))
                .toList(),
            child: IgnorePointer(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.sync, size: 18),
                label: Text(t('bulk_update_condition', lang)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: colors.error,
            ),
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: Text(t('bulk_delete', lang)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.lang, required this.onAdd});

  final AppLanguage lang;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: colors.outline),
            const SizedBox(height: 16),
            Text(
              t('no_inventory', lang),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              t('add_inventory_hint', lang),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(t('add_inventory', lang)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error view with retry
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.lang,
  });

  final String message;
  final VoidCallback onRetry;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: colors.error),
          const SizedBox(height: 16),
          Text(
            t('error_loading_inventory', lang),
            style: TextStyle(color: colors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(t('retry', lang)),
          ),
        ],
      ),
    );
  }
}
