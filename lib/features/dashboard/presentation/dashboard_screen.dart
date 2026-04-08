import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/providers/language_provider.dart';
import 'package:agricola_dashboard/core/widgets/chart_card.dart';
import 'package:agricola_dashboard/core/widgets/period_filter.dart';
import 'package:agricola_dashboard/core/widgets/stat_card.dart';
import 'package:agricola_dashboard/features/auth/providers/auth_providers.dart';
import 'package:agricola_dashboard/features/dashboard/providers/dashboard_controller.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final user = ref.watch(currentUserProvider);
    final analyticsAsync = ref.watch(analyticsProvider);

    return analyticsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorView(
        message: t('error_try_again', lang),
        onRetry: () => ref.invalidate(analyticsProvider),
        lang: lang,
      ),
      data: (analytics) => _DashboardContent(
        analytics: analytics,
        lang: lang,
        userType: user?.userType ?? UserType.merchant,
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.analytics,
    required this.lang,
    required this.userType,
  });

  final AnalyticsModel analytics;
  final AppLanguage lang;
  final UserType userType;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildStatsGrid(context),
          const SizedBox(height: 32),
          _buildChartsSection(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('dashboard', lang),
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                t('dashboard_subtitle', lang),
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const PeriodFilter(),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    final cards = userType == UserType.merchant
        ? _merchantCards()
        : _farmerCards();

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

  List<Widget> _merchantCards() {
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

  List<Widget> _farmerCards() {
    return [
      StatCard(
        icon: Icons.grass_outlined,
        label: t('active_crops', lang),
        value: '${analytics.crops.active}',
        subtitle:
            '${analytics.crops.harvested} ${t('harvested', lang)}',
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

  Widget _buildChartsSection(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;

        final charts = userType == UserType.merchant
            ? _merchantCharts()
            : _farmerCharts();

        if (isWide) {
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
              .map((chart) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: chart,
                  ))
              .toList(),
        );
      },
    );
  }

  List<Widget> _merchantCharts() {
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

  List<Widget> _farmerCharts() {
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

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return 'P${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return 'P${(amount / 1000).toStringAsFixed(1)}K';
    }
    return 'P${amount.toStringAsFixed(2)}';
  }

  String _formatWeight(double kg) {
    if (kg >= 1000) {
      return '${(kg / 1000).toStringAsFixed(1)}t';
    }
    return '${kg.toStringAsFixed(1)}kg';
  }

  String _formatArea(double hectares) {
    return '${hectares.toStringAsFixed(1)}ha';
  }
}

// ---------------------------------------------------------------------------
// Revenue vs Purchases bar chart (Merchant)
// ---------------------------------------------------------------------------

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

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: [periodRevenue, periodPurchases]
                .reduce((a, b) => a > b ? a : b) *
            1.3,
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
                  child: Text(
                    label,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Inventory donut chart (Merchant)
// ---------------------------------------------------------------------------

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
        child: Text(
          t('no_data', lang),
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
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
                    fontWeight: FontWeight.bold,
                  ),
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
                      fontWeight: FontWeight.bold,
                    ),
                    radius: 50,
                  ),
                PieChartSectionData(
                  value: activeListings.toDouble(),
                  color: colors.tertiary,
                  title: '$activeListings',
                  titleStyle: TextStyle(
                    color: colors.onTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  radius: 50,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LegendItem(
              color: colors.primary,
              label: t('healthy_stock', lang),
            ),
            const SizedBox(height: 8),
            if (critical > 0) ...[
              _LegendItem(
                color: colors.error,
                label: t('critical_items', lang),
              ),
              const SizedBox(height: 8),
            ],
            _LegendItem(
              color: colors.tertiary,
              label: t('active_listings', lang),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Crop status donut chart (Farmer)
// ---------------------------------------------------------------------------

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
        child: Text(
          t('no_data', lang),
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
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
                    fontWeight: FontWeight.bold,
                  ),
                  radius: 50,
                ),
                PieChartSectionData(
                  value: harvested.toDouble(),
                  color: colors.tertiary,
                  title: '$harvested',
                  titleStyle: TextStyle(
                    color: colors.onTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  radius: 50,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LegendItem(
              color: colors.primary,
              label: t('active_crops', lang),
            ),
            const SizedBox(height: 8),
            _LegendItem(
              color: colors.tertiary,
              label: t('harvested', lang),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Yield vs Loss bar chart (Farmer)
// ---------------------------------------------------------------------------

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

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: [totalYield, totalLoss].reduce((a, b) => a > b ? a : b) * 1.3,
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
                  child: Text(
                    label,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared legend item
// ---------------------------------------------------------------------------

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
            message,
            style: TextStyle(color: colors.onSurfaceVariant),
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
