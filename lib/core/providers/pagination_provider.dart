import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Immutable pagination state for a data table.
class PaginationState {
  const PaginationState({
    this.currentPage = 0,
    this.rowsPerPage = 10,
  });

  final int currentPage;
  final int rowsPerPage;

  PaginationState copyWith({int? currentPage, int? rowsPerPage}) {
    return PaginationState(
      currentPage: currentPage ?? this.currentPage,
      rowsPerPage: rowsPerPage ?? this.rowsPerPage,
    );
  }
}

/// Family provider keyed by table name (e.g. `'inventory'`, `'orders'`).
final paginationProvider = StateProvider.family<PaginationState, String>(
  (_, __) => const PaginationState(),
);

/// Returns the sublist of [items] for the current page described by [pagination].
List<T> paginateList<T>(List<T> items, PaginationState pagination) {
  final start = pagination.currentPage * pagination.rowsPerPage;
  if (start >= items.length) return [];
  final end = (start + pagination.rowsPerPage).clamp(0, items.length);
  return items.sublist(start, end);
}
