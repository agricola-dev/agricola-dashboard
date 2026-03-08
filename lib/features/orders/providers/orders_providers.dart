import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/network/http_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides an [OrdersApiService] backed by the authenticated Dio client.
final ordersApiServiceProvider = Provider<OrdersApiService>((ref) {
  return OrdersApiService(ref.watch(httpClientProvider));
});

// ---------------------------------------------------------------------------
// Sort
// ---------------------------------------------------------------------------

/// Sort fields for the orders table.
enum OrderSortField {
  createdAt,
  status,
  totalAmount,
}

/// Sort configuration: field + direction.
class OrderSort {
  const OrderSort({
    this.field = OrderSortField.createdAt,
    this.ascending = false,
  });

  final OrderSortField field;
  final bool ascending;

  OrderSort copyWith({OrderSortField? field, bool? ascending}) {
    return OrderSort(
      field: field ?? this.field,
      ascending: ascending ?? this.ascending,
    );
  }
}

// ---------------------------------------------------------------------------
// Filter / search state
// ---------------------------------------------------------------------------

/// Search text for filtering orders.
final ordersSearchProvider = StateProvider<String>((_) => '');

/// Current sort configuration for orders.
final ordersSortProvider = StateProvider<OrderSort>(
  (_) => const OrderSort(),
);

/// Status filter for orders (null = all statuses).
final ordersStatusFilterProvider = StateProvider<String?>((_) => null);

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

/// Controller for the current user's orders — owns fetch + status updates.
final ordersControllerProvider =
    AsyncNotifierProvider<OrdersController, List<OrderModel>>(
  OrdersController.new,
);

class OrdersController extends AsyncNotifier<List<OrderModel>> {
  @override
  Future<List<OrderModel>> build() async {
    final service = ref.watch(ordersApiServiceProvider);
    return service.getUserOrders(role: 'seller');
  }

  /// Updates an order's status. Returns null on success, error message on failure.
  Future<String?> updateStatus(String id, String status) async {
    try {
      final service = ref.read(ordersApiServiceProvider);
      await service.updateOrderStatus(id, status);
      ref.invalidateSelf();
      await future;
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Cancels an order. Returns null on success, error message on failure.
  Future<String?> cancelOrder(String id) async {
    try {
      final service = ref.read(ordersApiServiceProvider);
      await service.cancelOrder(id);
      ref.invalidateSelf();
      await future;
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

// ---------------------------------------------------------------------------
// Derived filtered + sorted provider
// ---------------------------------------------------------------------------

/// Derived provider that filters by search text, status, and sorts orders.
final filteredOrdersProvider =
    Provider<AsyncValue<List<OrderModel>>>((ref) {
  final asyncItems = ref.watch(ordersControllerProvider);
  final search = ref.watch(ordersSearchProvider).toLowerCase();
  final sort = ref.watch(ordersSortProvider);
  final statusFilter = ref.watch(ordersStatusFilterProvider);

  return asyncItems.whenData((items) {
    // Filter by status
    var filtered = items;
    if (statusFilter != null) {
      filtered = filtered.where((o) => o.status == statusFilter).toList();
    }

    // Filter by search text
    if (search.isNotEmpty) {
      filtered = filtered.where((order) {
        return order.status.toLowerCase().contains(search) ||
            order.id?.toLowerCase().contains(search) == true ||
            order.userId.toLowerCase().contains(search) ||
            order.items.any(
              (item) => item.title.toLowerCase().contains(search),
            );
      }).toList();
    }

    // Sort
    filtered = List.of(filtered);
    filtered.sort((a, b) {
      int result;
      switch (sort.field) {
        case OrderSortField.createdAt:
          result = a.createdAt.compareTo(b.createdAt);
        case OrderSortField.status:
          result = a.status.compareTo(b.status);
        case OrderSortField.totalAmount:
          result = a.totalAmount.compareTo(b.totalAmount);
      }
      return sort.ascending ? result : -result;
    });

    return filtered;
  });
});
