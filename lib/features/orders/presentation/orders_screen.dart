import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/providers/language_provider.dart';
import 'package:agricola_dashboard/core/widgets/app_text_field.dart';
import 'package:agricola_dashboard/features/orders/presentation/order_detail_dialog.dart';
import 'package:agricola_dashboard/features/orders/presentation/widgets/order_status_badge.dart';
import 'package:agricola_dashboard/features/orders/providers/orders_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Order statuses for the filter dropdown.
const _statusOptions = [
  'pending',
  'confirmed',
  'shipped',
  'delivered',
  'cancelled',
];

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final filteredAsync = ref.watch(filteredOrdersProvider);
    final sort = ref.watch(ordersSortProvider);

    return filteredAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorView(
        message: error.toString(),
        onRetry: () => ref.invalidate(ordersControllerProvider),
        lang: lang,
      ),
      data: (orders) => _OrdersContent(
        orders: orders,
        sort: sort,
        lang: lang,
      ),
    );
  }
}

class _OrdersContent extends ConsumerWidget {
  const _OrdersContent({
    required this.orders,
    required this.sort,
    required this.lang,
  });

  final List<OrderModel> orders;
  final OrderSort sort;
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
          if (orders.isEmpty)
            const _EmptyState()
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
    final statusFilter = ref.watch(ordersStatusFilterProvider);

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
              t('orders', lang),
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Chip(
              label: Text('${orders.length}'),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        // Search + Status filter
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 260,
              child: AppTextField(
                label: t('search', lang),
                prefixIcon: Icons.search,
                onChanged: (value) =>
                    ref.read(ordersSearchProvider.notifier).state = value,
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<String?>(
              value: statusFilter,
              hint: Text(t('filter_by_status', lang)),
              onChanged: (value) =>
                  ref.read(ordersStatusFilterProvider.notifier).state = value,
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(t('all_statuses', lang)),
                ),
                ..._statusOptions.map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(t(s, lang)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
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
          DataColumn(label: Text(t('order_id', lang))),
          DataColumn(label: Text(t('order_items', lang)), numeric: true),
          DataColumn(
            label: Text(t('total_amount', lang)),
            numeric: true,
            onSort: (_, ascending) =>
                _onSort(ref, OrderSortField.totalAmount, ascending),
          ),
          DataColumn(
            label: Text(t('status', lang)),
            onSort: (_, ascending) =>
                _onSort(ref, OrderSortField.status, ascending),
          ),
          DataColumn(
            label: Text(t('order_date', lang)),
            onSort: (_, ascending) =>
                _onSort(ref, OrderSortField.createdAt, ascending),
          ),
          DataColumn(label: Text(t('actions', lang))),
        ],
        rows: orders.map((order) {
          final truncatedId = order.id != null && order.id!.length > 8
              ? '${order.id!.substring(0, 8)}...'
              : order.id ?? '-';

          return DataRow(cells: [
            DataCell(
              Tooltip(
                message: order.id ?? '',
                child: Text(truncatedId),
              ),
            ),
            DataCell(Text('${order.items.length}')),
            DataCell(Text('P${order.totalAmount.toStringAsFixed(2)}')),
            DataCell(OrderStatusBadge(status: order.status, lang: lang)),
            DataCell(Text(dateFormat.format(order.createdAt))),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, size: 20),
                    tooltip: t('order_detail', lang),
                    onPressed: () => _viewOrder(context, ref, order),
                  ),
                  ..._buildQuickActions(context, ref, order, colors),
                ],
              ),
            ),
          ]);
        }).toList(),
      ),
    );
  }

  List<Widget> _buildQuickActions(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
    ColorScheme colors,
  ) {
    final next = nextStatuses(order.status);
    if (next.isEmpty) return [];

    return next.map((status) {
      if (status == 'cancelled') {
        return IconButton(
          icon: Icon(Icons.cancel_outlined, size: 20, color: colors.error),
          tooltip: t('cancel_order', lang),
          onPressed: () => _updateStatus(context, ref, order.id!, status),
        );
      }

      final (icon, tooltip) = switch (status) {
        'confirmed' => (Icons.check_circle_outlined, 'confirm_order'),
        'shipped' => (Icons.local_shipping_outlined, 'ship_order'),
        'delivered' => (Icons.done_all, 'mark_delivered'),
        _ => (Icons.update, status),
      };

      return IconButton(
        icon: Icon(icon, size: 20),
        tooltip: t(tooltip, lang),
        onPressed: () => _updateStatus(context, ref, order.id!, status),
      );
    }).toList();
  }

  void _onSort(WidgetRef ref, OrderSortField field, bool ascending) {
    ref.read(ordersSortProvider.notifier).state = OrderSort(
      field: field,
      ascending: ascending,
    );
  }

  Future<void> _viewOrder(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
  ) async {
    final newStatus = await showOrderDetailDialog(
      context,
      order: order,
      lang: lang,
    );

    if (newStatus == null || order.id == null || !context.mounted) return;
    _updateStatus(context, ref, order.id!, newStatus);
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    String orderId,
    String status,
  ) async {
    final String? error;
    final String successKey;

    if (status == 'cancelled') {
      error = await ref
          .read(ordersControllerProvider.notifier)
          .cancelOrder(orderId);
      successKey = 'order_cancelled';
    } else {
      error = await ref
          .read(ordersControllerProvider.notifier)
          .updateStatus(orderId, status);
      successKey = 'status_updated';
    }

    if (!context.mounted) return;
    _showResultSnackBar(context, error: error, successKey: successKey);
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

class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final lang = ref.watch(languageProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: colors.outline),
            const SizedBox(height: 16),
            Text(
              t('no_orders', lang),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              t('no_orders_hint', lang),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
            t('error_loading_orders', lang),
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
