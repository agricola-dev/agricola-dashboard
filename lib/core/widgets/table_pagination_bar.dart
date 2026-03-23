import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/providers/pagination_provider.dart';
import 'package:flutter/material.dart';

/// Pagination controls displayed below a DataTable.
///
/// Shows "Showing X–Y of Z", a rows-per-page dropdown, and prev/next buttons.
class TablePaginationBar extends StatelessWidget {
  const TablePaginationBar({
    super.key,
    required this.totalItems,
    required this.pagination,
    required this.onPageChanged,
    required this.onRowsPerPageChanged,
    required this.lang,
  });

  final int totalItems;
  final PaginationState pagination;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onRowsPerPageChanged;
  final AppLanguage lang;

  static const _rowOptions = [10, 25, 50];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant,
        );

    final start = totalItems == 0
        ? 0
        : pagination.currentPage * pagination.rowsPerPage + 1;
    final end =
        ((pagination.currentPage + 1) * pagination.rowsPerPage).clamp(0, totalItems);
    final lastPage =
        totalItems == 0 ? 0 : ((totalItems - 1) ~/ pagination.rowsPerPage);

    final label = t('showing_x_of_y', lang)
        .replaceAll('{start}', '$start')
        .replaceAll('{end}', '$end')
        .replaceAll('{total}', '$totalItems');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label, style: textStyle),
          const Spacer(),
          Text(t('rows_per_page', lang), style: textStyle),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: pagination.rowsPerPage,
            underline: const SizedBox.shrink(),
            items: _rowOptions
                .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                .toList(),
            onChanged: (value) {
              if (value != null) onRowsPerPageChanged(value);
            },
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: t('previous', lang),
            onPressed: pagination.currentPage > 0
                ? () => onPageChanged(pagination.currentPage - 1)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: t('next', lang),
            onPressed: pagination.currentPage < lastPage
                ? () => onPageChanged(pagination.currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }
}
