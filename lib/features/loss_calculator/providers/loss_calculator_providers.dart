import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/network/http_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides a [LossCalculatorApiService] backed by the authenticated Dio client.
final lossCalculatorApiServiceProvider =
    Provider<LossCalculatorApiService>((ref) {
  return LossCalculatorApiService(ref.watch(httpClientProvider));
});

/// Sort fields for loss calculations table columns.
enum LossCalcSortField {
  cropType,
  totalLossPercentage,
  monetaryLoss,
  calculationDate,
}

/// Sort configuration: field + direction.
class LossCalcSort {
  const LossCalcSort({
    this.field = LossCalcSortField.calculationDate,
    this.ascending = false,
  });

  final LossCalcSortField field;
  final bool ascending;

  LossCalcSort copyWith({LossCalcSortField? field, bool? ascending}) {
    return LossCalcSort(
      field: field ?? this.field,
      ascending: ascending ?? this.ascending,
    );
  }
}

/// Search text for filtering calculations.
final lossCalcSearchProvider = StateProvider<String>((_) => '');

/// Current sort configuration.
final lossCalcSortProvider = StateProvider<LossCalcSort>(
  (_) => const LossCalcSort(),
);

/// Loss calculation list controller — owns CRUD operations.
final lossCalcControllerProvider =
    AsyncNotifierProvider<LossCalcController, List<LossCalculation>>(
  LossCalcController.new,
);

class LossCalcController extends AsyncNotifier<List<LossCalculation>> {
  @override
  Future<List<LossCalculation>> build() async {
    final service = ref.watch(lossCalculatorApiServiceProvider);
    return service.getCalculations();
  }

  /// Saves a new calculation. Returns null on success, error message on failure.
  Future<String?> addCalculation(LossCalculation calculation) async {
    try {
      final service = ref.read(lossCalculatorApiServiceProvider);
      await service.saveCalculation(calculation);
      ref.invalidateSelf();
      await future;
      return null;
    } catch (e) {
      return 'error_save_failed';
    }
  }

  /// Deletes a calculation. Returns null on success, error message on failure.
  Future<String?> deleteCalculation(String id) async {
    try {
      final service = ref.read(lossCalculatorApiServiceProvider);
      await service.deleteCalculation(id);
      ref.invalidateSelf();
      await future;
      return null;
    } catch (e) {
      return 'error_delete_failed';
    }
  }
}

/// Derived provider that filters by search text and sorts the list.
final filteredLossCalcsProvider =
    Provider<AsyncValue<List<LossCalculation>>>((ref) {
  final asyncItems = ref.watch(lossCalcControllerProvider);
  final search = ref.watch(lossCalcSearchProvider).toLowerCase();
  final sort = ref.watch(lossCalcSortProvider);

  return asyncItems.whenData((items) {
    // Filter
    var filtered = items;
    if (search.isNotEmpty) {
      filtered = items.where((item) {
        return item.cropType.toLowerCase().contains(search) ||
            (item.cropCategory?.toLowerCase().contains(search) ?? false);
      }).toList();
    }

    // Sort
    filtered = List.of(filtered);
    filtered.sort((a, b) {
      int result;
      switch (sort.field) {
        case LossCalcSortField.cropType:
          result = a.cropType.compareTo(b.cropType);
        case LossCalcSortField.totalLossPercentage:
          result =
              a.totalLossPercentage.compareTo(b.totalLossPercentage);
        case LossCalcSortField.monetaryLoss:
          result = a.monetaryLoss.compareTo(b.monetaryLoss);
        case LossCalcSortField.calculationDate:
          result = (a.calculationDate ?? DateTime(2000))
              .compareTo(b.calculationDate ?? DateTime(2000));
      }
      return sort.ascending ? result : -result;
    });

    return filtered;
  });
});
