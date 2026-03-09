import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/providers/language_provider.dart';
import 'package:agricola_dashboard/features/crops/providers/crop_providers.dart';
import 'package:agricola_dashboard/features/harvests/presentation/harvest_form_dialog.dart';
import 'package:agricola_dashboard/features/harvests/presentation/widgets/quality_badge.dart';
import 'package:agricola_dashboard/features/harvests/providers/harvest_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HarvestsScreen extends ConsumerStatefulWidget {
  const HarvestsScreen({super.key, this.initialCropId});

  final String? initialCropId;

  @override
  ConsumerState<HarvestsScreen> createState() => _HarvestsScreenState();
}

class _HarvestsScreenState extends ConsumerState<HarvestsScreen> {
  @override
  void initState() {
    super.initState();
    // Set the initial crop selection if navigated with a cropId
    if (widget.initialCropId != null) {
      Future.microtask(() {
        ref.read(selectedCropIdProvider.notifier).state =
            widget.initialCropId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final cropsAsync = ref.watch(cropControllerProvider);
    final selectedCropId = ref.watch(selectedCropIdProvider);
    final harvestsAsync = ref.watch(harvestControllerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, lang, cropsAsync, selectedCropId),
          const SizedBox(height: 24),
          if (selectedCropId != null)
            _buildSelectedCropInfo(context, lang, cropsAsync, selectedCropId),
          if (selectedCropId == null)
            _NoCropSelected(lang: lang)
          else
            harvestsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorView(
                message: error.toString(),
                onRetry: () => ref.invalidate(harvestControllerProvider),
                lang: lang,
              ),
              data: (harvests) => harvests.isEmpty
                  ? _EmptyState(
                      lang: lang,
                      onAdd: () => _recordHarvest(context, selectedCropId),
                    )
                  : _buildTable(context, harvests, lang, selectedCropId),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLanguage lang,
    AsyncValue<List<CropModel>> cropsAsync,
    String? selectedCropId,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final crops = cropsAsync.valueOrNull ?? [];
    final catalogAsync = ref.watch(cropCatalogProvider);
    final catalog = catalogAsync.valueOrNull ?? [];

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
              t('harvest', lang),
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Crop selector dropdown
            SizedBox(
              width: 280,
              child: DropdownButtonFormField<String>(
                initialValue: selectedCropId,
                decoration: InputDecoration(
                  labelText: t('select_crop', lang),
                  prefixIcon: const Icon(Icons.grass),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: crops.map((crop) {
                  final displayName =
                      cropDisplayName(crop.cropType, catalog, lang);
                  return DropdownMenuItem(
                    value: crop.id,
                    child: Text(
                      '$displayName — ${crop.fieldName}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  ref.read(selectedCropIdProvider.notifier).state = value;
                },
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: selectedCropId != null
                  ? () => _recordHarvest(context, selectedCropId)
                  : null,
              icon: const Icon(Icons.add),
              label: Text(t('record_harvest', lang)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectedCropInfo(
    BuildContext context,
    AppLanguage lang,
    AsyncValue<List<CropModel>> cropsAsync,
    String selectedCropId,
  ) {
    final crops = cropsAsync.valueOrNull ?? [];
    final crop = crops.where((c) => c.id == selectedCropId).firstOrNull;
    if (crop == null) return const SizedBox.shrink();

    final catalogAsync = ref.watch(cropCatalogProvider);
    final catalog = catalogAsync.valueOrNull ?? [];
    final colors = Theme.of(context).colorScheme;
    final displayName = cropDisplayName(crop.cropType, catalog, lang);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _InfoChip(
                icon: Icons.grass,
                label: displayName,
                colors: colors,
              ),
              const SizedBox(width: 24),
              _InfoChip(
                icon: Icons.landscape,
                label: crop.fieldName,
                colors: colors,
              ),
              const SizedBox(width: 24),
              _InfoChip(
                icon: Icons.calendar_today,
                label:
                    '${t('planting_date', lang)}: ${formatCropDate(crop.plantingDate)}',
                colors: colors,
              ),
              const SizedBox(width: 24),
              _InfoChip(
                icon: Icons.scale,
                label:
                    '${t('estimated_yield', lang)}: ${crop.estimatedYield} ${crop.yieldUnit}',
                colors: colors,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTable(
    BuildContext context,
    List<HarvestModel> harvests,
    AppLanguage lang,
    String cropId,
  ) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          colors.surfaceContainerLow,
        ),
        columns: [
          DataColumn(label: Text(t('harvest_date', lang))),
          DataColumn(
            label: Text(t('actual_yield', lang)),
            numeric: true,
          ),
          DataColumn(label: Text(t('quality_assessment', lang))),
          DataColumn(label: Text(t('storage_location', lang))),
          DataColumn(label: Text(t('loss_amount', lang)), numeric: true),
          DataColumn(label: Text(t('loss_reason', lang))),
          DataColumn(label: Text(t('actions', lang))),
        ],
        rows: harvests
            .map((h) => _buildRow(context, h, lang, colors))
            .toList(),
      ),
    );
  }

  DataRow _buildRow(
    BuildContext context,
    HarvestModel harvest,
    AppLanguage lang,
    ColorScheme colors,
  ) {
    return DataRow(
      cells: [
        DataCell(Text(formatCropDate(harvest.harvestDate))),
        DataCell(Text('${harvest.actualYield} ${harvest.yieldUnit}')),
        DataCell(QualityBadge(quality: harvest.quality, lang: lang)),
        DataCell(Text(harvest.storageLocation)),
        DataCell(Text(
          harvest.lossAmount != null
              ? harvest.lossAmount!.toStringAsFixed(1)
              : '—',
        )),
        DataCell(Text(
          harvest.lossReason != null ? t(harvest.lossReason!, lang) : '—',
        )),
        DataCell(
          IconButton(
            icon: Icon(Icons.delete_outline, size: 20, color: colors.error),
            tooltip: t('delete', lang),
            onPressed: () => _deleteHarvest(context, harvest, lang),
          ),
        ),
      ],
    );
  }

  Future<void> _recordHarvest(BuildContext context, String cropId) async {
    final lang = ref.read(languageProvider);
    // Get the crop's yield unit to pre-select in the form
    final crops = ref.read(cropControllerProvider).valueOrNull ?? [];
    final crop = crops.where((c) => c.id == cropId).firstOrNull;

    final result = await showHarvestFormDialog(
      context,
      lang: lang,
      cropId: cropId,
      defaultYieldUnit: crop?.yieldUnit ?? 'kg',
    );
    if (result == null || !context.mounted) return;

    final error = await ref
        .read(harvestControllerProvider.notifier)
        .addHarvest(result);

    if (!context.mounted) return;
    _showResultSnackBar(
      context,
      error: error,
      successKey: 'harvest_recorded',
      lang: lang,
    );
  }

  Future<void> _deleteHarvest(
    BuildContext context,
    HarvestModel harvest,
    AppLanguage lang,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('delete', lang)),
        content: Text(t('delete_harvest_confirm', lang)),
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
        .read(harvestControllerProvider.notifier)
        .deleteHarvest(harvest.id!);

    if (!context.mounted) return;
    _showResultSnackBar(
      context,
      error: error,
      successKey: 'harvest_deleted',
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
}

// ---------------------------------------------------------------------------
// Info chip for crop summary card
// ---------------------------------------------------------------------------

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.colors,
  });

  final IconData icon;
  final String label;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colors.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// No crop selected state
// ---------------------------------------------------------------------------

class _NoCropSelected extends StatelessWidget {
  const _NoCropSelected({required this.lang});

  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.agriculture_outlined, size: 64, color: colors.outline),
            const SizedBox(height: 16),
            Text(
              t('select_crop_to_view_harvests', lang),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
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
            Icon(Icons.agriculture_outlined, size: 64, color: colors.outline),
            const SizedBox(height: 16),
            Text(
              t('no_harvests', lang),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              t('record_harvest_hint', lang),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(t('record_harvest', lang)),
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
            t('error_loading_harvests', lang),
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
