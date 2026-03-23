import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/providers/language_provider.dart';
import 'package:agricola_dashboard/core/providers/pagination_provider.dart';
import 'package:agricola_dashboard/core/widgets/app_text_field.dart';
import 'package:agricola_dashboard/core/widgets/table_pagination_bar.dart';
import 'package:agricola_dashboard/features/loss_calculator/presentation/loss_calculator_form_dialog.dart';
import 'package:agricola_dashboard/features/loss_calculator/presentation/loss_detail_dialog.dart';
import 'package:agricola_dashboard/features/loss_calculator/presentation/widgets/loss_severity_badge.dart';
import 'package:agricola_dashboard/features/loss_calculator/providers/loss_calculator_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LossCalculatorScreen extends ConsumerWidget {
  const LossCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final filteredAsync = ref.watch(filteredLossCalcsProvider);
    final sort = ref.watch(lossCalcSortProvider);

    return filteredAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorView(
        message: error.toString(),
        onRetry: () => ref.invalidate(lossCalcControllerProvider),
        lang: lang,
      ),
      data: (items) => _LossCalcContent(
        items: items,
        sort: sort,
        lang: lang,
      ),
    );
  }
}

class _LossCalcContent extends ConsumerWidget {
  const _LossCalcContent({
    required this.items,
    required this.sort,
    required this.lang,
  });

  final List<LossCalculation> items;
  final LossCalcSort sort;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    final pagination = ref.watch(paginationProvider('loss_calculator'));
    final pageItems = paginateList(items, pagination);

    ref.listen(lossCalcSearchProvider, (_, __) {
      ref.read(paginationProvider('loss_calculator').notifier).state =
          ref.read(paginationProvider('loss_calculator')).copyWith(currentPage: 0);
    });
    ref.listen(lossCalcSortProvider, (_, __) {
      ref.read(paginationProvider('loss_calculator').notifier).state =
          ref.read(paginationProvider('loss_calculator')).copyWith(currentPage: 0);
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, ref, textTheme, colors),
          const SizedBox(height: 24),
          if (items.isEmpty)
            _EmptyState(lang: lang, onAdd: () => _addCalculation(context, ref))
          else ...[
            _buildTable(context, ref, colors, pageItems),
            const SizedBox(height: 16),
            TablePaginationBar(
              totalItems: items.length,
              pagination: pagination,
              onPageChanged: (page) =>
                  ref.read(paginationProvider('loss_calculator').notifier).state =
                      pagination.copyWith(currentPage: page),
              onRowsPerPageChanged: (rows) =>
                  ref.read(paginationProvider('loss_calculator').notifier).state =
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t('loss_calculator', lang),
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 260,
              child: AppTextField(
                label: t('search', lang),
                prefixIcon: Icons.search,
                onChanged: (value) =>
                    ref.read(lossCalcSearchProvider.notifier).state = value,
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () => _addCalculation(context, ref),
              icon: const Icon(Icons.add),
              label: Text(t('add_calculation', lang)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTable(BuildContext context, WidgetRef ref, ColorScheme colors, List<LossCalculation> pageItems) {
    return SizedBox(
      width: double.infinity,
      child: DataTable(
        sortColumnIndex: sort.field.index,
        sortAscending: sort.ascending,
        headingRowColor: WidgetStateProperty.all(
          colors.surfaceContainerLow,
        ),
        columns: [
          DataColumn(
            label: Text(t('crop_type', lang)),
            onSort: (_, ascending) =>
                _onSort(ref, LossCalcSortField.cropType, ascending),
          ),
          DataColumn(label: Text(t('crop_category', lang))),
          DataColumn(label: Text(t('harvest_amount', lang))),
          DataColumn(
            label: Text(t('loss_percentage', lang)),
            numeric: true,
            onSort: (_, ascending) =>
                _onSort(ref, LossCalcSortField.totalLossPercentage, ascending),
          ),
          DataColumn(
            label: Text(t('monetary_loss', lang)),
            numeric: true,
            onSort: (_, ascending) =>
                _onSort(ref, LossCalcSortField.monetaryLoss, ascending),
          ),
          DataColumn(label: Text(t('severity', lang))),
          DataColumn(
            label: Text(t('date', lang)),
            onSort: (_, ascending) =>
                _onSort(ref, LossCalcSortField.calculationDate, ascending),
          ),
          DataColumn(label: Text(t('actions', lang))),
        ],
        rows: pageItems.map((item) => _buildRow(context, ref, item, colors)).toList(),
      ),
    );
  }

  DataRow _buildRow(
    BuildContext context,
    WidgetRef ref,
    LossCalculation calc,
    ColorScheme colors,
  ) {
    return DataRow(
      cells: [
        DataCell(Text(calc.cropType)),
        DataCell(Text(t(calc.cropCategory ?? 'default', lang))),
        DataCell(Text('${calc.harvestAmount} ${calc.unit}')),
        DataCell(Text('${calc.totalLossPercentage.toStringAsFixed(1)}%')),
        DataCell(Text(formatBWP(calc.monetaryLoss))),
        DataCell(
          LossSeverityBadge(
            lossPercentage: calc.totalLossPercentage,
            lang: lang,
          ),
        ),
        DataCell(Text(_formatDate(calc.calculationDate))),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 20),
                tooltip: t('view_details', lang),
                onPressed: () => showLossDetailDialog(
                  context,
                  calculation: calc,
                  lang: lang,
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 20, color: colors.error),
                tooltip: t('delete', lang),
                onPressed: () => _deleteCalculation(context, ref, calc),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onSort(WidgetRef ref, LossCalcSortField field, bool ascending) {
    ref.read(lossCalcSortProvider.notifier).state = LossCalcSort(
      field: field,
      ascending: ascending,
    );
  }

  Future<void> _addCalculation(BuildContext context, WidgetRef ref) async {
    final lang = ref.read(languageProvider);
    final result = await showLossCalculatorFormDialog(
      context,
      lang: lang,
    );
    if (result == null || !context.mounted) return;

    final error = await ref
        .read(lossCalcControllerProvider.notifier)
        .addCalculation(result);

    if (!context.mounted) return;
    _showResultSnackBar(
      context,
      error: error,
      successKey: 'calculation_added',
      lang: lang,
    );
  }

  Future<void> _deleteCalculation(
    BuildContext context,
    WidgetRef ref,
    LossCalculation calc,
  ) async {
    final lang = ref.read(languageProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('delete', lang)),
        content: Text(t('delete_calculation_confirm', lang)),
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
        .read(lossCalcControllerProvider.notifier)
        .deleteCalculation(calc.id!);

    if (!context.mounted) return;
    _showResultSnackBar(
      context,
      error: error,
      successKey: 'calculation_deleted',
      lang: lang,
    );
  }

  void _showResultSnackBar(
    BuildContext context, {
    required String? error,
    required String successKey,
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
      messenger.showSnackBar(
        SnackBar(content: Text(t(successKey, lang))),
      );
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
            Icon(Icons.calculate_outlined, size: 64, color: colors.outline),
            const SizedBox(height: 16),
            Text(
              t('no_calculations', lang),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              t('add_calculation_hint', lang),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(t('add_calculation', lang)),
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
            t('error_loading_calculations', lang),
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
