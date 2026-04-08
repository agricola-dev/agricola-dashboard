import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/providers/language_provider.dart';
import 'package:agricola_dashboard/core/providers/pagination_provider.dart';
import 'package:agricola_dashboard/core/widgets/app_text_field.dart';
import 'package:agricola_dashboard/core/widgets/table_pagination_bar.dart';
import 'package:agricola_dashboard/features/crops/presentation/crop_form_dialog.dart';
import 'package:agricola_dashboard/features/crops/presentation/widgets/crop_stage_badge.dart';
import 'package:agricola_dashboard/features/crops/providers/crop_providers.dart';
import 'package:agricola_dashboard/routing/route_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CropsScreen extends ConsumerWidget {
  const CropsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final filteredAsync = ref.watch(filteredCropsProvider);
    final sort = ref.watch(cropSortProvider);

    return filteredAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorView(
        message: t('error_try_again', lang),
        onRetry: () => ref.invalidate(cropControllerProvider),
        lang: lang,
      ),
      data: (items) => _CropsContent(
        items: items,
        sort: sort,
        lang: lang,
      ),
    );
  }
}

class _CropsContent extends ConsumerWidget {
  const _CropsContent({
    required this.items,
    required this.sort,
    required this.lang,
  });

  final List<CropModel> items;
  final CropSort sort;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    final pagination = ref.watch(paginationProvider('crops'));
    final pageItems = paginateList(items, pagination);

    ref.listen(cropSearchProvider, (_, __) {
      ref.read(paginationProvider('crops').notifier).state =
          ref.read(paginationProvider('crops')).copyWith(currentPage: 0);
    });
    ref.listen(cropSortProvider, (_, __) {
      ref.read(paginationProvider('crops').notifier).state =
          ref.read(paginationProvider('crops')).copyWith(currentPage: 0);
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, ref, textTheme, colors),
          const SizedBox(height: 24),
          if (items.isEmpty)
            _EmptyState(lang: lang, onAdd: () => _addCrop(context, ref))
          else ...[
            _buildTable(context, ref, colors, pageItems),
            const SizedBox(height: 16),
            TablePaginationBar(
              totalItems: items.length,
              pagination: pagination,
              onPageChanged: (page) =>
                  ref.read(paginationProvider('crops').notifier).state =
                      pagination.copyWith(currentPage: page),
              onRowsPerPageChanged: (rows) =>
                  ref.read(paginationProvider('crops').notifier).state =
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
              t('crops', lang),
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
                    ref.read(cropSearchProvider.notifier).state = value,
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () => _addCrop(context, ref),
              icon: const Icon(Icons.add),
              label: Text(t('add_crop', lang)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTable(BuildContext context, WidgetRef ref, ColorScheme colors, List<CropModel> pageItems) {
    final catalogAsync = ref.watch(cropCatalogProvider);
    final catalog = catalogAsync.valueOrNull ?? [];

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
                _onSort(ref, CropSortField.cropType, ascending),
          ),
          DataColumn(
            label: Text(t('field_name', lang)),
            onSort: (_, ascending) =>
                _onSort(ref, CropSortField.fieldName, ascending),
          ),
          DataColumn(label: Text(t('field_size', lang))),
          DataColumn(
            label: Text(t('planting_date', lang)),
            onSort: (_, ascending) =>
                _onSort(ref, CropSortField.plantingDate, ascending),
          ),
          DataColumn(
            label: Text(t('expected_harvest_date', lang)),
            onSort: (_, ascending) =>
                _onSort(ref, CropSortField.expectedHarvestDate, ascending),
          ),
          DataColumn(label: Text(t('current_stage', lang))),
          DataColumn(label: Text(t('actions', lang))),
        ],
        rows: pageItems
            .map((item) => _buildRow(context, ref, item, colors, catalog))
            .toList(),
      ),
    );
  }

  DataRow _buildRow(
    BuildContext context,
    WidgetRef ref,
    CropModel crop,
    ColorScheme colors,
    List<CropCatalogEntry> catalog,
  ) {
    final stage = cropStage(crop);
    final progress = cropProgress(crop);
    final displayName = cropDisplayName(crop.cropType, catalog, lang);

    return DataRow(
      cells: [
        DataCell(Text(displayName)),
        DataCell(Text(crop.fieldName)),
        DataCell(Text('${crop.fieldSize} ${crop.fieldSizeUnit}')),
        DataCell(Text(formatCropDate(crop.plantingDate))),
        DataCell(Text(formatCropDate(crop.expectedHarvestDate))),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CropStageBadge(stage: stage, lang: lang),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                child: LinearProgressIndicator(
                  value: progress,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.agriculture_outlined, size: 20),
                tooltip: t('harvest', lang),
                onPressed: () => context.go(
                  '${RouteNames.harvests}?cropId=${crop.id}',
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: t('edit_crop', lang),
                onPressed: () => _editCrop(context, ref, crop),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    size: 20, color: colors.error),
                tooltip: t('delete', lang),
                onPressed: () => _deleteCrop(context, ref, crop),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onSort(WidgetRef ref, CropSortField field, bool ascending) {
    ref.read(cropSortProvider.notifier).state = CropSort(
      field: field,
      ascending: ascending,
    );
  }

  Future<void> _addCrop(BuildContext context, WidgetRef ref) async {
    final lang = ref.read(languageProvider);
    final catalog = ref.read(cropCatalogProvider).valueOrNull ?? [];
    final result = await showCropFormDialog(
      context,
      lang: lang,
      catalog: catalog,
    );
    if (result == null || !context.mounted) return;

    final error =
        await ref.read(cropControllerProvider.notifier).addCrop(result);

    if (!context.mounted) return;
    _showResultSnackBar(context, error: error, successKey: 'crop_added', lang: lang);
  }

  Future<void> _editCrop(
    BuildContext context,
    WidgetRef ref,
    CropModel crop,
  ) async {
    final lang = ref.read(languageProvider);
    final catalog = ref.read(cropCatalogProvider).valueOrNull ?? [];
    final result = await showCropFormDialog(
      context,
      lang: lang,
      catalog: catalog,
      crop: crop,
    );
    if (result == null || !context.mounted) return;

    final error = await ref
        .read(cropControllerProvider.notifier)
        .updateCrop(crop.id!, result);

    if (!context.mounted) return;
    _showResultSnackBar(context, error: error, successKey: 'crop_updated', lang: lang);
  }

  Future<void> _deleteCrop(
    BuildContext context,
    WidgetRef ref,
    CropModel crop,
  ) async {
    final lang = ref.read(languageProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('delete', lang)),
        content: Text(t('delete_crop_confirm', lang)),
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

    final error =
        await ref.read(cropControllerProvider.notifier).deleteCrop(crop.id!);

    if (!context.mounted) return;
    _showResultSnackBar(context, error: error, successKey: 'crop_deleted', lang: lang);
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
          content: Text(t(error, lang)),
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
            Icon(Icons.grass_outlined, size: 64, color: colors.outline),
            const SizedBox(height: 16),
            Text(
              t('no_crops', lang),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              t('add_crop_hint', lang),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(t('add_crop', lang)),
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
            t('error_loading_crops', lang),
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
