import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/features/orders/presentation/widgets/order_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Shows order detail dialog with items table and status actions.
Future<String?> showOrderDetailDialog(
  BuildContext context, {
  required OrderModel order,
  required AppLanguage lang,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _OrderDetailDialog(order: order, lang: lang),
  );
}

/// Valid next statuses for a given current status.
List<String> nextStatuses(String current) {
  return switch (current) {
    'pending' => ['confirmed', 'cancelled'],
    'confirmed' => ['shipped'],
    'shipped' => ['delivered'],
    _ => [],
  };
}

class _OrderDetailDialog extends StatelessWidget {
  const _OrderDetailDialog({required this.order, required this.lang});

  final OrderModel order;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return AlertDialog(
      title: Text(t('order_detail', lang)),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Order info
              _InfoRow(
                label: t('order_id', lang),
                value: order.id ?? '-',
              ),
              const SizedBox(height: 8),
              _InfoRow(
                label: t('buyer', lang),
                value: order.userId,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${t('status', lang)}: ',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  OrderStatusBadge(status: order.status, lang: lang),
                ],
              ),
              const SizedBox(height: 8),
              _InfoRow(
                label: t('order_date', lang),
                value: dateFormat.format(order.createdAt),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              // Items table
              Text(
                t('order_items', lang),
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    colors.surfaceContainerLow,
                  ),
                  columnSpacing: 24,
                  columns: [
                    DataColumn(label: Text(t('item_title', lang))),
                    DataColumn(
                      label: Text(t('quantity', lang)),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text(t('unit_price', lang)),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text(t('line_total', lang)),
                      numeric: true,
                    ),
                  ],
                  rows: order.items
                      .map(
                        (item) => DataRow(cells: [
                          DataCell(Text(item.title)),
                          DataCell(Text('${item.quantity}')),
                          DataCell(Text('P${item.price.toStringAsFixed(2)}')),
                          DataCell(Text(
                            'P${(item.price * item.quantity).toStringAsFixed(2)}',
                          )),
                        ]),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),

              // Total
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${t('order_total', lang)}: P${order.totalAmount.toStringAsFixed(2)}',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t('cancel', lang)),
        ),
        // Status action buttons
        ...nextStatuses(order.status).map(
          (status) => status == 'cancelled'
              ? OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.error,
                  ),
                  onPressed: () => Navigator.of(context).pop(status),
                  child: Text(t('cancel_order', lang)),
                )
              : FilledButton(
                  onPressed: () => Navigator.of(context).pop(status),
                  child: Text(t(_actionKey(status), lang)),
                ),
        ),
      ],
    );
  }

  String _actionKey(String status) {
    return switch (status) {
      'confirmed' => 'confirm_order',
      'shipped' => 'ship_order',
      'delivered' => 'mark_delivered',
      _ => status,
    };
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        Expanded(
          child: Text(value, style: textTheme.bodyMedium),
        ),
      ],
    );
  }
}
