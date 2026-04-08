import 'dart:typed_data';

import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/analytics/analytics_provider.dart';
import 'package:agricola_dashboard/core/providers/language_provider.dart';
import 'package:agricola_dashboard/core/widgets/chart_card.dart';
import 'package:agricola_dashboard/core/widgets/period_filter.dart';
import 'package:agricola_dashboard/core/widgets/stat_card.dart';
import 'package:agricola_dashboard/features/auth/providers/auth_providers.dart';
import 'package:agricola_dashboard/features/crops/providers/crop_providers.dart';
import 'package:agricola_dashboard/features/dashboard/providers/dashboard_controller.dart';
import 'package:agricola_dashboard/features/harvests/providers/harvest_providers.dart';
import 'package:agricola_dashboard/features/inventory/providers/inventory_providers.dart';
import 'package:agricola_dashboard/features/orders/providers/orders_providers.dart';
import 'package:agricola_dashboard/features/purchases/providers/purchases_providers.dart';
import 'package:agricola_dashboard/features/reports/providers/reports_providers.dart';
import 'package:agricola_dashboard/features/reports/services/web_export_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    // Listen for custom period selection and open date range picker
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(analyticsPeriodProvider, (previous, next) {
        if (next == AnalyticsPeriod.custom) {
          _openDateRangePicker();
        }
      });
    });
  }

  Future<void> _openDateRangePicker() async {
    final existing = ref.read(reportsDateRangeProvider);
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: existing,
    );
    if (range != null) {
      ref.read(reportsDateRangeProvider.notifier).state = range;
    } else {
      // User cancelled — revert to month
      ref.read(analyticsPeriodProvider.notifier).state = AnalyticsPeriod.month;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final user = ref.watch(currentUserProvider);
    final period = ref.watch(analyticsPeriodProvider);
    final analyticsAsync = ref.watch(analyticsProvider);
    final isFarmer = user?.userType == UserType.farmer;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, lang, period),
          const SizedBox(height: 24),
          analyticsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _ErrorView(
              message: t('error_try_again', lang),
              onRetry: () => ref.invalidate(analyticsProvider),
              lang: lang,
            ),
            data: (analytics) => _buildAnalyticsContent(
              context,
              analytics,
              isFarmer,
              lang,
              period,
            ),
          ),
          const SizedBox(height: 32),
          _buildDataSection(context, lang, isFarmer),
          const SizedBox(height: 32),
          _buildExportBar(context, lang, isFarmer, analyticsAsync),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader(
    BuildContext context,
    AppLanguage lang,
    AnalyticsPeriod period,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('reports', lang),
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                t('view_reports_desc', lang),
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const PeriodFilter(showCustom: true),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Analytics section
  // ---------------------------------------------------------------------------

  Widget _buildAnalyticsContent(
    BuildContext context,
    AnalyticsModel analytics,
    bool isFarmer,
    AppLanguage lang,
    AnalyticsPeriod period,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (period == AnalyticsPeriod.custom) ...[
          _buildCustomRangeNote(context, lang),
          const SizedBox(height: 16),
        ],
        _buildStatsGrid(context, analytics, isFarmer, lang),
        const SizedBox(height: 32),
        _buildChartsSection(context, analytics, isFarmer, lang),
      ],
    );
  }

  Widget _buildCustomRangeNote(BuildContext context, AppLanguage lang) {
    final range = ref.watch(reportsDateRangeProvider);
    final colors = Theme.of(context).colorScheme;
    final df = DateFormat('dd MMM yyyy');
    final rangeStr = range != null
        ? '${df.format(range.start)} — ${df.format(range.end)}'
        : '';

    return Row(
      children: [
        Icon(Icons.info_outline, size: 16, color: colors.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            rangeStr.isNotEmpty
                ? '${t('date_range', lang)}: $rangeStr  •  ${t('showing_all_time_stats', lang)}'
                : t('showing_all_time_stats', lang),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(
    BuildContext context,
    AnalyticsModel analytics,
    bool isFarmer,
    AppLanguage lang,
  ) {
    final cards = isFarmer
        ? _farmerCards(analytics, lang)
        : _merchantCards(analytics, lang);

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800
            ? 3
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
          children: cards,
        );
      },
    );
  }

  List<Widget> _merchantCards(AnalyticsModel analytics, AppLanguage lang) {
    return [
      StatCard(
        icon: Icons.inventory_2_outlined,
        label: t('inventory', lang),
        value: '${analytics.inventory.total}',
        subtitle: analytics.inventory.criticalItems > 0
            ? '${analytics.inventory.criticalItems} ${t('critical_items', lang)}'
            : null,
      ),
      StatCard(
        icon: Icons.storefront_outlined,
        label: t('active_listings', lang),
        value: '${analytics.marketplace.activeListings}',
      ),
      StatCard(
        icon: Icons.receipt_long_outlined,
        label: t('active_orders', lang),
        value: '${analytics.orders.active}',
      ),
      StatCard(
        icon: Icons.trending_up_outlined,
        label: t('period_revenue', lang),
        value: _formatCurrency(analytics.orders.periodRevenue),
        subtitle:
            '${t('total', lang)}: ${_formatCurrency(analytics.orders.totalRevenue)}',
      ),
      StatCard(
        icon: Icons.shopping_cart_outlined,
        label: t('total_purchases', lang),
        value: '${analytics.purchases.total}',
        subtitle: _formatCurrency(analytics.purchases.periodValue),
      ),
      StatCard(
        icon: Icons.people_outlined,
        label: t('unique_suppliers', lang),
        value: '${analytics.purchases.uniqueSuppliers}',
      ),
    ];
  }

  List<Widget> _farmerCards(AnalyticsModel analytics, AppLanguage lang) {
    return [
      StatCard(
        icon: Icons.grass_outlined,
        label: t('active_crops', lang),
        value: '${analytics.crops.active}',
        subtitle: '${analytics.crops.harvested} ${t('harvested', lang)}',
      ),
      StatCard(
        icon: Icons.calendar_today_outlined,
        label: t('upcoming_harvests', lang),
        value: '${analytics.crops.upcomingHarvests}',
      ),
      StatCard(
        icon: Icons.scale_outlined,
        label: t('total_yield', lang),
        value: _formatWeight(analytics.harvests.totalYield),
      ),
      StatCard(
        icon: Icons.warning_amber_outlined,
        label: t('total_loss', lang),
        value: _formatWeight(analytics.harvests.totalLoss),
      ),
      StatCard(
        icon: Icons.inventory_2_outlined,
        label: t('inventory', lang),
        value: '${analytics.inventory.total}',
        subtitle: analytics.inventory.criticalItems > 0
            ? '${analytics.inventory.criticalItems} ${t('critical_items', lang)}'
            : null,
      ),
      StatCard(
        icon: Icons.landscape_outlined,
        label: t('total_field_size', lang),
        value: _formatArea(analytics.crops.totalFieldSize),
      ),
    ];
  }

  Widget _buildChartsSection(
    BuildContext context,
    AnalyticsModel analytics,
    bool isFarmer,
    AppLanguage lang,
  ) {
    final charts = isFarmer
        ? _farmerCharts(analytics, lang)
        : _merchantCharts(analytics, lang);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 700) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: charts[0]),
              const SizedBox(width: 16),
              Expanded(child: charts[1]),
            ],
          );
        }
        return Column(
          children: charts
              .map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: c,
                  ))
              .toList(),
        );
      },
    );
  }

  List<Widget> _merchantCharts(AnalyticsModel analytics, AppLanguage lang) {
    return [
      ChartCard(
        title: t('revenue_overview', lang),
        child: _RevenueBarChart(
          periodRevenue: analytics.orders.periodRevenue,
          periodPurchases: analytics.purchases.periodValue,
          lang: lang,
        ),
      ),
      ChartCard(
        title: t('inventory_overview', lang),
        child: _InventoryPieChart(
          total: analytics.inventory.total,
          critical: analytics.inventory.criticalItems,
          activeListings: analytics.marketplace.activeListings,
          lang: lang,
        ),
      ),
    ];
  }

  List<Widget> _farmerCharts(AnalyticsModel analytics, AppLanguage lang) {
    return [
      ChartCard(
        title: t('crop_overview', lang),
        child: _CropPieChart(
          active: analytics.crops.active,
          harvested: analytics.crops.harvested,
          lang: lang,
        ),
      ),
      ChartCard(
        title: t('yield_vs_loss', lang),
        child: _YieldLossBarChart(
          totalYield: analytics.harvests.totalYield,
          totalLoss: analytics.harvests.totalLoss,
          lang: lang,
        ),
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Data section
  // ---------------------------------------------------------------------------

  Widget _buildDataSection(
    BuildContext context,
    AppLanguage lang,
    bool isFarmer,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    final datasets = isFarmer
        ? ['crops', 'harvests', 'inventory']
        : ['inventory', 'purchases', 'orders'];

    final dataset = ref.watch(reportsDatasetProvider);
    final activeDataset = datasets.contains(dataset) ? dataset : datasets.first;

    final labels = {
      'crops': t('crops', lang),
      'harvests': t('harvests', lang),
      'inventory': t('inventory', lang),
      'purchases': t('purchases', lang),
      'orders': t('orders', lang),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('export_data', lang),
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        // Dataset selector
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<String>(
            segments: datasets
                .map((d) => ButtonSegment(
                      value: d,
                      label: Text(labels[d] ?? d),
                    ))
                .toList(),
            selected: {activeDataset},
            onSelectionChanged: (s) {
              ref.read(reportsDatasetProvider.notifier).state = s.first;
            },
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Data table
        Card(
          elevation: 0,
          color: colors.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side:
                BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildDataTable(context, lang, activeDataset),
          ),
        ),
      ],
    );
  }

  Widget _buildDataTable(
    BuildContext context,
    AppLanguage lang,
    String dataset,
  ) {
    final dateRange = ref.watch(reportsDateRangeProvider);

    switch (dataset) {
      case 'crops':
        final cropsAsync = ref.watch(cropControllerProvider);
        return cropsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _InlineError(message: t('error_try_again', lang), lang: lang),
          data: (crops) {
            final filtered = dateRange != null
                ? crops
                    .where((c) =>
                        !c.plantingDate.isBefore(dateRange.start) &&
                        !c.plantingDate.isAfter(dateRange.end))
                    .toList()
                : crops;
            if (filtered.isEmpty) return _EmptyTable(lang: lang);
            return _CropsTable(crops: filtered, lang: lang);
          },
        );

      case 'harvests':
        final harvestsAsync = ref.watch(harvestControllerProvider);
        final selectedCropId = ref.watch(selectedCropIdProvider);
        if (selectedCropId == null) {
          return _HarvestsNoCropHint(lang: lang);
        }
        return harvestsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _InlineError(message: t('error_try_again', lang), lang: lang),
          data: (harvests) {
            final filtered = dateRange != null
                ? harvests
                    .where((h) =>
                        !h.harvestDate.isBefore(dateRange.start) &&
                        !h.harvestDate.isAfter(dateRange.end))
                    .toList()
                : harvests;
            if (filtered.isEmpty) return _EmptyTable(lang: lang);
            return _HarvestsTable(harvests: filtered, lang: lang);
          },
        );

      case 'inventory':
        final inventoryAsync = ref.watch(inventoryControllerProvider);
        return inventoryAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _InlineError(message: t('error_try_again', lang), lang: lang),
          data: (items) {
            final filtered = dateRange != null
                ? items
                    .where((i) =>
                        !i.storageDate.isBefore(dateRange.start) &&
                        !i.storageDate.isAfter(dateRange.end))
                    .toList()
                : items;
            if (filtered.isEmpty) return _EmptyTable(lang: lang);
            return _InventoryTable(items: filtered, lang: lang);
          },
        );

      case 'purchases':
        final purchasesAsync = ref.watch(purchasesControllerProvider);
        return purchasesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _InlineError(message: t('error_try_again', lang), lang: lang),
          data: (purchases) {
            final filtered = dateRange != null
                ? purchases
                    .where((p) =>
                        !p.purchaseDate.isBefore(dateRange.start) &&
                        !p.purchaseDate.isAfter(dateRange.end))
                    .toList()
                : purchases;
            if (filtered.isEmpty) return _EmptyTable(lang: lang);
            return _PurchasesTable(purchases: filtered, lang: lang);
          },
        );

      case 'orders':
        final ordersAsync = ref.watch(ordersControllerProvider);
        return ordersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _InlineError(message: t('error_try_again', lang), lang: lang),
          data: (orders) {
            final filtered = dateRange != null
                ? orders
                    .where((o) =>
                        !o.createdAt.isBefore(dateRange.start) &&
                        !o.createdAt.isAfter(dateRange.end))
                    .toList()
                : orders;
            if (filtered.isEmpty) return _EmptyTable(lang: lang);
            return _OrdersTable(orders: filtered, lang: lang);
          },
        );

      default:
        return _EmptyTable(lang: lang);
    }
  }

  // ---------------------------------------------------------------------------
  // Export bar
  // ---------------------------------------------------------------------------

  Widget _buildExportBar(
    BuildContext context,
    AppLanguage lang,
    bool isFarmer,
    AsyncValue<AnalyticsModel> analyticsAsync,
  ) {
    final isLoading = ref.watch(reportsExportLoadingProvider);
    final dataset = ref.watch(reportsDatasetProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: isLoading ? null : () => _exportCsv(lang, dataset),
          icon: const Icon(Icons.table_chart_outlined, size: 18),
          label: Text(t('export_as_csv', lang)),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: isLoading
              ? null
              : () => _exportPdf(lang, isFarmer, analyticsAsync),
          icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
          label: Text(t('export_as_pdf', lang)),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () {
            ref.read(analyticsServiceProvider).logCtaClick(
                  ctaName: 'print_report',
                  screen: '/reports',
                );
            WebExportService.printPage();
          },
          icon: const Icon(Icons.print_outlined, size: 18),
          label: Text(t('print_report', lang)),
        ),
      ],
    );
  }

  Future<void> _exportCsv(AppLanguage lang, String dataset) async {
    ref.read(analyticsServiceProvider).logCtaClick(
          ctaName: 'export_csv',
          screen: '/reports',
        );
    ref.read(reportsExportLoadingProvider.notifier).state = true;
    try {
      String csv;
      String filename;
      final dateRange = ref.read(reportsDateRangeProvider);

      switch (dataset) {
        case 'crops':
          final crops = ref.read(cropControllerProvider).valueOrNull ?? [];
          final filtered = dateRange != null
              ? crops
                  .where((c) =>
                      !c.plantingDate.isBefore(dateRange.start) &&
                      !c.plantingDate.isAfter(dateRange.end))
                  .toList()
              : crops;
          if (filtered.isEmpty) {
            _showSnackBar(t('no_data_to_export', lang));
            return;
          }
          csv = WebExportService.cropsAsCsv(filtered, lang);
          filename = WebExportService.csvFilename('crops');
        case 'harvests':
          final harvests = ref.read(harvestControllerProvider).valueOrNull ?? [];
          final filtered = dateRange != null
              ? harvests
                  .where((h) =>
                      !h.harvestDate.isBefore(dateRange.start) &&
                      !h.harvestDate.isAfter(dateRange.end))
                  .toList()
              : harvests;
          if (filtered.isEmpty) {
            _showSnackBar(t('no_data_to_export', lang));
            return;
          }
          csv = WebExportService.harvestsAsCsv(filtered, lang);
          filename = WebExportService.csvFilename('harvests');
        case 'inventory':
          final items = ref.read(inventoryControllerProvider).valueOrNull ?? [];
          final filtered = dateRange != null
              ? items
                  .where((i) =>
                      !i.storageDate.isBefore(dateRange.start) &&
                      !i.storageDate.isAfter(dateRange.end))
                  .toList()
              : items;
          if (filtered.isEmpty) {
            _showSnackBar(t('no_data_to_export', lang));
            return;
          }
          csv = WebExportService.inventoryAsCsv(filtered, lang);
          filename = WebExportService.csvFilename('inventory');
        case 'purchases':
          final purchases =
              ref.read(purchasesControllerProvider).valueOrNull ?? [];
          final filtered = dateRange != null
              ? purchases
                  .where((p) =>
                      !p.purchaseDate.isBefore(dateRange.start) &&
                      !p.purchaseDate.isAfter(dateRange.end))
                  .toList()
              : purchases;
          if (filtered.isEmpty) {
            _showSnackBar(t('no_data_to_export', lang));
            return;
          }
          csv = WebExportService.purchasesAsCsv(filtered, lang);
          filename = WebExportService.csvFilename('purchases');
        case 'orders':
          final orders = ref.read(ordersControllerProvider).valueOrNull ?? [];
          final filtered = dateRange != null
              ? orders
                  .where((o) =>
                      !o.createdAt.isBefore(dateRange.start) &&
                      !o.createdAt.isAfter(dateRange.end))
                  .toList()
              : orders;
          if (filtered.isEmpty) {
            _showSnackBar(t('no_data_to_export', lang));
            return;
          }
          csv = WebExportService.ordersAsCsv(filtered, lang);
          filename = WebExportService.csvFilename('orders');
        default:
          return;
      }

      WebExportService.downloadCsv(csv, filename);
      if (mounted) _showSnackBar(t('export_success', lang));
    } catch (e) {
      if (mounted) _showSnackBar(t('export_error', lang), isError: true);
    } finally {
      ref.read(reportsExportLoadingProvider.notifier).state = false;
    }
  }

  Future<void> _exportPdf(
    AppLanguage lang,
    bool isFarmer,
    AsyncValue<AnalyticsModel> analyticsAsync,
  ) async {
    final analytics = analyticsAsync.valueOrNull;
    if (analytics == null) {
      _showSnackBar(t('no_data_to_export', lang));
      return;
    }

    ref.read(analyticsServiceProvider).logCtaClick(
          ctaName: 'export_pdf',
          screen: '/reports',
        );
    ref.read(reportsExportLoadingProvider.notifier).state = true;
    try {
      final period = ref.read(analyticsPeriodProvider);
      final dateRange = ref.read(reportsDateRangeProvider);
      final df = DateFormat('dd MMM yyyy');
      final periodLabel = period == AnalyticsPeriod.custom && dateRange != null
          ? '${df.format(dateRange.start)} — ${df.format(dateRange.end)}'
          : t(period.name, lang);

      Uint8List pdfBytes;
      String filename;

      if (isFarmer) {
        pdfBytes = await WebExportService.buildFarmSummaryPdf(
          crops: ref.read(cropControllerProvider).valueOrNull ?? [],
          harvests: ref.read(harvestControllerProvider).valueOrNull ?? [],
          inventory: ref.read(inventoryControllerProvider).valueOrNull ?? [],
          analytics: analytics,
          lang: lang,
          periodLabel: periodLabel,
        );
        filename = WebExportService.pdfFilename('farm');
      } else {
        pdfBytes = await WebExportService.buildBusinessSummaryPdf(
          purchases: ref.read(purchasesControllerProvider).valueOrNull ?? [],
          orders: ref.read(ordersControllerProvider).valueOrNull ?? [],
          inventory: ref.read(inventoryControllerProvider).valueOrNull ?? [],
          analytics: analytics,
          lang: lang,
          periodLabel: periodLabel,
        );
        filename = WebExportService.pdfFilename('business');
      }

      await WebExportService.downloadPdf(pdfBytes, filename);
      if (mounted) _showSnackBar(t('export_success', lang));
    } catch (e) {
      if (mounted) _showSnackBar(t('export_error', lang), isError: true);
    } finally {
      ref.read(reportsExportLoadingProvider.notifier).state = false;
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final colors = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colors.error : null,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Formatters
  // ---------------------------------------------------------------------------

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return 'P${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return 'P${(amount / 1000).toStringAsFixed(1)}K';
    }
    return 'P${amount.toStringAsFixed(2)}';
  }

  String _formatWeight(double kg) {
    if (kg >= 1000) return '${(kg / 1000).toStringAsFixed(1)}t';
    return '${kg.toStringAsFixed(1)}kg';
  }

  String _formatArea(double hectares) => '${hectares.toStringAsFixed(1)}ha';
}

// =============================================================================
// Data tables (private, self-contained)
// =============================================================================

class _CropsTable extends StatelessWidget {
  const _CropsTable({required this.crops, required this.lang});
  final List<CropModel> crops;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy');
    final colors = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor:
            WidgetStateProperty.all(colors.surfaceContainerHighest),
        columns: [
          DataColumn(label: Text(t('crop_type', lang))),
          DataColumn(label: Text(t('field_name', lang))),
          DataColumn(label: Text(t('field_size', lang))),
          DataColumn(label: Text(t('planting_date', lang))),
          DataColumn(label: Text(t('expected_harvest_date', lang))),
          DataColumn(label: Text(t('estimated_yield', lang))),
        ],
        rows: crops
            .map((c) => DataRow(cells: [
                  DataCell(Text(c.cropType)),
                  DataCell(Text(c.fieldName)),
                  DataCell(Text('${c.fieldSize} ${c.fieldSizeUnit}')),
                  DataCell(Text(df.format(c.plantingDate))),
                  DataCell(Text(df.format(c.expectedHarvestDate))),
                  DataCell(Text('${c.estimatedYield} ${c.yieldUnit}')),
                ]))
            .toList(),
      ),
    );
  }
}

class _HarvestsTable extends StatelessWidget {
  const _HarvestsTable({required this.harvests, required this.lang});
  final List<HarvestModel> harvests;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy');
    final colors = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor:
            WidgetStateProperty.all(colors.surfaceContainerHighest),
        columns: [
          DataColumn(label: Text(t('harvest_date', lang))),
          DataColumn(label: Text(t('actual_yield', lang))),
          DataColumn(label: Text(t('quality', lang))),
          DataColumn(label: Text(t('loss_amount', lang))),
          DataColumn(label: Text(t('storage_location', lang))),
        ],
        rows: harvests
            .map((h) => DataRow(cells: [
                  DataCell(Text(df.format(h.harvestDate))),
                  DataCell(Text('${h.actualYield} ${h.yieldUnit}')),
                  DataCell(Text(h.quality)),
                  DataCell(Text(
                    h.lossAmount != null ? '${h.lossAmount} ${h.yieldUnit}' : '-',
                  )),
                  DataCell(Text(h.storageLocation)),
                ]))
            .toList(),
      ),
    );
  }
}

class _InventoryTable extends StatelessWidget {
  const _InventoryTable({required this.items, required this.lang});
  final List<InventoryModel> items;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy');
    final colors = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor:
            WidgetStateProperty.all(colors.surfaceContainerHighest),
        columns: [
          DataColumn(label: Text(t('crop_type', lang))),
          DataColumn(label: Text(t('quantity', lang))),
          DataColumn(label: Text(t('storage_date', lang))),
          DataColumn(label: Text(t('storage_location', lang))),
          DataColumn(label: Text(t('condition', lang))),
        ],
        rows: items
            .map((i) => DataRow(cells: [
                  DataCell(Text(i.cropType)),
                  DataCell(Text('${i.quantity} ${i.unit}')),
                  DataCell(Text(df.format(i.storageDate))),
                  DataCell(Text(i.storageLocation)),
                  DataCell(Text(i.condition)),
                ]))
            .toList(),
      ),
    );
  }
}

class _PurchasesTable extends StatelessWidget {
  const _PurchasesTable({required this.purchases, required this.lang});
  final List<PurchaseModel> purchases;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy');
    final nf = NumberFormat.currency(symbol: 'P');
    final colors = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor:
            WidgetStateProperty.all(colors.surfaceContainerHighest),
        columns: [
          DataColumn(label: Text(t('seller_name', lang))),
          DataColumn(label: Text(t('crop_type', lang))),
          DataColumn(label: Text(t('quantity', lang))),
          DataColumn(label: Text(t('total_amount', lang))),
          DataColumn(label: Text(t('purchase_date', lang))),
        ],
        rows: purchases
            .map((p) => DataRow(cells: [
                  DataCell(Text(p.sellerName)),
                  DataCell(Text(p.cropType)),
                  DataCell(Text('${p.quantity} ${p.unit}')),
                  DataCell(Text(nf.format(p.totalAmount))),
                  DataCell(Text(df.format(p.purchaseDate))),
                ]))
            .toList(),
      ),
    );
  }
}

class _OrdersTable extends StatelessWidget {
  const _OrdersTable({required this.orders, required this.lang});
  final List<OrderModel> orders;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy');
    final nf = NumberFormat.currency(symbol: 'P');
    final colors = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor:
            WidgetStateProperty.all(colors.surfaceContainerHighest),
        columns: [
          DataColumn(label: Text(t('order_id', lang))),
          DataColumn(label: Text(t('status', lang))),
          DataColumn(label: Text(t('total_amount', lang))),
          DataColumn(label: Text(t('created_at', lang))),
        ],
        rows: orders
            .map((o) => DataRow(cells: [
                  DataCell(Text(o.id ?? '-')),
                  DataCell(Text(o.status)),
                  DataCell(Text(nf.format(o.totalAmount))),
                  DataCell(Text(df.format(o.createdAt))),
                ]))
            .toList(),
      ),
    );
  }
}

// =============================================================================
// Small helper widgets
// =============================================================================

class _EmptyTable extends StatelessWidget {
  const _EmptyTable({required this.lang});
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          t('no_data', lang),
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _HarvestsNoCropHint extends StatelessWidget {
  const _HarvestsNoCropHint({required this.lang});
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.agriculture_outlined,
            size: 40,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            t('select_crop_to_view_harvests', lang),
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.lang});
  final String message;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        message,
        style:
            TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13),
      ),
    );
  }
}

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
          Text(message,
              style: TextStyle(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center),
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

// =============================================================================
// Charts (reused from dashboard patterns)
// =============================================================================

class _RevenueBarChart extends StatelessWidget {
  const _RevenueBarChart({
    required this.periodRevenue,
    required this.periodPurchases,
    required this.lang,
  });
  final double periodRevenue;
  final double periodPurchases;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final maxY =
        [periodRevenue, periodPurchases].reduce((a, b) => a > b ? a : b) * 1.3;

    return BarChart(BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxY > 0 ? maxY : 1,
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final label =
                groupIndex == 0 ? t('revenue', lang) : t('purchases', lang);
            return BarTooltipItem(
              '$label\nP${rod.toY.toStringAsFixed(0)}',
              TextStyle(color: colors.onInverseSurface, fontSize: 12),
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final label = value.toInt() == 0
                  ? t('revenue', lang)
                  : t('purchases', lang);
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(label,
                    style: TextStyle(
                        color: colors.onSurfaceVariant, fontSize: 12)),
              );
            },
          ),
        ),
        leftTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      gridData: const FlGridData(show: false),
      barGroups: [
        BarChartGroupData(x: 0, barRods: [
          BarChartRodData(
            toY: periodRevenue,
            color: colors.primary,
            width: 40,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ]),
        BarChartGroupData(x: 1, barRods: [
          BarChartRodData(
            toY: periodPurchases,
            color: colors.tertiary,
            width: 40,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ]),
      ],
    ));
  }
}

class _InventoryPieChart extends StatelessWidget {
  const _InventoryPieChart({
    required this.total,
    required this.critical,
    required this.activeListings,
    required this.lang,
  });
  final int total;
  final int critical;
  final int activeListings;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final healthy = total - critical;

    if (total == 0 && activeListings == 0) {
      return Center(
          child: Text(t('no_data', lang),
              style: TextStyle(color: colors.onSurfaceVariant)));
    }

    return Row(
      children: [
        Expanded(
          child: PieChart(PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 36,
            sections: [
              PieChartSectionData(
                value: healthy.toDouble(),
                color: colors.primary,
                title: '$healthy',
                titleStyle: TextStyle(
                    color: colors.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
                radius: 50,
              ),
              if (critical > 0)
                PieChartSectionData(
                  value: critical.toDouble(),
                  color: colors.error,
                  title: '$critical',
                  titleStyle: TextStyle(
                      color: colors.onError,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                  radius: 50,
                ),
              PieChartSectionData(
                value: activeListings.toDouble(),
                color: colors.tertiary,
                title: '$activeListings',
                titleStyle: TextStyle(
                    color: colors.onTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
                radius: 50,
              ),
            ],
          )),
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LegendItem(color: colors.primary, label: t('healthy_stock', lang)),
            const SizedBox(height: 8),
            if (critical > 0) ...[
              _LegendItem(
                  color: colors.error, label: t('critical_items', lang)),
              const SizedBox(height: 8),
            ],
            _LegendItem(
                color: colors.tertiary, label: t('active_listings', lang)),
          ],
        ),
      ],
    );
  }
}

class _CropPieChart extends StatelessWidget {
  const _CropPieChart({
    required this.active,
    required this.harvested,
    required this.lang,
  });
  final int active;
  final int harvested;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (active == 0 && harvested == 0) {
      return Center(
          child: Text(t('no_data', lang),
              style: TextStyle(color: colors.onSurfaceVariant)));
    }

    return Row(
      children: [
        Expanded(
          child: PieChart(PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 36,
            sections: [
              PieChartSectionData(
                value: active.toDouble(),
                color: colors.primary,
                title: '$active',
                titleStyle: TextStyle(
                    color: colors.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
                radius: 50,
              ),
              PieChartSectionData(
                value: harvested.toDouble(),
                color: colors.tertiary,
                title: '$harvested',
                titleStyle: TextStyle(
                    color: colors.onTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
                radius: 50,
              ),
            ],
          )),
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LegendItem(color: colors.primary, label: t('active_crops', lang)),
            const SizedBox(height: 8),
            _LegendItem(color: colors.tertiary, label: t('harvested', lang)),
          ],
        ),
      ],
    );
  }
}

class _YieldLossBarChart extends StatelessWidget {
  const _YieldLossBarChart({
    required this.totalYield,
    required this.totalLoss,
    required this.lang,
  });
  final double totalYield;
  final double totalLoss;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final maxY =
        [totalYield, totalLoss].reduce((a, b) => a > b ? a : b) * 1.3;

    return BarChart(BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxY > 0 ? maxY : 1,
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final label = groupIndex == 0
                ? t('total_yield', lang)
                : t('total_loss', lang);
            return BarTooltipItem(
              '$label\n${rod.toY.toStringAsFixed(1)}kg',
              TextStyle(color: colors.onInverseSurface, fontSize: 12),
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final label = value.toInt() == 0
                  ? t('total_yield', lang)
                  : t('total_loss', lang);
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(label,
                    style: TextStyle(
                        color: colors.onSurfaceVariant, fontSize: 12)),
              );
            },
          ),
        ),
        leftTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      gridData: const FlGridData(show: false),
      barGroups: [
        BarChartGroupData(x: 0, barRods: [
          BarChartRodData(
            toY: totalYield,
            color: colors.primary,
            width: 40,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ]),
        BarChartGroupData(x: 1, barRods: [
          BarChartRodData(
            toY: totalLoss,
            color: colors.error,
            width: 40,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ]),
      ],
    ));
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
