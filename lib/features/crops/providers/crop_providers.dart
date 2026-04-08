import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/network/http_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides a [CropApiService] backed by the authenticated Dio client.
final cropApiServiceProvider = Provider<CropApiService>((ref) {
  return CropApiService(ref.watch(httpClientProvider));
});

/// Provides a [CropCatalogApiService] backed by the authenticated Dio client.
final cropCatalogApiServiceProvider = Provider<CropCatalogApiService>((ref) {
  return CropCatalogApiService(ref.watch(httpClientProvider));
});

/// Fetches and caches the crop catalog from the backend.
final cropCatalogProvider =
    FutureProvider<List<CropCatalogEntry>>((ref) async {
  final service = ref.watch(cropCatalogApiServiceProvider);
  return service.getCatalog();
});

/// Sort fields for crops table columns.
enum CropSortField {
  cropType,
  fieldName,
  plantingDate,
  expectedHarvestDate,
}

/// Sort configuration: field + direction.
class CropSort {
  const CropSort({
    this.field = CropSortField.plantingDate,
    this.ascending = false,
  });

  final CropSortField field;
  final bool ascending;

  CropSort copyWith({CropSortField? field, bool? ascending}) {
    return CropSort(
      field: field ?? this.field,
      ascending: ascending ?? this.ascending,
    );
  }
}

/// Search text for filtering crops.
final cropSearchProvider = StateProvider<String>((_) => '');

/// Current sort configuration.
final cropSortProvider = StateProvider<CropSort>(
  (_) => const CropSort(),
);

/// Crop list controller — owns CRUD operations.
final cropControllerProvider =
    AsyncNotifierProvider<CropController, List<CropModel>>(
  CropController.new,
);

class CropController extends AsyncNotifier<List<CropModel>> {
  @override
  Future<List<CropModel>> build() async {
    final service = ref.watch(cropApiServiceProvider);
    return service.getUserCrops();
  }

  /// Creates a new crop. Returns null on success, error message on failure.
  Future<String?> addCrop(CropModel crop) async {
    try {
      final service = ref.read(cropApiServiceProvider);
      await service.createCrop(crop);
      ref.invalidateSelf();
      await future;
      return null;
    } catch (e) {
      return 'error_save_failed';
    }
  }

  /// Updates an existing crop. Returns null on success, error message on failure.
  Future<String?> updateCrop(String id, CropModel crop) async {
    try {
      final service = ref.read(cropApiServiceProvider);
      await service.updateCrop(id, crop);
      ref.invalidateSelf();
      await future;
      return null;
    } catch (e) {
      return 'error_update_failed';
    }
  }

  /// Deletes a crop. Returns null on success, error message on failure.
  Future<String?> deleteCrop(String id) async {
    try {
      final service = ref.read(cropApiServiceProvider);
      await service.deleteCrop(id);
      ref.invalidateSelf();
      await future;
      return null;
    } catch (e) {
      return 'error_delete_failed';
    }
  }
}

/// Derived provider that filters by search text and sorts the crop list.
final filteredCropsProvider =
    Provider<AsyncValue<List<CropModel>>>((ref) {
  final asyncItems = ref.watch(cropControllerProvider);
  final search = ref.watch(cropSearchProvider).toLowerCase();
  final sort = ref.watch(cropSortProvider);

  return asyncItems.whenData((items) {
    // Filter
    var filtered = items;
    if (search.isNotEmpty) {
      filtered = items.where((item) {
        return item.cropType.toLowerCase().contains(search) ||
            item.fieldName.toLowerCase().contains(search) ||
            item.storageMethod.toLowerCase().contains(search);
      }).toList();
    }

    // Sort
    filtered = List.of(filtered);
    filtered.sort((a, b) {
      int result;
      switch (sort.field) {
        case CropSortField.cropType:
          result = a.cropType.compareTo(b.cropType);
        case CropSortField.fieldName:
          result = a.fieldName.compareTo(b.fieldName);
        case CropSortField.plantingDate:
          result = a.plantingDate.compareTo(b.plantingDate);
        case CropSortField.expectedHarvestDate:
          result = a.expectedHarvestDate.compareTo(b.expectedHarvestDate);
      }
      return sort.ascending ? result : -result;
    });

    return filtered;
  });
});
