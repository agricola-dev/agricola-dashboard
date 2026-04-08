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
      return 'error_save_failed';
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
      return 'error_update_failed';
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
      return 'error_delete_failed';
    }
  }
}

// ---------------------------------------------------------------------------
// Derived filtered + sorted provider
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Summary stats
// ---------------------------------------------------------------------------

/// Computed summary statistics for the purchases list.
class PurchaseSummaryStats {
  const PurchaseSummaryStats({
    required this.totalSpend,
    required this.averagePurchase,
    required this.totalCount,
    required this.topSupplierName,
    required this.topSupplierCount,
    required this.topSupplierTotal,
    required this.purchasesPerMonth,
    required this.uniqueSupplierCount,
  });

  final double totalSpend;
  final double averagePurchase;
  final int totalCount;
  final String topSupplierName;
  final int topSupplierCount;
  final double topSupplierTotal;
  final double purchasesPerMonth;
  final int uniqueSupplierCount;
}

/// Derives summary stats from the full (unfiltered) purchases list.
final purchaseSummaryStatsProvider =
    Provider<AsyncValue<PurchaseSummaryStats>>((ref) {
  final asyncItems = ref.watch(purchasesControllerProvider);

  return asyncItems.whenData((items) {
    if (items.isEmpty) {
      return const PurchaseSummaryStats(
        totalSpend: 0,
        averagePurchase: 0,
        totalCount: 0,
        topSupplierName: '-',
        topSupplierCount: 0,
        topSupplierTotal: 0,
        purchasesPerMonth: 0,
        uniqueSupplierCount: 0,
      );
    }

    final totalSpend = items.fold(0.0, (sum, p) => sum + p.totalAmount);
    final averagePurchase = totalSpend / items.length;

    // Top supplier by total spend
    final supplierTotals = <String, double>{};
    final supplierCounts = <String, int>{};
    for (final p in items) {
      supplierTotals[p.sellerName] =
          (supplierTotals[p.sellerName] ?? 0) + p.totalAmount;
      supplierCounts[p.sellerName] =
          (supplierCounts[p.sellerName] ?? 0) + 1;
    }

    final topSupplier = supplierTotals.entries
        .reduce((a, b) => a.value >= b.value ? a : b);

    // Purchase frequency (per month)
    final dates = items.map((p) => p.purchaseDate).toList()..sort();
    final spanDays = dates.last.difference(dates.first).inDays;
    final spanMonths = spanDays / 30.44; // average days per month
    final purchasesPerMonth =
        spanMonths >= 1 ? items.length / spanMonths : items.length.toDouble();

    return PurchaseSummaryStats(
      totalSpend: totalSpend,
      averagePurchase: averagePurchase,
      totalCount: items.length,
      topSupplierName: topSupplier.key,
      topSupplierCount: supplierCounts[topSupplier.key]!,
      topSupplierTotal: topSupplier.value,
      purchasesPerMonth: purchasesPerMonth,
      uniqueSupplierCount: supplierTotals.length,
    );
  });
});

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
