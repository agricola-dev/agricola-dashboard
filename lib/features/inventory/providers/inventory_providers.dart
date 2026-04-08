import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/network/http_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides an [InventoryApiService] backed by the authenticated Dio client.
final inventoryApiServiceProvider = Provider<InventoryApiService>((ref) {
  return InventoryApiService(ref.watch(httpClientProvider));
});

/// Sort fields for inventory table columns.
enum InventorySortField {
  cropType,
  quantity,
  storageDate,
}

/// Sort configuration: field + direction.
class InventorySort {
  const InventorySort({
    this.field = InventorySortField.cropType,
    this.ascending = true,
  });

  final InventorySortField field;
  final bool ascending;

  InventorySort copyWith({InventorySortField? field, bool? ascending}) {
    return InventorySort(
      field: field ?? this.field,
      ascending: ascending ?? this.ascending,
    );
  }
}

/// Set of selected inventory item IDs for bulk actions.
final selectedInventoryIdsProvider = StateProvider<Set<String>>((_) => {});

/// Search text for filtering inventory items.
final inventorySearchProvider = StateProvider<String>((_) => '');

/// Current sort configuration.
final inventorySortProvider = StateProvider<InventorySort>(
  (_) => const InventorySort(),
);

/// Inventory list controller — owns CRUD operations.
final inventoryControllerProvider =
    AsyncNotifierProvider<InventoryController, List<InventoryModel>>(
  InventoryController.new,
);

class InventoryController extends AsyncNotifier<List<InventoryModel>> {
  @override
  Future<List<InventoryModel>> build() async {
    final service = ref.watch(inventoryApiServiceProvider);
    return service.getUserInventory();
  }

  /// Creates a new inventory item. Returns null on success, error message on failure.
  Future<String?> addInventory(InventoryModel item) async {
    try {
      final service = ref.read(inventoryApiServiceProvider);
      await service.createInventory(item);
      ref.invalidateSelf();
      await future;
      return null;
    } catch (e) {
      return 'error_save_failed';
    }
  }

  /// Updates an existing inventory item. Returns null on success, error message on failure.
  Future<String?> updateInventory(String id, InventoryModel item) async {
    try {
      final service = ref.read(inventoryApiServiceProvider);
      await service.updateInventory(id, item);
      ref.invalidateSelf();
      await future;
      return null;
    } catch (e) {
      return 'error_update_failed';
    }
  }

  /// Deletes an inventory item. Returns null on success, error message on failure.
  Future<String?> deleteInventory(String id) async {
    try {
      final service = ref.read(inventoryApiServiceProvider);
      await service.deleteInventory(id);
      ref.invalidateSelf();
      await future;
      return null;
    } catch (e) {
      return 'error_delete_failed';
    }
  }

  /// Bulk delete selected items. Returns null on success, error message on failure.
  Future<String?> bulkDeleteInventory(List<String> ids) async {
    try {
      final service = ref.read(inventoryApiServiceProvider);
      await service.bulkDeleteInventory(ids);
      ref.invalidateSelf();
      await future;
      return null;
    } catch (e) {
      return 'error_bulk_delete_failed';
    }
  }

  /// Bulk update condition. Returns null on success, error message on failure.
  Future<String?> bulkUpdateCondition(
      List<String> ids, String condition) async {
    try {
      final service = ref.read(inventoryApiServiceProvider);
      await service.bulkUpdateCondition(ids, condition);
      ref.invalidateSelf();
      await future;
      return null;
    } catch (e) {
      return 'error_bulk_update_failed';
    }
  }
}

/// Derived provider that filters by search text and sorts the inventory list.
final filteredInventoryProvider = Provider<AsyncValue<List<InventoryModel>>>((ref) {
  final asyncItems = ref.watch(inventoryControllerProvider);
  final search = ref.watch(inventorySearchProvider).toLowerCase();
  final sort = ref.watch(inventorySortProvider);

  return asyncItems.whenData((items) {
    // Filter
    var filtered = items;
    if (search.isNotEmpty) {
      filtered = items.where((item) {
        return item.cropType.toLowerCase().contains(search) ||
            item.storageLocation.toLowerCase().contains(search) ||
            item.condition.toLowerCase().contains(search);
      }).toList();
    }

    // Sort
    filtered = List.of(filtered);
    filtered.sort((a, b) {
      int result;
      switch (sort.field) {
        case InventorySortField.cropType:
          result = a.cropType.compareTo(b.cropType);
        case InventorySortField.quantity:
          result = a.quantity.compareTo(b.quantity);
        case InventorySortField.storageDate:
          result = a.storageDate.compareTo(b.storageDate);
      }
      return sort.ascending ? result : -result;
    });

    return filtered;
  });
});
