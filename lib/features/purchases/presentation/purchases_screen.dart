import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/providers/language_provider.dart';
import 'package:agricola_dashboard/core/widgets/app_text_field.dart';
import 'package:agricola_dashboard/core/widgets/stat_card.dart';
import 'package:agricola_dashboard/features/auth/providers/auth_providers.dart';
import 'package:agricola_dashboard/features/purchases/presentation/purchase_form_dialog.dart';
import 'package:agricola_dashboard/features/purchases/providers/purchases_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class PurchasesScreen extends ConsumerWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final filteredAsync = ref.watch(filteredPurchasesProvider);
    final sort = ref.watch(purchasesSortProvider);

    return filteredAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorView(
        message: error.toString(),
        onRetry: () => ref.invalidate(purchasesControllerProvider),
        lang: lang,
      ),
      data: (purchases) => _PurchasesContent(
        purchases: purchases,
        sort: sort,
        lang: lang,
      ),
    );
  }
}

class _PurchasesContent extends ConsumerWidget {
  const _PurchasesContent({
    required this.purchases,
    required this.sort,
    required this.lang,
  });

  final List<PurchaseModel> purchases;
  final PurchaseSort sort;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, ref, textTheme, colors),
          const SizedBox(height: 24),
          _buildStatsGrid(context, ref),
          const SizedBox(height: 24),
          if (purchases.isEmpty)
            _EmptyState(lang: lang, onAdd: () => _addPurchase(context, ref))
          else
            _buildTable(context, ref, colors),
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
              t('purchases', lang),
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Chip(
              label: Text('${purchases.length}'),
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
                    ref.read(purchasesSearchProvider.notifier).state = value,
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () => _addPurchase(context, ref),
              icon: const Icon(Icons.add),
              label: Text(t('add_purchase', lang)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(purchaseSummaryStatsProvider);

    return statsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (stats) {
        if (stats.totalCount == 0) return const SizedBox.shrink();

        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 800
                ? 4
                : constraints.maxWidth > 500
                    ? 2
                    : 1;

            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.8,
              children: [
                StatCard(
                  icon: Icons.payments_outlined,
                  label: t('total_spend', lang),
                  value: _formatCurrency(stats.totalSpend),
                  subtitle:
                      '${stats.totalCount} ${t('purchases_count', lang)}',
                ),
                StatCard(
                  icon: Icons.analytics_outlined,
                  label: t('average_purchase', lang),
                  value: _formatCurrency(stats.averagePurchase),
                ),
                StatCard(
                  icon: Icons.store_outlined,
                  label: t('top_supplier', lang),
                  value: stats.topSupplierName,
                  subtitle:
                      '${stats.topSupplierCount} ${t('purchases_count', lang)}, ${_formatCurrency(stats.topSupplierTotal)}',
                ),
                StatCard(
                  icon: Icons.calendar_month_outlined,
                  label: t('purchase_frequency', lang),
                  value:
                      '${stats.purchasesPerMonth.toStringAsFixed(1)}${t('per_month', lang)}',
                  subtitle:
                      '${stats.uniqueSupplierCount} ${t('unique_suppliers', lang).toLowerCase()}',
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return 'P${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return 'P${(amount / 1000).toStringAsFixed(1)}K';
    }
    return 'P${amount.toStringAsFixed(2)}';
  }

  Widget _buildTable(BuildContext context, WidgetRef ref, ColorScheme colors) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return SizedBox(
      width: double.infinity,
      child: DataTable(
        sortColumnIndex: sort.field.index,
        sortAscending: sort.ascending,
        headingRowColor: WidgetStateProperty.all(
          colors.surfaceContainerLow,
        ),
        columns: [
          DataColumn(label: Text(t('seller_name', lang))),
          DataColumn(
            label: Text(t('crop_type', lang)),
            onSort: (_, ascending) =>
                _onSort(ref, PurchaseSortField.cropType, ascending),
          ),
          DataColumn(label: Text(t('quantity', lang)), numeric: true),
          DataColumn(label: Text(t('unit', lang))),
          DataColumn(
            label: Text(t('price_per_unit', lang)),
            numeric: true,
          ),
          DataColumn(
            label: Text(t('total_amount', lang)),
            numeric: true,
            onSort: (_, ascending) =>
                _onSort(ref, PurchaseSortField.totalAmount, ascending),
          ),
          DataColumn(
            label: Text(t('purchase_date', lang)),
            onSort: (_, ascending) =>
                _onSort(ref, PurchaseSortField.purchaseDate, ascending),
          ),
          DataColumn(label: Text(t('actions', lang))),
        ],
        rows: purchases
            .map((p) => _buildRow(context, ref, p, colors, dateFormat))
            .toList(),
      ),
    );
  }

  DataRow _buildRow(
    BuildContext context,
    WidgetRef ref,
    PurchaseModel purchase,
    ColorScheme colors,
    DateFormat dateFormat,
  ) {
    return DataRow(cells: [
      DataCell(Text(purchase.sellerName)),
      DataCell(Text(purchase.cropType)),
      DataCell(Text(purchase.quantity.toStringAsFixed(1))),
      DataCell(Text(purchase.unit)),
      DataCell(Text('P${purchase.pricePerUnit.toStringAsFixed(2)}')),
      DataCell(Text('P${purchase.totalAmount.toStringAsFixed(2)}')),
      DataCell(Text(dateFormat.format(purchase.purchaseDate))),
      DataCell(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: t('edit_purchase', lang),
              onPressed: () => _editPurchase(context, ref, purchase),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, size: 20, color: colors.error),
              tooltip: t('delete_purchase', lang),
              onPressed: () => _deletePurchase(context, ref, purchase),
            ),
          ],
        ),
      ),
    ]);
  }

  void _onSort(WidgetRef ref, PurchaseSortField field, bool ascending) {
    ref.read(purchasesSortProvider.notifier).state = PurchaseSort(
      field: field,
      ascending: ascending,
    );
  }

  Future<void> _addPurchase(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final result = await showPurchaseFormDialog(
      context,
      lang: lang,
      userId: user.uid,
    );
    if (result == null || !context.mounted) return;

    final error = await ref
        .read(purchasesControllerProvider.notifier)
        .addPurchase(result);

    if (!context.mounted) return;
    _showResultSnackBar(context, error: error, successKey: 'purchase_added');
  }

  Future<void> _editPurchase(
    BuildContext context,
    WidgetRef ref,
    PurchaseModel purchase,
  ) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final result = await showPurchaseFormDialog(
      context,
      lang: lang,
      userId: user.uid,
      purchase: purchase,
    );
    if (result == null || !context.mounted) return;

    final error = await ref
        .read(purchasesControllerProvider.notifier)
        .updatePurchase(purchase.id!, result);

    if (!context.mounted) return;
    _showResultSnackBar(context, error: error, successKey: 'purchase_updated');
  }

  Future<void> _deletePurchase(
    BuildContext context,
    WidgetRef ref,
    PurchaseModel purchase,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('delete_purchase', lang)),
        content: Text(t('delete_purchase_confirm', lang)),
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
        .read(purchasesControllerProvider.notifier)
        .deletePurchase(purchase.id!);

    if (!context.mounted) return;
    _showResultSnackBar(context, error: error, successKey: 'purchase_deleted');
  }

  void _showResultSnackBar(
    BuildContext context, {
    required String? error,
    required String successKey,
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
      messenger.showSnackBar(
        SnackBar(content: Text(t(successKey, lang))),
      );
    }
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
            Icon(Icons.shopping_cart_outlined, size: 64, color: colors.outline),
            const SizedBox(height: 16),
            Text(
              t('no_purchases', lang),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              t('no_purchases_hint', lang),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(t('add_purchase', lang)),
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
            t('error_loading_purchases', lang),
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
