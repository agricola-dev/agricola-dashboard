import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/network/http_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides a [HarvestApiService] backed by the authenticated Dio client.
final harvestApiServiceProvider = Provider<HarvestApiService>((ref) {
  return HarvestApiService(ref.watch(httpClientProvider));
});

/// Tracks which crop's harvests are currently being viewed.
final selectedCropIdProvider = StateProvider<String?>((_) => null);

/// Harvest list controller — fetches harvests for the selected crop.
final harvestControllerProvider =
    AsyncNotifierProvider<HarvestController, List<HarvestModel>>(
  HarvestController.new,
);

class HarvestController extends AsyncNotifier<List<HarvestModel>> {
  @override
  Future<List<HarvestModel>> build() async {
    final cropId = ref.watch(selectedCropIdProvider);
    if (cropId == null) return [];
    final service = ref.watch(harvestApiServiceProvider);
    return service.getHarvestsByCrop(cropId);
  }

  /// Records a new harvest. Returns null on success, error message on failure.
  Future<String?> addHarvest(HarvestModel harvest) async {
    try {
      final service = ref.read(harvestApiServiceProvider);
      await service.createHarvest(harvest);
      ref.invalidateSelf();
      await future;
      return null;
    } catch (e) {
      return 'error_save_failed';
    }
  }

  /// Deletes a harvest. Returns null on success, error message on failure.
  Future<String?> deleteHarvest(String id) async {
    try {
      final service = ref.read(harvestApiServiceProvider);
      await service.deleteHarvest(id);
      ref.invalidateSelf();
      await future;
      return null;
    } catch (e) {
      return 'error_delete_failed';
    }
  }
}
