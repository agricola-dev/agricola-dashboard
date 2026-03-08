import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/network/http_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides a [PurchasesApiService] backed by the authenticated Dio client.
final purchasesApiServiceProvider = Provider<PurchasesApiService>((ref) {
  return PurchasesApiService(ref.watch(httpClientProvider));
});

// ---------------------------------------------------------------------------
// Sort
// ---------------------------------------------------------------------------

/// Sort fields for the purchases table.
enum PurchaseSortField {
  purchaseDate,
  cropType,
  totalAmount,
}

/// Sort configuration: field + direction.
class PurchaseSort {
  const PurchaseSort({
    this.field = PurchaseSortField.purchaseDate,
    this.ascending = false,
  });

  final PurchaseSortField field;
  final bool ascending;

  PurchaseSort copyWith({PurchaseSortField? field, bool? ascending}) {
    return PurchaseSort(
      field: field ?? this.field,
      ascending: ascending ?? this.ascending,
    );
  }
}

// ---------------------------------------------------------------------------
// Filter / search state
// ---------------------------------------------------------------------------

/// Search text for filtering purchases.
final purchasesSearchProvider = StateProvider<String>((_) => '');

/// Current sort configuration for purchases.
final purchasesSortProvider = StateProvider<PurchaseSort>(
  (_) => const PurchaseSort(),
);

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

/// Controller for the current user's purchases — owns full CRUD.
final purchasesControllerProvider =
    AsyncNotifierProvider<PurchasesController, List<PurchaseModel>>(
  PurchasesController.new,
);

class PurchasesController extends AsyncNotifier<List<PurchaseModel>> {
  @override
  Future<List<PurchaseModel>> build() async {
    final service = ref.watch(purchasesApiServiceProvider);
    return service.getPurchases();
  }

  /// Creates a new purchase. Returns null on success, error message on failure.
  Future<String?> addPurchase(PurchaseModel purchase) async {
    try {
      final service = ref.read(purchasesApiServiceProvider);
      await service.createPurchase(purchase);
      ref.invalidateSelf();
      await future;
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Updates an existing purchase. Returns null on success, error message on failure.
  Future<String?> updatePurchase(String id, PurchaseModel purchase) async {
    try {
      final service = ref.read(purchasesApiServiceProvider);
      await service.updatePurchase(id, purchase);
      ref.invalidateSelf();
      await future;
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Deletes a purchase. Returns null on success, error message on failure.
  Future<String?> deletePurchase(String id) async {
    try {
      final service = ref.read(purchasesApiServiceProvider);
      await service.deletePurchase(id);
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

/// Derived provider that filters by search text and sorts purchases.
final filteredPurchasesProvider =
    Provider<AsyncValue<List<PurchaseModel>>>((ref) {
  final asyncItems = ref.watch(purchasesControllerProvider);
  final search = ref.watch(purchasesSearchProvider).toLowerCase();
  final sort = ref.watch(purchasesSortProvider);

  return asyncItems.whenData((items) {
    // Filter by search text
    var filtered = items;
    if (search.isNotEmpty) {
      filtered = items.where((p) {
        return p.sellerName.toLowerCase().contains(search) ||
            p.cropType.toLowerCase().contains(search) ||
            (p.notes?.toLowerCase().contains(search) ?? false);
      }).toList();
    }

    // Sort
    filtered = List.of(filtered);
    filtered.sort((a, b) {
      int result;
      switch (sort.field) {
        case PurchaseSortField.purchaseDate:
          result = a.purchaseDate.compareTo(b.purchaseDate);
        case PurchaseSortField.cropType:
          result = a.cropType.compareTo(b.cropType);
        case PurchaseSortField.totalAmount:
          result = a.totalAmount.compareTo(b.totalAmount);
      }
      return sort.ascending ? result : -result;
    });

    return filtered;
  });
});
