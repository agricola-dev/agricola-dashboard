import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/theme/app_theme.dart';
import 'package:agricola_dashboard/core/widgets/labeled_divider.dart';
import 'package:agricola_dashboard/features/loss_calculator/presentation/widgets/loss_severity_badge.dart';
import 'package:flutter/material.dart';

/// Shows a read-only detail dialog for a saved [LossCalculation].
Future<void> showLossDetailDialog(
  BuildContext context, {
  required LossCalculation calculation,
  required AppLanguage lang,
}) {
  return showDialog(
    context: context,
    builder: (context) => _LossDetailDialog(
      calculation: calculation,
      lang: lang,
    ),
  );
}

class _LossDetailDialog extends StatelessWidget {
  const _LossDetailDialog({
    required this.calculation,
    required this.lang,
  });

  final LossCalculation calculation;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final comparison = compareLossToRegional(
      calculation,
      calculation.cropCategory ?? 'default',
    );

    return AlertDialog(
      title: Row(
        children: [
          Expanded(
            child: Text(
              '${calculation.cropType} — ${_formatDate(calculation.calculationDate)}',
            ),
          ),
          LossSeverityBadge(
            lossPercentage: calculation.totalLossPercentage,
            lang: lang,
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary stats row
              _buildSummaryRow(colors, textTheme),
              const SizedBox(height: 24),

              // Stage breakdown
              LabeledDivider(label: t('loss_by_stage', lang)),
              const SizedBox(height: 12),
              ...calculation.stages.map(
                (stage) => _buildStageRow(stage, colors, textTheme),
              ),
              const SizedBox(height: 24),

              // Regional comparison
              LabeledDivider(label: t('regional_average', lang)),
              const SizedBox(height: 12),
              _buildComparison(comparison, colors, textTheme),
              const SizedBox(height: 24),

              // Prevention tips
              if (calculation.highestLossStage != null) ...[
                LabeledDivider(label: t('prevention_tips', lang)),
                const SizedBox(height: 12),
                _buildTips(calculation.highestLossStage!, textTheme),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t('close', lang)),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(ColorScheme colors, TextTheme textTheme) {
    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            label: t('total_harvest', lang),
            value: '${calculation.harvestAmount} ${calculation.unit}',
            colors: colors,
            textTheme: textTheme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniStat(
            label: t('total_loss', lang),
            value:
                '${calculation.totalLoss.toStringAsFixed(1)} ${calculation.unit}',
            colors: colors,
            textTheme: textTheme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniStat(
            label: t('loss_percentage', lang),
            value: '${calculation.totalLossPercentage.toStringAsFixed(1)}%',
            colors: colors,
            textTheme: textTheme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniStat(
            label: t('monetary_loss', lang),
            value: formatBWP(calculation.monetaryLoss),
            colors: colors,
            textTheme: textTheme,
          ),
        ),
      ],
    );
  }

  Widget _buildStageRow(
    LossStage stage,
    ColorScheme colors,
    TextTheme textTheme,
  ) {
    final isHighest = calculation.highestLossStage?.stage == stage.stage;
    final percentage = stage.percentage(calculation.harvestAmount);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isHighest)
                Icon(Icons.warning_amber, size: 16, color: colors.error),
              if (isHighest) const SizedBox(width: 4),
              Text(
                t('loss_stage_${stage.stage}', lang),
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: isHighest ? FontWeight.bold : FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '${stage.amount.toStringAsFixed(1)} ${calculation.unit} (${percentage.toStringAsFixed(1)}%)',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: isHighest ? FontWeight.bold : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: calculation.harvestAmount > 0
                ? stage.amount / calculation.harvestAmount
                : 0,
            borderRadius: BorderRadius.circular(4),
            color: isHighest ? colors.error : colors.primary,
            backgroundColor: colors.surfaceContainerHighest,
          ),
          if (stage.cause != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                t(stage.cause!, lang),
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildComparison(
    LossComparisonResult comparison,
    ColorScheme colors,
    TextTheme textTheme,
  ) {
    final isBetter = comparison.isBelowAverage;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(t('your_loss', lang), style: textTheme.bodyMedium),
            Text(
              '${comparison.userPercentage.toStringAsFixed(1)}%',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(t('regional_average', lang), style: textTheme.bodyMedium),
            Text(
              '${comparison.regionalAverage.toStringAsFixed(1)}%',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              isBetter ? Icons.trending_down : Icons.trending_up,
              size: 20,
              color: isBetter
                  ? BadgeColors.successForeground
                  : BadgeColors.cautionForeground,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t(isBetter ? 'below_average' : 'above_average', lang),
                style: textTheme.bodyMedium?.copyWith(
                  color: isBetter
                      ? BadgeColors.successForeground
                      : BadgeColors.cautionForeground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${comparison.difference.abs().toStringAsFixed(1)}%',
              style: textTheme.titleMedium?.copyWith(
                color: isBetter
                    ? BadgeColors.successForeground
                    : BadgeColors.cautionForeground,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Remaining value summary
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(t('remaining_amount', lang), style: textTheme.bodyMedium),
            Text(
              '${calculation.remainingAmount.toStringAsFixed(1)} ${calculation.unit}',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(t('remaining_value', lang), style: textTheme.bodyMedium),
            Text(
              formatBWP(calculation.remainingValue),
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: BadgeColors.successForeground,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTips(LossStage highestStage, TextTheme textTheme) {
    final tips = preventionTipKeys(highestStage.stage, calculation.storageMethod);

    return Column(
      children: tips
          .map(
            (tipKey) => ListTile(
              dense: true,
              leading: const Icon(Icons.lightbulb_outline, size: 20),
              title: Text(
                t(tipKey, lang),
                style: textTheme.bodyMedium,
              ),
            ),
          )
          .toList(),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// A compact stat display for the detail dialog summary row.
class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.colors,
    required this.textTheme,
  });

  final String label;
  final String value;
  final ColorScheme colors;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
